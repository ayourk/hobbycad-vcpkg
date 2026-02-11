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
# not their contents.  The constraint solver (BUILD_LIB) only needs Eigen3;
# all other vendored deps (zlib, libpng, freetype, pixman, cairo, angle) are
# for the GUI/CLI that we don't build.
#
# The vcpkg toolchain intercepts add_library() calls, which breaks the
# stub-CMakeLists.txt approach.  Instead, we neutralize the vendored
# dependency macros so CMake skips those subdirectories entirely, and then
# strip the ALIAS target lines that reference vendored targets.
# ---------------------------------------------------------------------------

# 1. Replace AddVendoredSubdirectory.cmake with a no-op macro
file(WRITE "${SOURCE_PATH}/cmake/AddVendoredSubdirectory.cmake"
"# Neutralized by vcpkg portfile - vendored subdirectories not available
macro(add_vendored_subdirectory)
endmacro()
")

# 2. Replace FindVendoredPackage.cmake: try system find_package only,
#    never fall back to vendored extlib subdirectories.
file(WRITE "${SOURCE_PATH}/cmake/FindVendoredPackage.cmake"
"# Neutralized by vcpkg portfile - use system packages from vcpkg only.
# Original macro would fall back to add_subdirectory(extlib/...) which
# requires git submodule content we don't ship in the PPA tarball.
macro(find_vendored_package VENDORED_PKG_NAME VENDORED_PKG_DIR)
    find_package(\${VENDORED_PKG_NAME} QUIET)
endmacro()
")

# 3. Strip add_library(ALIAS) lines that reference vendored targets
#    (e.g. ZLIB::ZLIB -> zlibstatic) which no longer exist.
file(READ "${SOURCE_PATH}/CMakeLists.txt" _cmakelists)
string(REPLACE "add_library(ZLIB::ZLIB" "# add_library(ZLIB::ZLIB" _cmakelists "${_cmakelists}")
file(WRITE "${SOURCE_PATH}/CMakeLists.txt" "${_cmakelists}")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_LIB=ON
        -DBUILD_GUI=OFF
        -DBUILD_CLI=OFF
        -DENABLE_GUI=OFF
        -DENABLE_OPENMP=OFF
        -DENABLE_TESTS=OFF
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/slvs)
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.txt")
