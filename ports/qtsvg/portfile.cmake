# Qt 6 SVG Module for HobbyCAD static builds

set(QT_VERSION 6.4.2)

vcpkg_download_distfile(ARCHIVE
    URLS
        "https://github.com/ayourk/hobbycad-vcpkg/releases/download/sources/qt6-svg_${QT_VERSION}.orig.tar.xz"
    FILENAME "qt6-svg_${QT_VERSION}.orig.tar.xz"
    SHA512 9b9de3f19a6c98d61ec1b4ba1883aada3b57db8e2ce56a493b6d7c639ed49a43f51c16b11f65cf8ee7ba8c8f4c61e1eedebb99c8645acfcc934048f2eb76fe64
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    SOURCE_BASE "qtsvg-everywhere-src-${QT_VERSION}"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DQT_BUILD_EXAMPLES=OFF
        -DQT_BUILD_TESTS=OFF
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME Qt6Svg CONFIG_PATH lib/cmake/Qt6Svg)
vcpkg_cmake_config_fixup(PACKAGE_NAME Qt6SvgWidgets CONFIG_PATH lib/cmake/Qt6SvgWidgets)

vcpkg_copy_pdbs()

# Clean up
file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/lib/cmake"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/lib/cmake"
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

# Install license
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSES/LGPL-3.0-only.txt")
