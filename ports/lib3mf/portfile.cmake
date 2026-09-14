# lib3mf, the 3D Manufacturing Format library
# Upstream: https://github.com/3MFConsortium/lib3mf

set(VERSION 2.5.0)
# Upstream tag: v2.5.0 (64bb454d1fcb53effa57d3cef752a10d740d41a2, 2026-02-24)
#
# The tarball is the PPA's lib3mf_2.5.0+p1.orig.tar.xz: upstream's
# source-with-submodules archive minus the prebuilt code-generator binaries
# (act.* for six platforms and the generator's own tree), with the HobbyCAD
# +p1 series baked in, made by HobbyCAD-libs/lib3mf/make-lib3mf-orig.sh.
# Every channel builds this one file and no channel patches it. +p1 is
# four build-system fixes: lib3mfConfig.cmake takes the install layout
# from configure_package_config_file instead of three parents above itself
# (find_package(lib3mf) failed for any consumer on a multiarch libdir) and
# finds libzip/zlib only for a static build that linked their targets;
# GNUInstallDirs after project() with upstream's CACHE PATH redeclarations
# removed (CMake 4 absolutized a relative libdir, upstream issue #450);
# lib3mf.pc links lib3mf alone with the system libraries in Libs.private;
# and the target exports cxx_std_11, which its C++ binding header needs
# (Apple clang still defaults to C++98).
# The +p level counts releases against one upstream version and restarts
# at the next. The vendored zlib, libzip and libressl are kept and, as
# upstream defaults, used here; the PPA build points the same tarball at
# the system libraries instead.

vcpkg_download_distfile(ARCHIVE
    URLS
        "https://github.com/ayourk/hobbycad-vcpkg/releases/download/sources/lib3mf_${VERSION}+p1.orig.tar.xz"
    FILENAME "lib3mf_${VERSION}+p1.orig.tar.xz"
    SHA512 ff54549865cd49e526aabbcf38f7eda69023c00e3b322f81931cb7118b21a05196393ba7a3d661acd2289bfec6dac5a844905c28893bf2fff6374b0645b129ac
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
)

# Library type follows the triplet. 2.5.0 added LIB3MF_BUILD_SHARED
# (defaulting from BUILD_SHARED_LIBS), so the SHARED -> STATIC rewrite the
# 2.4.1 port needed is gone.
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    set(_lib3mf_shared OFF)
else()
    set(_lib3mf_shared ON)
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DLIB3MF_BUILD_SHARED=${_lib3mf_shared}
        -DLIB3MF_TESTS=OFF
        -DUSE_INCLUDED_ZLIB=ON
        -DUSE_INCLUDED_LIBZIP=ON
        -DUSE_INCLUDED_SSL=ON
        -DSTRIP_BINARIES=OFF
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/lib3mf)
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
