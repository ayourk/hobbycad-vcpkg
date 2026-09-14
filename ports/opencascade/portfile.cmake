# OpenCASCADE Technology (OCCT) — 3D surface and solid modeling
# Upstream: https://dev.opencascade.org/

set(VERSION 8.0.1)
# Upstream tag: V8_0_1
#
# Moved to 8.0.1 to match the PPA. HobbyCAD spans 7.9.x and 8.0.x with one
# #if OCC_VERSION_MAJOR guard, so leaving this channel on 7.9.2 while Linux
# moved would mean the two exercised different branches of that guard and
# nobody was testing the combination anyone actually shipped.
#
# The tarball is the PPA's opencascade_8.0.1+p1.orig.tar.xz: stock upstream
# V8_0_1 with the HobbyCAD BSD portability series baked in (+p1; OpenCASCADE
# issue #1515: locale detection, OSD_Path, OSD_MemInfo, Standard_CString,
# occt_csf.cmake). The same file feeds the PPA, Homebrew and the BSD ports, so
# this port no longer carries a BSD patch of its own; the earlier
# 0001-clocale-posix2008-on-bsd.patch was a first cut of that series and
# would have re-added NetBSD, which has newlocale() but no uselocale().

vcpkg_download_distfile(ARCHIVE
    URLS
        "https://github.com/ayourk/hobbycad-vcpkg/releases/download/sources/opencascade_${VERSION}+p1.orig.tar.xz"
    FILENAME "opencascade_${VERSION}+p1.orig.tar.xz"
    SHA512 66e92df6d9a37493d58e663fe221becb93c78ef6b9886b35683a499abae68b23dde104c66532781787423f843efd146e8d556e86eb3d6b15778c640fe188c5f0
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    SOURCE_BASE "opencascade-8.0.1+p1"
    PATCHES
        fix-rapidjson-header-only.patch
)

# macOS framework paths - OCCT uses non-standard CMake variable names
# that don't work with vcpkg's toolchain. Use full framework paths
# instead of -framework flags to avoid vcpkg cmake fixup issues.
# Note: find_library doesn't work in vcpkg portfiles, so use direct paths.
set(MACOS_OPTIONS "")
if(VCPKG_TARGET_IS_OSX)
    set(MACOS_FRAMEWORKS "/System/Library/Frameworks")
    list(APPEND MACOS_OPTIONS
        "-DAppkit_LIB=${MACOS_FRAMEWORKS}/AppKit.framework"
        "-DIOKit_LIB=${MACOS_FRAMEWORKS}/IOKit.framework"
        "-DOpenGlLibs_LIB=${MACOS_FRAMEWORKS}/OpenGL.framework"
    )
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_LIBRARY_TYPE=Static
        ${MACOS_OPTIONS}
        -DBUILD_MODULE_ApplicationFramework=ON
        -DBUILD_MODULE_DataExchange=ON
        -DBUILD_MODULE_Draw=OFF
        -DBUILD_MODULE_FoundationClasses=ON
        -DBUILD_MODULE_ModelingAlgorithms=ON
        -DBUILD_MODULE_ModelingData=ON
        -DBUILD_MODULE_Visualization=ON
        -DUSE_D3D=OFF
        -DUSE_DRACO=OFF
        -DUSE_FFMPEG=OFF
        -DUSE_FREEIMAGE=OFF
        -DUSE_GLES2=OFF
        -DUSE_OPENGL=ON
        -DUSE_OPENVR=OFF
        -DUSE_RAPIDJSON=ON
        -DUSE_TBB=OFF
        -DUSE_TK=OFF
        -DUSE_VTK=OFF
        -DINSTALL_DIR_LIB=lib
        -DINSTALL_DIR_BIN=bin
        -DINSTALL_DIR_INCLUDE=include/opencascade
        -DINSTALL_DIR_CMAKE=share/opencascade
        -DINSTALL_DIR_RESOURCE=share/opencascade/resources
        -DINSTALL_DIR_DATA=share/opencascade/data
        -DINSTALL_DIR_SAMPLES=share/opencascade/samples
        -DINSTALL_DIR_DOC=share/doc/opencascade
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH share/opencascade)
vcpkg_copy_pdbs()

# Fix OpenCASCADE_INSTALL_PREFIX path calculation in the CMake config.
# The OpenCASCADEConfig.cmake calculates the install prefix but ends up at
# share/ instead of the vcpkg root. We append code to the config file that
# recalculates the correct paths after it runs.
file(APPEND "${CURRENT_PACKAGES_DIR}/share/opencascade/OpenCASCADEConfig.cmake" [[

# vcpkg port fix: recalculate paths to point to vcpkg root
# The original config ends up with OpenCASCADE_INSTALL_PREFIX pointing to share/
# which causes include paths to be wrong. Fix by going up one more level.
get_filename_component(_VCPKG_OCCT_ROOT "${CMAKE_CURRENT_LIST_DIR}" PATH)
get_filename_component(_VCPKG_OCCT_ROOT "${_VCPKG_OCCT_ROOT}" PATH)
set(OpenCASCADE_INSTALL_PREFIX "${_VCPKG_OCCT_ROOT}")
set(OpenCASCADE_INCLUDE_DIR "${_VCPKG_OCCT_ROOT}/include/opencascade")
unset(_VCPKG_OCCT_ROOT)
]])

# OCCT drops its environment scripts (env, custom, draw) and copies of the
# license texts at the prefix root and under bin/. They carry absolute build
# paths and mean nothing inside a vcpkg tree; the license is installed as the
# port's copyright below. In a static build bin/ then holds nothing.
file(GLOB _occt_stray
    "${CURRENT_PACKAGES_DIR}/*.sh" "${CURRENT_PACKAGES_DIR}/*.bat"
    "${CURRENT_PACKAGES_DIR}/*.txt"
    "${CURRENT_PACKAGES_DIR}/debug/*.sh" "${CURRENT_PACKAGES_DIR}/debug/*.bat"
    "${CURRENT_PACKAGES_DIR}/debug/*.txt"
    "${CURRENT_PACKAGES_DIR}/bin/*.sh" "${CURRENT_PACKAGES_DIR}/bin/*.bat"
    "${CURRENT_PACKAGES_DIR}/debug/bin/*.sh" "${CURRENT_PACKAGES_DIR}/debug/bin/*.bat")
if(_occt_stray)
    file(REMOVE ${_occt_stray})
endif()
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# Remove empty directories and debug includes
file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/share/doc"
    "${CURRENT_PACKAGES_DIR}/share/opencascade/data"
    "${CURRENT_PACKAGES_DIR}/share/opencascade/samples"
)

# Install cmake wrapper to handle dependencies
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# Install license file
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE_LGPL_21.txt")
