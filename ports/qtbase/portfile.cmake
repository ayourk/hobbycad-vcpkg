# Qt 6 Base Module for HobbyCAD static builds
# Source: PPA dfsg tarball (hosted on GitHub releases)

set(QT_VERSION 6.4.2)

vcpkg_download_distfile(ARCHIVE
    URLS
        "https://github.com/ayourk/hobbycad-vcpkg/releases/download/sources/qt6-base_${QT_VERSION}+dfsg.orig.tar.xz"
    FILENAME "qt6-base_${QT_VERSION}+dfsg.orig.tar.xz"
    SHA512 2704b90dab05ad2bc31a1171e2818aaa694d5d579d0defe27f9806f3d6c6263467c0673415b3fa73612e45f076442b5fe003d79b9eb758489616263153189a8d
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    SOURCE_BASE "qtbase-everywhere-src-${QT_VERSION}"
    PATCHES
        fix-macos-visibility-test.patch
        add-wintab-headers.patch
        fix-threads-global-promotion.patch
        fix-qduplicatetracker-include.patch
)

vcpkg_find_acquire_program(PERL)
get_filename_component(PERL_PATH ${PERL} DIRECTORY)
vcpkg_add_to_path(${PERL_PATH})

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_PATH ${PYTHON3} DIRECTORY)
vcpkg_add_to_path(${PYTHON3_PATH})

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

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
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

# Dynamically find and fixup all Qt6 cmake config directories
file(GLOB _qt6_cmake_dirs LIST_DIRECTORIES true "${CURRENT_PACKAGES_DIR}/lib/cmake/Qt6*")
foreach(_dir IN LISTS _qt6_cmake_dirs)
    if(IS_DIRECTORY "${_dir}")
        get_filename_component(_pkg_name "${_dir}" NAME)
        vcpkg_cmake_config_fixup(PACKAGE_NAME "${_pkg_name}" CONFIG_PATH "lib/cmake/${_pkg_name}")
    endif()
endforeach()

# Qt6BuildInternals may be nested under lib/cmake/Qt6/ instead of lib/cmake/Qt6BuildInternals/
# Handle this case explicitly before lib/cmake cleanup
if(EXISTS "${CURRENT_PACKAGES_DIR}/lib/cmake/Qt6/Qt6BuildInternals")
    file(COPY "${CURRENT_PACKAGES_DIR}/lib/cmake/Qt6/Qt6BuildInternals/" DESTINATION "${CURRENT_PACKAGES_DIR}/share/Qt6BuildInternals")
endif()
# Also copy from share/Qt6 if that's where it ended up after fixup
if(EXISTS "${CURRENT_PACKAGES_DIR}/share/Qt6/Qt6BuildInternals")
    file(COPY "${CURRENT_PACKAGES_DIR}/share/Qt6/Qt6BuildInternals/" DESTINATION "${CURRENT_PACKAGES_DIR}/share/Qt6BuildInternals")
endif()
# Legacy location check
if(EXISTS "${CURRENT_PACKAGES_DIR}/share/Qt6/QtBuildInternals")
    file(COPY "${CURRENT_PACKAGES_DIR}/share/Qt6/QtBuildInternals/" DESTINATION "${CURRENT_PACKAGES_DIR}/share/Qt6BuildInternals")
endif()

vcpkg_copy_pdbs()

# Copy tools (only for shared builds - static builds don't produce tools)
if(NOT VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    set(QT_TOOLS moc rcc uic)
    vcpkg_copy_tools(TOOL_NAMES ${QT_TOOLS} SEARCH_DIR "${CURRENT_PACKAGES_DIR}/bin" AUTO_CLEAN)
endif()

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
