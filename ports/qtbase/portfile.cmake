# Qt 6.4.2 Base with selectable features.
# Source: PPA dfsg tarballs (hosted on GitHub releases).
# qtsvg is optionally integrated into the qtbase build tree via the
# "qtsvg" feature, creating a monolithic build that avoids
# Qt6BuildInternals complexity.

set(QT_VERSION 6.4.2)

# ============================================================================
# Feature mapping
# ============================================================================

vcpkg_check_features(OUT_FEATURE_OPTIONS _unused
    FEATURES
    "brotli"          _HAS_BROTLI
    "concurrent"      _HAS_CONCURRENT
    "dbus"            _HAS_DBUS
    "freetype"        _HAS_FREETYPE
    "gui"             _HAS_GUI
    "harfbuzz"        _HAS_HARFBUZZ
    "icu"             _HAS_ICU
    "jpeg"            _HAS_JPEG
    "network"         _HAS_NETWORK
    "opengl"          _HAS_OPENGL
    "openssl"         _HAS_OPENSSL
    "png"             _HAS_PNG
    "printsupport"    _HAS_PRINTSUPPORT
    "sessionmanager"  _HAS_SESSIONMANAGER
    "sql"             _HAS_SQL
    "sql-sqlite"      _HAS_SQL_SQLITE
    "sql-psql"        _HAS_SQL_PSQL
    "qtsvg"           _HAS_QTSVG
    "testlib"         _HAS_TESTLIB
    "thread"          _HAS_THREAD
    "widgets"         _HAS_WIDGETS
    "xml"             _HAS_XML
    "zstd"            _HAS_ZSTD
)

# Helper: convert bool var to ON/OFF string
macro(_on_off var out)
    if(${var})
        set(${out} ON)
    else()
        set(${out} OFF)
    endif()
endmacro()

_on_off(_HAS_CONCURRENT _V_CONCURRENT)
_on_off(_HAS_DBUS        _V_DBUS)
_on_off(_HAS_GUI         _V_GUI)
_on_off(_HAS_NETWORK     _V_NETWORK)
_on_off(_HAS_OPENGL      _V_OPENGL)
_on_off(_HAS_PRINTSUPPORT   _V_PRINTSUPPORT)
_on_off(_HAS_SESSIONMANAGER _V_SESSIONMANAGER)
_on_off(_HAS_SQL         _V_SQL)
_on_off(_HAS_TESTLIB     _V_TESTLIB)
_on_off(_HAS_WIDGETS     _V_WIDGETS)
_on_off(_HAS_XML         _V_XML)
_on_off(_HAS_ICU         _V_ICU)
_on_off(_HAS_ZSTD        _V_ZSTD)

# Map features to Qt configure flags
set(FEATURE_OPTIONS
    -DFEATURE_concurrent=${_V_CONCURRENT}
    -DFEATURE_dbus=${_V_DBUS}
    -DFEATURE_gui=${_V_GUI}
    -DFEATURE_network=${_V_NETWORK}
    -DFEATURE_opengl=${_V_OPENGL}
    -DFEATURE_thread=ON
    -DFEATURE_process=ON
    -DFEATURE_printsupport=${_V_PRINTSUPPORT}
    -DFEATURE_sessionmanager=${_V_SESSIONMANAGER}
    -DFEATURE_sql=${_V_SQL}
    -DFEATURE_testlib=${_V_TESTLIB}
    -DFEATURE_widgets=${_V_WIDGETS}
    -DFEATURE_xml=${_V_XML}
)

# GUI-dependent features
if(_HAS_GUI)
    _on_off(_HAS_FREETYPE  _V_FREETYPE)
    _on_off(_HAS_HARFBUZZ  _V_HARFBUZZ)
    _on_off(_HAS_JPEG      _V_JPEG)
    _on_off(_HAS_PNG       _V_PNG)
    list(APPEND FEATURE_OPTIONS
        -DFEATURE_freetype=${_V_FREETYPE}
        -DFEATURE_harfbuzz=${_V_HARFBUZZ}
        -DFEATURE_jpeg=${_V_JPEG}
        -DFEATURE_png=${_V_PNG}
    )
else()
    list(APPEND FEATURE_OPTIONS
        -DFEATURE_freetype=OFF
        -DFEATURE_harfbuzz=OFF
        -DFEATURE_jpeg=OFF
        -DFEATURE_png=OFF
    )
endif()

# Network-dependent features
if(_HAS_NETWORK)
    _on_off(_HAS_OPENSSL _V_OPENSSL)
    _on_off(_HAS_BROTLI  _V_BROTLI)
    list(APPEND FEATURE_OPTIONS
        -DFEATURE_openssl=${_V_OPENSSL}
        -DFEATURE_brotli=${_V_BROTLI}
    )
    if(_HAS_OPENSSL)
        list(APPEND FEATURE_OPTIONS -DINPUT_openssl=linked)
    endif()
else()
    list(APPEND FEATURE_OPTIONS
        -DFEATURE_openssl=OFF
        -DFEATURE_brotli=OFF
    )
endif()

# SQL driver flags
if(_HAS_SQL)
    _on_off(_HAS_SQL_SQLITE _V_SQL_SQLITE)
    list(APPEND FEATURE_OPTIONS
        -DFEATURE_sql_odbc=OFF
        -DFEATURE_sql_mysql=OFF
        -DFEATURE_sql_oci=OFF
        -DFEATURE_system_sqlite=${_V_SQL_SQLITE}
    )
    if(NOT _HAS_SQL_PSQL)
        list(APPEND FEATURE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_PostgreSQL=ON)
    endif()
    if(NOT _HAS_SQL_SQLITE)
        list(APPEND FEATURE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_SQLite3=ON)
    endif()
else()
    list(APPEND FEATURE_OPTIONS
        -DCMAKE_DISABLE_FIND_PACKAGE_PostgreSQL=ON
        -DCMAKE_DISABLE_FIND_PACKAGE_SQLite3=ON
        -DCMAKE_DISABLE_FIND_PACKAGE_ODBC=ON
        -DCMAKE_DISABLE_FIND_PACKAGE_MySQL=ON
        -DCMAKE_DISABLE_FIND_PACKAGE_Oracle=ON
    )
endif()

# ICU / zstd
list(APPEND FEATURE_OPTIONS
    -DFEATURE_icu=${_V_ICU}
    -DFEATURE_zstd=${_V_ZSTD}
)
if(_HAS_ICU)
    list(APPEND FEATURE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_ICU=OFF)
else()
    list(APPEND FEATURE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_ICU=ON)
endif()
if(_HAS_ZSTD)
    list(APPEND FEATURE_OPTIONS -DCMAKE_REQUIRE_FIND_PACKAGE_zstd=ON)
else()
    list(APPEND FEATURE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_ZSTD=ON)
endif()

# Input options for system libraries
set(INPUT_OPTIONS
    -DINPUT_doubleconversion=system
    -DINPUT_libmd4c=qt
)
if(_HAS_FREETYPE)
    list(APPEND INPUT_OPTIONS -DINPUT_freetype=system)
endif()
if(_HAS_HARFBUZZ)
    list(APPEND INPUT_OPTIONS -DINPUT_harfbuzz=system)
endif()
if(_HAS_JPEG)
    list(APPEND INPUT_OPTIONS -DINPUT_libjpeg=system)
endif()
if(_HAS_PNG)
    list(APPEND INPUT_OPTIONS -DINPUT_libpng=system)
endif()

# Unconditionally disabled packages (not feature-gated)
set(DISABLE_OPTIONS
    -DCMAKE_DISABLE_FIND_PACKAGE_ATSPI2=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_DirectFB=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Fontconfig=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_GLIB2=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_GSSAPI=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_GTK3=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Libdrm=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Libinput=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Libproxy=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_LTTngUST=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Mtdev=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_PPS=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Slog2=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Tslib=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Vulkan=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_X11=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_XCB=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_XKB=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_X11_XCB=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_XKB_COMMON_X11=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_XRender=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_gbm=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_libb2=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_DB2=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Interbase=ON
    -DFEATURE_glib=OFF
    -DFEATURE_fontconfig=OFF
    -DFEATURE_xlib=OFF
    -DFEATURE_xkbcommon=OFF
    -DFEATURE_xcb=OFF
    -DFEATURE_xcb_xlib=OFF
    -DFEATURE_xkbcommon_x11=OFF
    -DFEATURE_xrender=OFF
    -DFEATURE_xcb_native_painting=OFF
    -DFEATURE_opengles2=OFF
    -DFEATURE_opengles3=OFF
    -DFEATURE_opengles31=OFF
    -DFEATURE_opengles32=OFF
    -DFEATURE_egl=OFF
    -DCMAKE_DISABLE_FIND_PACKAGE_EGL=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_GLESv2=ON
    -DINPUT_bundled_xcb_xinput=no
    -DINPUT_xcb=no
    -DINPUT_xkbcommon=no
)

# CUPS is needed by PrintSupport on macOS; disable everywhere else
if(NOT VCPKG_TARGET_IS_OSX OR NOT _HAS_PRINTSUPPORT)
    list(APPEND DISABLE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_Cups=ON)
endif()

if(NOT _HAS_DBUS)
    list(APPEND DISABLE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_WrapDBus1=ON)
endif()
if(NOT _HAS_BROTLI)
    list(APPEND DISABLE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_WrapBrotli=ON)
endif()
if(NOT _HAS_OPENSSL)
    list(APPEND DISABLE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_WrapOpenSSL=ON)
endif()

# Platform-specific
set(PLATFORM_OPTIONS "")
if(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND PLATFORM_OPTIONS -DFEATURE_opengl_desktop=ON)
elseif(VCPKG_TARGET_IS_OSX)
    list(APPEND PLATFORM_OPTIONS
        -DFEATURE_opengl_desktop=ON
    )
endif()

# Bundled library overrides
set(BUNDLE_OPTIONS
    -DQT_USE_BUNDLED_BundledFreetype=OFF
    -DQT_USE_BUNDLED_BundledHarfbuzz=OFF
    -DQT_USE_BUNDLED_BundledLibpng=OFF
    -DQT_USE_BUNDLED_BundledPcre2=OFF
    -DQT_USE_BUNDLED_BundledZLIB=OFF
)

# ============================================================================
# Download sources
# ============================================================================

vcpkg_download_distfile(QTBASE_ARCHIVE
    URLS
        "https://github.com/ayourk/hobbycad-vcpkg/releases/download/sources/qt6-base_${QT_VERSION}+dfsg.orig.tar.xz"
    FILENAME "qt6-base_${QT_VERSION}+dfsg.orig.tar.xz"
    SHA512 2704b90dab05ad2bc31a1171e2818aaa694d5d579d0defe27f9806f3d6c6263467c0673415b3fa73612e45f076442b5fe003d79b9eb758489616263153189a8d
)

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

# ============================================================================
# Restore configure.cmake files stripped by dfsg
# ============================================================================
# The dfsg tarball removes configure.cmake files that Qt's build system
# needs for feature auto-detection (QProcess, QTemporaryFile, etc.).
# Without them, features are undefined and platform-specific tools
# (macdeployqt, windeployqt) fail to compile. The files are shipped
# alongside this port in the dfsg-configure/ directory, sourced from
# upstream Qt 6.4.2 (tag v6.4.2).

set(_configure_restore
    "configure.cmake|."
    "corelib-configure.cmake|src/corelib"
    "gui-configure.cmake|src/gui"
    "network-configure.cmake|src/network"
    "widgets-configure.cmake|src/widgets"
    "sql-configure.cmake|src/sql"
    "xml-configure.cmake|src/xml"
    "printsupport-configure.cmake|src/printsupport"
    "testlib-configure.cmake|src/testlib"
    "tools-configure.cmake|src/tools"
)

foreach(_entry IN LISTS _configure_restore)
    string(REPLACE "|" ";" _parts "${_entry}")
    list(GET _parts 0 _src_name)
    list(GET _parts 1 _dest_dir)
    set(_dest "${QTBASE_SOURCE_PATH}/${_dest_dir}/configure.cmake")
    if(NOT EXISTS "${_dest}")
        file(COPY "${CMAKE_CURRENT_LIST_DIR}/dfsg-configure/${_src_name}"
             DESTINATION "${QTBASE_SOURCE_PATH}/${_dest_dir}")
        file(RENAME "${QTBASE_SOURCE_PATH}/${_dest_dir}/${_src_name}" "${_dest}")
    endif()
endforeach()

# ============================================================================
# QtSvg integration (only when qtsvg feature is enabled)
# ============================================================================

if(_HAS_QTSVG)
    vcpkg_download_distfile(QTSVG_ARCHIVE
        URLS
            "https://github.com/ayourk/hobbycad-vcpkg/releases/download/sources/qt6-svg_${QT_VERSION}.orig.tar.xz"
        FILENAME "qt6-svg_${QT_VERSION}.orig.tar.xz"
        SHA512 9b9de3f19a6c98d61ec1b4ba1883aada3b57db8e2ce56a493b6d7c639ed49a43f51c16b11f65cf8ee7ba8c8f4c61e1eedebb99c8645acfcc934048f2eb76fe64
    )

    vcpkg_extract_source_archive(
        QTSVG_SOURCE_PATH
        ARCHIVE "${QTSVG_ARCHIVE}"
        SOURCE_BASE "qtsvg-everywhere-src-${QT_VERSION}"
    )

    file(COPY "${QTSVG_SOURCE_PATH}/src/svg" DESTINATION "${QTBASE_SOURCE_PATH}/src/")

    file(MAKE_DIRECTORY "${QTBASE_SOURCE_PATH}/include/QtSvg")
    file(COPY "${QTBASE_SOURCE_PATH}/src/svg/qsvgrenderer.h" DESTINATION "${QTBASE_SOURCE_PATH}/include/QtSvg/")
    file(COPY "${QTBASE_SOURCE_PATH}/src/svg/qsvggenerator.h" DESTINATION "${QTBASE_SOURCE_PATH}/include/QtSvg/")
    file(COPY "${QTBASE_SOURCE_PATH}/src/svg/qtsvgglobal.h" DESTINATION "${QTBASE_SOURCE_PATH}/include/QtSvg/")

    file(WRITE "${QTBASE_SOURCE_PATH}/include/QtSvg/QSvgRenderer" "#include \"qsvgrenderer.h\"\n")
    file(WRITE "${QTBASE_SOURCE_PATH}/include/QtSvg/QSvgGenerator" "#include \"qsvggenerator.h\"\n")
    file(WRITE "${QTBASE_SOURCE_PATH}/include/QtSvg/QtSvg" "#include \"qtsvgglobal.h\"\n#include \"qsvgrenderer.h\"\n#include \"qsvggenerator.h\"\n")
    file(WRITE "${QTBASE_SOURCE_PATH}/include/QtSvg/QtSvgVersion" "#include \"qtsvgversion.h\"\n")

    file(REMOVE "${QTBASE_SOURCE_PATH}/src/svg/.cmake.conf")
    file(REMOVE "${QTBASE_SOURCE_PATH}/src/svg/Qt6SvgMacros.cmake")

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

    string(REPLACE "." ";" _qt_version_list "${QT_VERSION}")
    list(GET _qt_version_list 0 _qt_major)
    list(GET _qt_version_list 1 _qt_minor)
    list(GET _qt_version_list 2 _qt_patch)
    string(LENGTH "${_qt_minor}" _minor_len)
    string(LENGTH "${_qt_patch}" _patch_len)
    if(_minor_len EQUAL 1)
        set(_qt_minor "0${_qt_minor}")
    endif()
    if(_patch_len EQUAL 1)
        set(_qt_patch "0${_qt_patch}")
    endif()
    file(WRITE "${QTBASE_SOURCE_PATH}/include/QtSvg/qtsvgversion.h"
"#ifndef QTSVGVERSION_H
#define QTSVGVERSION_H
#define QTSVG_VERSION_STR \"${QT_VERSION}\"
#define QTSVG_VERSION 0x0${_qt_major}${_qt_minor}${_qt_patch}
#endif
")

    file(READ "${QTBASE_SOURCE_PATH}/src/svg/qtsvgglobal_p.h" _svgglobal_p)
    string(REPLACE
        "#include <QtSvg/private/qtsvgexports_p.h>"
        "// For static builds, export macros are empty\n#define Q_SVG_PRIVATE_EXPORT Q_SVG_EXPORT"
        _svgglobal_p "${_svgglobal_p}")
    file(WRITE "${QTBASE_SOURCE_PATH}/src/svg/qtsvgglobal_p.h" "${_svgglobal_p}")

    file(WRITE "${QTBASE_SOURCE_PATH}/src/svg/CMakeLists.txt"
"# Qt6 SVG Module - integrated into qtbase build

if(NOT QT_FEATURE_system_zlib)
    find_package(Qt6 COMPONENTS ZlibPrivate)
elseif(NOT TARGET WrapZLIB::WrapZLIB)
    qt_find_package(WrapZLIB PROVIDED_TARGETS WrapZLIB::WrapZLIB)
endif()

set(_svg_build_include_dir \"\${QT_BUILD_DIR}/include/QtSvg\")
file(MAKE_DIRECTORY \"\${_svg_build_include_dir}\")
file(MAKE_DIRECTORY \"\${_svg_build_include_dir}/${QT_VERSION}\")
file(MAKE_DIRECTORY \"\${_svg_build_include_dir}/${QT_VERSION}/QtSvg\")
file(MAKE_DIRECTORY \"\${_svg_build_include_dir}/${QT_VERSION}/QtSvg/private\")

set(_svg_source_include_dir \"\${CMAKE_CURRENT_SOURCE_DIR}/../../include/QtSvg\")
if(EXISTS \"\${_svg_source_include_dir}\")
    file(GLOB _svg_headers \"\${_svg_source_include_dir}/*\")
    foreach(_header \${_svg_headers})
        if(NOT IS_DIRECTORY \"\${_header}\")
            get_filename_component(_header_name \"\${_header}\" NAME)
            configure_file(\"\${_header}\" \"\${_svg_build_include_dir}/\${_header_name}\" COPYONLY)
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

qt_internal_extend_target(Svg CONDITION MSVC AND (TEST_architecture_arch STREQUAL \"i386\")
    LINK_OPTIONS \"/BASE:0x66000000\"
)

qt_internal_extend_target(Svg CONDITION QT_FEATURE_system_zlib
    LIBRARIES WrapZLIB::WrapZLIB
)

qt_internal_extend_target(Svg CONDITION NOT QT_FEATURE_system_zlib
    LIBRARIES Qt::ZlibPrivate
)
")

    file(READ "${QTBASE_SOURCE_PATH}/src/CMakeLists.txt" _src_cmake)
    if(NOT _src_cmake MATCHES "add_subdirectory\\(svg\\)")
        string(APPEND _src_cmake "\n# QtSvg module (integrated)\nadd_subdirectory(svg)\n")
        file(WRITE "${QTBASE_SOURCE_PATH}/src/CMakeLists.txt" "${_src_cmake}")
    endif()
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
# Configure and build
# ============================================================================

vcpkg_cmake_configure(
    SOURCE_PATH "${QTBASE_SOURCE_PATH}"
    OPTIONS
        -DBUILD_SHARED_LIBS=OFF
        -DQT_BUILD_EXAMPLES=OFF
        -DQT_BUILD_TESTS=OFF
        -DQT_BUILD_BENCHMARKS=OFF
        -DQT_FORCE_BUILD_TOOLS=ON
        -DFEATURE_relocatable=ON
        -DHOST_PERL=${PERL}
        ${FEATURE_OPTIONS}
        ${INPUT_OPTIONS}
        ${PLATFORM_OPTIONS}
        ${DISABLE_OPTIONS}
        ${BUNDLE_OPTIONS}
)

vcpkg_cmake_install()

# ============================================================================
# Install QtSvg headers (when qtsvg feature is enabled)
# ============================================================================

if(_HAS_QTSVG)
    set(_svg_include_dest "${CURRENT_PACKAGES_DIR}/include/QtSvg")
    file(MAKE_DIRECTORY "${_svg_include_dest}")

    file(GLOB _svg_headers "${QTBASE_SOURCE_PATH}/include/QtSvg/*")
    foreach(_header IN LISTS _svg_headers)
        if(NOT IS_DIRECTORY "${_header}")
            file(COPY "${_header}" DESTINATION "${_svg_include_dest}")
        endif()
    endforeach()
endif()

# ============================================================================
# Fix up cmake configs
# ============================================================================

file(GLOB _qt6_cmake_dirs "${CURRENT_PACKAGES_DIR}/lib/cmake/Qt6*")
foreach(_dir IN LISTS _qt6_cmake_dirs)
    get_filename_component(_comp "${_dir}" NAME)
    if(NOT "${_comp}" STREQUAL "Qt6BuildInternals")
        file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/${_comp}")
        file(WRITE "${CURRENT_PACKAGES_DIR}/share/${_comp}/${_comp}Config.cmake"
            "include(\"\${CMAKE_CURRENT_LIST_DIR}/../../lib/cmake/${_comp}/${_comp}Config.cmake\")\n")
    endif()
endforeach()

if(_HAS_QTSVG AND EXISTS "${CURRENT_PACKAGES_DIR}/lib/cmake/Qt6Svg/Qt6SvgTargets.cmake")
    file(READ "${CURRENT_PACKAGES_DIR}/lib/cmake/Qt6Svg/Qt6SvgTargets.cmake" _svg_targets)
    if(NOT _svg_targets MATCHES "include/QtSvg")
        file(APPEND "${CURRENT_PACKAGES_DIR}/lib/cmake/Qt6Svg/Qt6SvgTargets.cmake"
"\n# Fix include directories for NO_SYNC_QT module
if(TARGET Qt6::Svg)
    if(NOT DEFINED _IMPORT_PREFIX)
        get_filename_component(_IMPORT_PREFIX \"\${CMAKE_CURRENT_LIST_FILE}\" PATH)
        get_filename_component(_IMPORT_PREFIX \"\${_IMPORT_PREFIX}\" PATH)
        get_filename_component(_IMPORT_PREFIX \"\${_IMPORT_PREFIX}\" PATH)
        get_filename_component(_IMPORT_PREFIX \"\${_IMPORT_PREFIX}\" PATH)
    endif()
    get_target_property(_svg_includes Qt6::Svg INTERFACE_INCLUDE_DIRECTORIES)
    if(_svg_includes)
        list(APPEND _svg_includes \"\${_IMPORT_PREFIX}/include/QtSvg\")
    else()
        set(_svg_includes \"\${_IMPORT_PREFIX}/include/QtSvg\")
    endif()
    set_target_properties(Qt6::Svg PROPERTIES INTERFACE_INCLUDE_DIRECTORIES \"\${_svg_includes}\")
endif()
")
    endif()
endif()

file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/Qt6")
# Prepend find_dependency(Threads) to the installed Qt6Config.cmake
# so Threads::Threads exists before Qt6Targets.cmake references it.
set(_qt6_config "${CURRENT_PACKAGES_DIR}/lib/cmake/Qt6/Qt6Config.cmake")
if(EXISTS "${_qt6_config}")
    file(READ "${_qt6_config}" _qt6_config_content)
    file(WRITE "${_qt6_config}" "include(CMakeFindDependencyMacro)\nfind_dependency(Threads)\n${_qt6_config_content}")
endif()

file(WRITE "${CURRENT_PACKAGES_DIR}/share/Qt6/Qt6Config.cmake"
    "include(\"\${CMAKE_CURRENT_LIST_DIR}/../../lib/cmake/Qt6/Qt6Config.cmake\")\n")

vcpkg_copy_pdbs()

# ============================================================================
# Clean up
# ============================================================================

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/lib/cmake"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/share/Qt6BuildInternals"
    "${CURRENT_PACKAGES_DIR}/share/Qt6/QtBuildInternals"
)

vcpkg_install_copyright(FILE_LIST "${QTBASE_SOURCE_PATH}/LICENSES/LGPL-3.0-only.txt")
