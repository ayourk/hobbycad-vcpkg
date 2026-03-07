# OpenCASCADE Technology (OCCT) — 3D surface and solid modeling
# Upstream: https://dev.opencascade.org/

set(VERSION 7.9.2)
# Upstream tag: V7_9_2

vcpkg_download_distfile(ARCHIVE
    URLS
        "https://github.com/ayourk/hobbycad-vcpkg/releases/download/sources/opencascade_${VERSION}+dfsg.orig.tar.xz"
    FILENAME "opencascade_${VERSION}+dfsg.orig.tar.xz"
    SHA512 4dd85fa698561969de035a8a82b5fcfe034bd8806f07ed26f1d23a69cb3b71de6a03c2425970dd5cd9de69258a5639003d28859aca398d09f809ca1b05f490ad
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    SOURCE_BASE "occt-V7_9_2"
    PATCHES
        fix-rapidjson-header-only.patch
)

# macOS framework paths - OCCT uses non-standard CMake variable names
# that don't work with vcpkg's toolchain. Explicitly set them.
set(MACOS_OPTIONS "")
if(VCPKG_TARGET_IS_OSX)
    list(APPEND MACOS_OPTIONS
        "-DAppkit_LIB=-framework AppKit"
        "-DIOKit_LIB=-framework IOKit"
        "-DOpenGlLibs_LIB=-framework OpenGL"
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
