# SolveSpace constraint solver library
# Upstream: https://github.com/solvespace/solvespace

set(VERSION 3.2)
set(SNAPSHOT 20260914)
# Upstream master 952c11c0 (2026-09-01). The snapshot date records when the
# HobbyCAD series was cut against it, not an upstream move.
#
# The +p1 suffix is the HobbyCAD patch-series level. The series is DELIVERED
# INSIDE THE TARBALL rather than applied here: every channel (Debian/PPA,
# vcpkg, Homebrew) needs the same series (twenty-seven patches at this snapshot:
# solver fixes, free-parameter reporting, drag weights, curvature and
# rational-cubic constraints, operand validation, version reporting,
# trust-region Newton steps, inequality and circle-line tangent constraints,
# live-source transform points, the point-on-line initialization fix), so
# carrying it once in the
# source is one place to maintain instead of three, and this port no longer
# applies any patch at all.
#
# The series itself is not gone -- it lives at
# HobbyCAD-libs/solvespace/patch-series/ and is the INPUT to make-orig.sh,
# which regenerates this tarball reproducibly. That is what keeps an upstream
# resync tractable: rebase the series onto a newer snapshot, rerun the script.
#
# Two independent axes: git.<snapshot> says which upstream, +p<level> says
# which revision of our series. The level counts releases against ONE
# snapshot and restarts at a new one, so the snapshot and the level together
# identify the contents.
#
# NOTE the dots: GitHub release assets normalize "~" to "." in the stored
# filename, so a URL written with a tilde 404s no matter how correct the
# upload was.

vcpkg_download_distfile(ARCHIVE
    URLS
        "https://github.com/ayourk/hobbycad-vcpkg/releases/download/sources/libslvs_${VERSION}.git.${SNAPSHOT}+p1.orig.tar.gz"
    FILENAME "libslvs_${VERSION}.git.${SNAPSHOT}+p1.orig.tar.gz"
    SHA512 ba63e5590b2c0d4fdbfd9c7abca23a24dbb412fd8610829c14960175c82f209318e776b1c320a130fe242730bf19b34dbfbfbfc60cbe2e5b59130f3c5a792521
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
)

# ---------------------------------------------------------------------------
# SolveSpace vendors several libraries as git submodules in extlib/.
# Our source tarball (PPA git snapshot) includes the extlib directories but
# not their contents (except mimalloc and libdxfrw which are present).
#
# Strategy: install deps from vcpkg and populate the empty extlib/ dirs with
# headers from vcpkg packages so the hardcoded include paths in CMakeLists.txt
# resolve correctly.  Neutralize the vendored build macros so CMake does not
# try to build the vendored sources (which don't exist).
# ---------------------------------------------------------------------------

# 1. Populate extlib/ directories with headers from vcpkg packages
#    (CMakeLists.txt hardcodes these as include paths)

# Eigen3 — extlib/eigen/Eigen/...
file(COPY "${CURRENT_INSTALLED_DIR}/include/eigen3/" DESTINATION "${SOURCE_PATH}/extlib/eigen")

# zlib — extlib/zlib/zlib.h, zconf.h
file(GLOB _zlib_hdrs "${CURRENT_INSTALLED_DIR}/include/zlib.h" "${CURRENT_INSTALLED_DIR}/include/zconf.h")
file(COPY ${_zlib_hdrs} DESTINATION "${SOURCE_PATH}/extlib/zlib")

# libpng — extlib/libpng/png.h, pngconf.h, pnglibconf.h
file(GLOB _png_hdrs "${CURRENT_INSTALLED_DIR}/include/png.h" "${CURRENT_INSTALLED_DIR}/include/pngconf.h" "${CURRENT_INSTALLED_DIR}/include/pnglibconf.h")
file(COPY ${_png_hdrs} DESTINATION "${SOURCE_PATH}/extlib/libpng")

# freetype — extlib/freetype/include/...
# vcpkg freetype may install to include/freetype2/ or include/
if(IS_DIRECTORY "${CURRENT_INSTALLED_DIR}/include/freetype2")
    file(COPY "${CURRENT_INSTALLED_DIR}/include/freetype2/" DESTINATION "${SOURCE_PATH}/extlib/freetype/include")
else()
    file(MAKE_DIRECTORY "${SOURCE_PATH}/extlib/freetype/include")
    file(GLOB _ft_items "${CURRENT_INSTALLED_DIR}/include/freetype/*" "${CURRENT_INSTALLED_DIR}/include/ft2build.h")
    if(_ft_items)
        file(COPY ${_ft_items} DESTINATION "${SOURCE_PATH}/extlib/freetype/include")
    endif()
endif()

# cairo — extlib/cairo/src/cairo.h etc.
file(GLOB _cairo_hdrs "${CURRENT_INSTALLED_DIR}/include/cairo/*")
file(COPY ${_cairo_hdrs} DESTINATION "${SOURCE_PATH}/extlib/cairo/src")

# 2. Neutralize vendored build macros — prevent add_subdirectory on extlib/
#    dirs that don't have buildable sources (only headers now).

file(WRITE "${SOURCE_PATH}/cmake/AddVendoredSubdirectory.cmake"
"# Neutralized by vcpkg portfile — deps provided by vcpkg packages
macro(add_vendored_subdirectory)
endmacro()
")

file(WRITE "${SOURCE_PATH}/cmake/FindVendoredPackage.cmake"
"# Neutralized by vcpkg portfile — deps provided by vcpkg packages.
macro(find_vendored_package VENDORED_PKG_NAME VENDORED_PKG_DIR)
    find_package(\${VENDORED_PKG_NAME} QUIET)
    # Map vcpkg targets to vendored target names expected by SolveSpace
    if(\"\${VENDORED_PKG_NAME}\" STREQUAL \"ZLIB\" AND TARGET ZLIB::ZLIB AND NOT TARGET zlibstatic)
        add_library(zlibstatic INTERFACE IMPORTED)
        set_target_properties(zlibstatic PROPERTIES INTERFACE_LINK_LIBRARIES ZLIB::ZLIB)
    endif()
    if(\"\${VENDORED_PKG_NAME}\" STREQUAL \"Cairo\" AND NOT TARGET cairo)
        find_library(_CAIRO_LIB NAMES cairo cairo-2)
        if(_CAIRO_LIB)
            add_library(cairo UNKNOWN IMPORTED)
            set_target_properties(cairo PROPERTIES IMPORTED_LOCATION \"\${_CAIRO_LIB}\")
        else()
            add_library(cairo INTERFACE IMPORTED)
        endif()
    endif()
endmacro()
")

# 3. Comment out ALIAS targets that reference vendored build targets
#    (zlibstatic, png_static, etc.) which no longer exist.
file(READ "${SOURCE_PATH}/CMakeLists.txt" _cmakelists)
string(REPLACE "add_library(ZLIB::ZLIB" "# add_library(ZLIB::ZLIB" _cmakelists "${_cmakelists}")
# Override solvespace's set(CMAKE_CXX_STANDARD 11) — the -D flag cannot
# override a normal variable, so we must patch the source directly
string(REPLACE "set(CMAKE_CXX_STANDARD 11)" "set(CMAKE_CXX_STANDARD 14)" _cmakelists "${_cmakelists}")
file(WRITE "${SOURCE_PATH}/CMakeLists.txt" "${_cmakelists}")

# 4. Library type follows the triplet. The fork hard-codes
#    add_library(slvs SHARED) and installs it with no RUNTIME destination,
#    so on Windows the DLL was linked and then never installed (an import
#    library pointing at nothing), and on a static triplet a shared library
#    was built regardless (dylibs on x64-osx-static). HobbyCAD's Windows and
#    macOS builds are static by design (x64-windows-static-md, *-osx-static):
#    on a static triplet the target becomes STATIC and defines STATIC_LIB;
#    on a dynamic triplet the DLL goes to bin/ like every other port.
file(READ "${SOURCE_PATH}/src/slvs/CMakeLists.txt" _slvs_cmake)
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    # The solver's temporary heap is mimalloc, which the fork links into the
    # shared slvs PRIVATEly. A static archive built from the same rules would
    # leave mi_heap_new and friends unresolved for every consumer (LNK2019 in
    # HobbyCAD's link), so mimalloc's objects are compiled into the archive:
    # MI_BUILD_OBJECT=ON below provides mimalloc-obj (mimalloc's single
    # translation unit) and the static target takes its objects.
    string(REPLACE "add_library(slvs SHARED)"
                   "add_library(slvs STATIC)\ntarget_compile_definitions(slvs PUBLIC STATIC_LIB)\ntarget_sources(slvs PRIVATE $<TARGET_OBJECTS:mimalloc-obj>)"
                   _slvs_cmake "${_slvs_cmake}")
    set(_slvs_static_options -DMI_BUILD_OBJECT=ON)
else()
    set(_slvs_static_options "")
    string(REPLACE [[    LIBRARY       DESTINATION ${CMAKE_INSTALL_LIBDIR}]]
                   [[    RUNTIME       DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY       DESTINATION ${CMAKE_INSTALL_LIBDIR}]]
                   _slvs_cmake "${_slvs_cmake}")
endif()
file(WRITE "${SOURCE_PATH}/src/slvs/CMakeLists.txt" "${_slvs_cmake}")

# 5. The CRT follows the triplet. The fork forces /MT on MSVC through
#    CMAKE_USER_MAKE_RULES_OVERRIDE (cmake/c_flag_overrides.cmake and
#    cxx_flag_overrides.cmake), which is right for SolveSpace's own
#    standalone binaries and wrong inside vcpkg: x64-windows-static-md wants
#    the dynamic CRT (/MD), and a /MT slvs.lib linked into an /MD program is
#    an LNK2038 RuntimeLibrary mismatch. Emptying the overrides leaves the
#    choice to vcpkg's toolchain (VCPKG_CRT_LINKAGE).
foreach(_ovr c_flag_overrides.cmake cxx_flag_overrides.cmake)
    file(WRITE "${SOURCE_PATH}/cmake/${_ovr}"
        "# Neutralized by the vcpkg port: the triplet chooses the CRT.\n")
endforeach()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${_slvs_static_options}
        -DENABLE_GUI=OFF
        -DENABLE_CLI=OFF
        -DENABLE_OPENMP=OFF
        -DENABLE_TESTS=OFF
    MAYBE_UNUSED_VARIABLES
        ENABLE_CLI
)

vcpkg_cmake_install()

# The fork installs no CMake package config (consumers use pkg-config or
# find_library), so there is nothing to fix up; the empty lib/cmake/slvs
# directories an earlier guard created only drew post-build warnings.
vcpkg_fixup_pkgconfig()

# On a static triplet the installed header must not declare dllimport:
# slvs.h keys that on STATIC_LIB, which CMake consumers never define.
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/slvs.h"
        "#if defined(WIN32) && !defined(STATIC_LIB)"
        "#define STATIC_LIB 1 /* vcpkg static triplet: no dllimport */\n#if defined(WIN32) && !defined(STATIC_LIB)")
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/lib/cmake"
    "${CURRENT_PACKAGES_DIR}/debug/lib/cmake")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.txt")
