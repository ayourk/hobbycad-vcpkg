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

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_LIB=ON
        -DBUILD_GUI=OFF
        -DBUILD_CLI=OFF
        -DENABLE_OPENMP=OFF
        -DENABLE_TESTS=OFF
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/slvs)
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.txt")
