# Qt 6 Base + SVG Modules for HobbyCAD static builds
# Source: PPA dfsg tarballs (hosted on GitHub releases)
#
# This port integrates qtsvg directly into the qtbase build tree, creating
# a truly monolithic build that avoids Qt6BuildInternals complexity entirely.

set(QT_VERSION 6.4.2)

# ============================================================================
# Download sources
# ============================================================================

vcpkg_download_distfile(QTBASE_ARCHIVE
    URLS
        "https://github.com/ayourk/hobbycad-vcpkg/releases/download/sources/qt6-base_${QT_VERSION}+dfsg.orig.tar.xz"
    FILENAME "qt6-base_${QT_VERSION}+dfsg.orig.tar.xz"
    SHA512 2704b90dab05ad2bc31a1171e2818aaa694d5d579d0defe27f9806f3d6c6263467c0673415b3fa73612e45f076442b5fe003d79b9eb758489616263153189a8d
)

vcpkg_download_distfile(QTSVG_ARCHIVE
    URLS
        "https://github.com/ayourk/hobbycad-vcpkg/releases/download/sources/qt6-svg_${QT_VERSION}.orig.tar.xz"
    FILENAME "qt6-svg_${QT_VERSION}.orig.tar.xz"
    SHA512 9b9de3f19a6c98d61ec1b4ba1883aada3b57db8e2ce56a493b6d7c639ed49a43f51c16b11f65cf8ee7ba8c8f4c61e1eedebb99c8645acfcc934048f2eb76fe64
)

# Extract qtbase first (with patches)
vcpkg_extract_source_archive(
    QTBASE_SOURCE_PATH
    ARCHIVE "${QTBASE_ARCHIVE}"
    SOURCE_BASE "qtbase-everywhere-src-${QT_VERSION}"
    PATCHES
        fix-macos-visibility-test.patch
        add-wintab-headers.patch
        fix-threads-global-promotion.patch
        fix-qduplicatetracker-include.patch
)

# Extract qtsvg to a temporary location
vcpkg_extract_source_archive(
    QTSVG_SOURCE_PATH
    ARCHIVE "${QTSVG_ARCHIVE}"
    SOURCE_BASE "qtsvg-everywhere-src-${QT_VERSION}"
)

# ============================================================================
# Integrate QtSvg into QtBase source tree
# ============================================================================

# Copy qtsvg sources into qtbase
file(COPY "${QTSVG_SOURCE_PATH}/src/svg" DESTINATION "${QTBASE_SOURCE_PATH}/src/")

# Copy pre-generated QtSvg headers (avoids needing syncqt.pl)
# This includes forwarding headers like QSvgRenderer, QtSvg, etc.
if(EXISTS "${QTSVG_SOURCE_PATH}/include/QtSvg")
    file(COPY "${QTSVG_SOURCE_PATH}/include/QtSvg" DESTINATION "${QTBASE_SOURCE_PATH}/include/")
endif()

# Remove qtsvg's original cmake files that would interfere
file(REMOVE "${QTBASE_SOURCE_PATH}/src/svg/.cmake.conf")
file(REMOVE "${QTBASE_SOURCE_PATH}/src/svg/Qt6SvgMacros.cmake")

# Create qtsvgexports.h for static builds
# GENERATE_CPP_EXPORTS doesn't generate this for static libraries
file(WRITE "${QTBASE_SOURCE_PATH}/include/QtSvg/qtsvgexports.h"
"// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only

#ifndef QTSVGEXPORTS_H
#define QTSVGEXPORTS_H

#include <QtCore/qglobal.h>

#if defined(QT_SHARED) || !defined(QT_STATIC)
#  if defined(QT_BUILD_SVG_LIB)
#    define Q_SVG_EXPORT Q_DECL_EXPORT
#  else
#    define Q_SVG_EXPORT Q_DECL_IMPORT
#  endif
#else
#  define Q_SVG_EXPORT
#endif

#endif // QTSVGEXPORTS_H
")

# Modify qtsvgglobal_p.h to define Q_SVG_PRIVATE_EXPORT directly
# This avoids needing the separate private exports header
file(READ "${QTBASE_SOURCE_PATH}/src/svg/qtsvgglobal_p.h" _svgglobal_p)
string(REPLACE
    "#include <QtSvg/private/qtsvgexports_p.h>"
    "// For static builds, export macros are empty\n#define Q_SVG_PRIVATE_EXPORT Q_SVG_EXPORT"
    _svgglobal_p "${_svgglobal_p}")
file(WRITE "${QTBASE_SOURCE_PATH}/src/svg/qtsvgglobal_p.h" "${_svgglobal_p}")

# Create the CMakeLists.txt for the integrated svg module
# This closely matches the original qtsvg CMakeLists.txt but with NO_SYNC_QT
# since syncqt.pl doesn't know about this module
file(WRITE "${QTBASE_SOURCE_PATH}/src/svg/CMakeLists.txt"
"# Qt6 SVG Module - integrated into qtbase build
# Based on original qtsvg/src/svg/CMakeLists.txt
# NO_SYNC_QT is required because syncqt.pl doesn't know about this module

# Handle zlib dependency (same as original)
if(NOT QT_FEATURE_system_zlib)
    find_package(Qt6 COMPONENTS ZlibPrivate)
elseif(NOT TARGET WrapZLIB::WrapZLIB)
    qt_find_package(WrapZLIB PROVIDED_TARGETS WrapZLIB::WrapZLIB)
endif()

# Since we use NO_SYNC_QT, manually set up the QtSvg include directory
set(_svg_build_include_dir \"\${QT_BUILD_DIR}/include/QtSvg\")
file(MAKE_DIRECTORY \"\${_svg_build_include_dir}\")
file(MAKE_DIRECTORY \"\${_svg_build_include_dir}/6.4.2\")
file(MAKE_DIRECTORY \"\${_svg_build_include_dir}/6.4.2/QtSvg\")
file(MAKE_DIRECTORY \"\${_svg_build_include_dir}/6.4.2/QtSvg/private\")

# Copy public headers from source include directory
set(_svg_source_include_dir \"\${CMAKE_CURRENT_SOURCE_DIR}/../../include/QtSvg\")
if(EXISTS \"\${_svg_source_include_dir}\")
    file(GLOB _svg_headers \"\${_svg_source_include_dir}/*\")
    foreach(_header \${_svg_headers})
        if(NOT IS_DIRECTORY \"\${_header}\")
            get_filename_component(_header_name \"\${_header}\" NAME)
            configure_file(\"\${_header}\" \"\${_svg_build_include_dir}/\${_header_name}\" COPYONLY)
        endif()
    endforeach()
    file(GLOB _svg_versioned_headers \"\${_svg_source_include_dir}/6.4.2/*\")
    foreach(_header \${_svg_versioned_headers})
        if(NOT IS_DIRECTORY \"\${_header}\")
            get_filename_component(_header_name \"\${_header}\" NAME)
            configure_file(\"\${_header}\" \"\${_svg_build_include_dir}/6.4.2/\${_header_name}\" COPYONLY)
        endif()
    endforeach()
endif()

qt_internal_add_module(Svg
    NO_SYNC_QT
    GENERATE_CPP_EXPORTS
    GENERATE_PRIVATE_CPP_EXPORTS
    SOURCES
        qsvgfont.cpp qsvgfont_p.h
        qsvggenerator.cpp qsvggenerator.h
        qsvggraphics.cpp qsvggraphics_p.h
        qsvghandler.cpp qsvghandler_p.h
        qsvgnode.cpp qsvgnode_p.h
        qsvgrenderer.cpp qsvgrenderer.h
        qsvgstructure.cpp qsvgstructure_p.h
        qsvgstyle.cpp qsvgstyle_p.h
        qsvgtinydocument.cpp qsvgtinydocument_p.h
        qtsvgglobal.h qtsvgglobal_p.h
    DEFINES
        QT_NO_USING_NAMESPACE
    LIBRARIES
        Qt::CorePrivate
        Qt::GuiPrivate
    PUBLIC_LIBRARIES
        Qt::Core
        Qt::Gui
    PRIVATE_MODULE_INTERFACE
        Qt::CorePrivate
        Qt::GuiPrivate
)

# MSVC link options (same as original)
qt_internal_extend_target(Svg CONDITION MSVC AND (TEST_architecture_arch STREQUAL \"i386\")
    LINK_OPTIONS
        \"/BASE:0x66000000\"
)

# Zlib linking (same as original)
qt_internal_extend_target(Svg CONDITION QT_FEATURE_system_zlib
    LIBRARIES
        WrapZLIB::WrapZLIB
)

qt_internal_extend_target(Svg CONDITION NOT QT_FEATURE_system_zlib
    LIBRARIES
        Qt::ZlibPrivate
)

# Install QtSvg headers manually since NO_SYNC_QT skips header installation
set(_svg_install_include_dir \"\${INSTALL_INCLUDEDIR}/QtSvg\")
install(FILES
    \"\${_svg_build_include_dir}/qtsvgexports.h\"
    \"\${_svg_build_include_dir}/qtsvgglobal.h\"
    \"\${_svg_build_include_dir}/qsvgrenderer.h\"
    \"\${_svg_build_include_dir}/qsvggenerator.h\"
    \"\${_svg_build_include_dir}/QtSvg\"
    \"\${_svg_build_include_dir}/QSvgRenderer\"
    \"\${_svg_build_include_dir}/QSvgGenerator\"
    DESTINATION \"\${_svg_install_include_dir}\"
)
")

# Add svg to the src/CMakeLists.txt subdirectories
file(READ "${QTBASE_SOURCE_PATH}/src/CMakeLists.txt" _src_cmake)
if(NOT _src_cmake MATCHES "add_subdirectory\\(svg\\)")
    string(APPEND _src_cmake "\n# QtSvg module (integrated)\nadd_subdirectory(svg)\n")
    file(WRITE "${QTBASE_SOURCE_PATH}/src/CMakeLists.txt" "${_src_cmake}")
endif()

# ============================================================================
# Build tools setup
# ============================================================================

vcpkg_find_acquire_program(PERL)
get_filename_component(PERL_PATH ${PERL} DIRECTORY)
vcpkg_add_to_path(${PERL_PATH})

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_PATH ${PYTHON3} DIRECTORY)
vcpkg_add_to_path(${PYTHON3_PATH})

# ============================================================================
# Qt configuration options
# ============================================================================

# Feature options for HobbyCAD's needs
set(FEATURE_OPTIONS
    -DFEATURE_concurrent=ON
    -DFEATURE_dbus=OFF
    -DFEATURE_gui=ON
    -DFEATURE_network=OFF
    -DFEATURE_opengl=ON
    -DFEATURE_printsupport=OFF
    -DFEATURE_sql=OFF
    -DFEATURE_testlib=OFF
    -DFEATURE_widgets=ON
    -DFEATURE_xml=ON
)

# Dependency configuration
set(INPUT_OPTIONS
    -DINPUT_doubleconversion=system
    -DINPUT_freetype=system
    -DINPUT_harfbuzz=system
    -DINPUT_libjpeg=system
    -DINPUT_libpng=system
    -DINPUT_pcre=system
)

# Platform-specific options
set(PLATFORM_OPTIONS "")
if(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND PLATFORM_OPTIONS
        -DFEATURE_opengl_desktop=ON
    )
elseif(VCPKG_TARGET_IS_OSX)
    list(APPEND PLATFORM_OPTIONS
        -DFEATURE_opengl_desktop=ON
        -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0
    )
endif()

# Disable features not needed
set(DISABLE_OPTIONS
    -DCMAKE_DISABLE_FIND_PACKAGE_ATSPI2=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Cups=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_DirectFB=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_EGL=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Fontconfig=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_GLESv2=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_GLIB2=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_GSSAPI=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_GTK3=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_ICU=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Libdrm=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Libinput=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Libproxy=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_LTTngUST=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Mtdev=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_MySQL=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_ODBC=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Oracle=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_PostgreSQL=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_SQLite3=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Slog2=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Tslib=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Vulkan=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_WrapBrotli=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_WrapDBus1=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_WrapOpenSSL=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_X11=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_XCB=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_XKB=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_ZSTD=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_gbm=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_libb2=ON
)

# ============================================================================
# Build Qt Base (with integrated SVG module)
# ============================================================================

vcpkg_cmake_configure(
    SOURCE_PATH "${QTBASE_SOURCE_PATH}"
    OPTIONS
        -DBUILD_SHARED_LIBS=OFF
        -DQT_BUILD_EXAMPLES=OFF
        -DQT_BUILD_TESTS=OFF
        -DQT_BUILD_BENCHMARKS=OFF
        -DQT_FORCE_BUILD_TOOLS=ON
        -DQT_USE_BUNDLED_BundledFreetype=OFF
        -DQT_USE_BUNDLED_BundledHarfbuzz=OFF
        -DQT_USE_BUNDLED_BundledLibpng=OFF
        -DQT_USE_BUNDLED_BundledPcre2=OFF
        -DQT_USE_BUNDLED_BundledZLIB=OFF
        -DFEATURE_relocatable=ON
        -DHOST_PERL=${PERL}
        ${FEATURE_OPTIONS}
        ${INPUT_OPTIONS}
        ${PLATFORM_OPTIONS}
        ${DISABLE_OPTIONS}
)

vcpkg_cmake_install()

# ============================================================================
# Fix up cmake configs
# ============================================================================

# Fix up the main Qt6 directory first
vcpkg_cmake_config_fixup(PACKAGE_NAME "Qt6" CONFIG_PATH "lib/cmake/Qt6")

# Dynamically find and fix up ALL Qt6* component directories
file(GLOB _qt6_cmake_dirs "${CURRENT_PACKAGES_DIR}/lib/cmake/Qt6*")
foreach(_dir IN LISTS _qt6_cmake_dirs)
    get_filename_component(_comp "${_dir}" NAME)
    # Skip directories we handle separately
    if(NOT "${_comp}" STREQUAL "Qt6" AND NOT "${_comp}" STREQUAL "Qt6BuildInternals")
        vcpkg_cmake_config_fixup(PACKAGE_NAME "${_comp}" CONFIG_PATH "lib/cmake/${_comp}")
    endif()
endforeach()

vcpkg_copy_pdbs()

# ============================================================================
# Clean up
# ============================================================================

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/lib/cmake"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/lib/cmake"
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

# Remove any leftover BuildInternals
file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/share/Qt6BuildInternals"
    "${CURRENT_PACKAGES_DIR}/share/Qt6/QtBuildInternals"
)

# Install license (LGPL covers both qtbase and qtsvg)
vcpkg_install_copyright(FILE_LIST "${QTBASE_SOURCE_PATH}/LICENSES/LGPL-3.0-only.txt")
