# SolveSpace constraint solver library
# Upstream: https://github.com/solvespace/solvespace

set(VERSION 3.2)
# Upstream commit: 02ec4e57aa90f70052f6a312aa5c286a64a7ec90 (2026-02-04)

vcpkg_download_distfile(ARCHIVE
    URLS
        "https://github.com/ayourk/hobbycad-vcpkg/releases/download/sources/libslvs_${VERSION}.git.20260208.orig.tar.gz"
    FILENAME "libslvs_${VERSION}.git.20260208.orig.tar.gz"
    SHA512 a95c2dbb7af60e1a172fdedf26a0e5de5ebfe8ebf16cc0e4933c3dcc28c537873620703a78ea0af3b2df14e96d406dfe2565f9fe9a078621c67a1e7e40debcbe
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        0001-handle-missing-git-directory.patch
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
file(WRITE "${SOURCE_PATH}/CMakeLists.txt" "${_cmakelists}")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DENABLE_GUI=OFF
        -DENABLE_CLI=OFF
        -DENABLE_OPENMP=OFF
        -DENABLE_TESTS=OFF
    MAYBE_UNUSED_VARIABLES
        ENABLE_CLI
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/slvs)
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.txt")
