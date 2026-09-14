# qttools 6.4.2 for ClaudeQt — direct build without qt_install_submodule.
#
# The builtin vcpkg qtbase port ships qt_install_submodule.cmake, but
# hobbycad-vcpkg's custom qtbase port does not. This portfile uses
# vcpkg_from_git + vcpkg_cmake_configure directly.

set(QT_VERSION 6.4.2)

# Only apply the litehtml devendoring patch when building Assistant.
# The GUI gate in src/linguist/CMakeLists.txt checks Qt::Widgets but not
# Qt::PrintSupport, which the app links; without the patch a widgets-only
# Qt fails qttools' generate step and takes lrelease down with it.
set(PATCHES linguist-gui-needs-printsupport.patch)
if("assistant" IN_LIST FEATURES)
    list(APPEND PATCHES devendor-litehtml.patch)
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://code.qt.io/qt/qttools.git
    REF 2ddbe1df490a4f9a7963a3dc78a8d865165cbf5b
    PATCHES ${PATCHES}
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
    "assistant" FEATURE_assistant
    "designer" FEATURE_designer
    "qdbus" FEATURE_qdbus
    "qdoc"   CMAKE_REQUIRE_FIND_PACKAGE_Clang
    "qml"    CMAKE_REQUIRE_FIND_PACKAGE_Qt6Qml
    "qml"    CMAKE_REQUIRE_FIND_PACKAGE_Qt6Quick
    "qml"    CMAKE_REQUIRE_FIND_PACKAGE_Qt6QuickWidgets
    "qml"    FEATURE_distancefieldgenerator
    INVERTED_FEATURES
    "qdoc"   CMAKE_DISABLE_FIND_PACKAGE_Clang
    "qdoc"   CMAKE_DISABLE_FIND_PACKAGE_WrapLibClang
    "qml"    CMAKE_DISABLE_FIND_PACKAGE_Qt6Qml
    "qml"    CMAKE_DISABLE_FIND_PACKAGE_Qt6Quick
    "qml"    CMAKE_DISABLE_FIND_PACKAGE_Qt6QuickWidgets
    )

set(EXTRA_CONFIGURE_OPTIONS "")
if(NOT "assistant" IN_LIST FEATURES)
    list(APPEND EXTRA_CONFIGURE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_litehtml=ON)
endif()
# Qt builds its graphical helper utilities whenever Widgets exists. Nothing
# here names them, pixeltool does not even link on a static macOS Qt
# (OpenGL symbols), and a static build must not ship a bin/ full of apps,
# so each is switched off through its own Qt feature unless the port
# feature that lists it asks for it.
list(APPEND EXTRA_CONFIGURE_OPTIONS
    -DFEATURE_qtdiag=OFF
    -DFEATURE_qtplugininfo=OFF
    -DFEATURE_kmap2qmap=OFF
    -DFEATURE_qev=OFF)
if(NOT "designer" IN_LIST FEATURES)
    list(APPEND EXTRA_CONFIGURE_OPTIONS -DFEATURE_pixeltool=OFF -DFEATURE_distancefieldgenerator=OFF)
endif()
if(NOT "qdoc" IN_LIST FEATURES)
    list(APPEND EXTRA_CONFIGURE_OPTIONS -DFEATURE_qtattributionsscanner=OFF)
endif()

vcpkg_find_acquire_program(PERL)
get_filename_component(PERL_PATH ${PERL} DIRECTORY)
vcpkg_add_to_path(${PERL_PATH})

# lrelease, lupdate and lconvert need only QtCore, but Qt gates them behind
# its "linguist" feature together with the Linguist GUI. The command-line
# tools are the reason this port exists, so the feature is always on here;
# the GUI is built only when the port's own "linguist" feature adds the
# widgets and printsupport it needs (Qt skips it otherwise).
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DFEATURE_linguist=ON
        -DQT_BUILD_EXAMPLES=OFF
        -DQT_BUILD_TESTS=OFF
        -DHOST_PERL=${PERL}
        -DCMAKE_DISABLE_FIND_PACKAGE_Qt6AxContainer=ON
        ${FEATURE_OPTIONS}
        ${EXTRA_CONFIGURE_OPTIONS}
)

vcpkg_cmake_install()

# Move libexec tools into bin/ so vcpkg_copy_tools can find them.
if(EXISTS "${CURRENT_PACKAGES_DIR}/libexec")
    file(GLOB _libexec_tools "${CURRENT_PACKAGES_DIR}/libexec/*")
    foreach(_tool IN LISTS _libexec_tools)
        get_filename_component(_name "${_tool}" NAME)
        file(RENAME "${_tool}" "${CURRENT_PACKAGES_DIR}/bin/${_name}")
    endforeach()
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/libexec")
endif()
if(EXISTS "${CURRENT_PACKAGES_DIR}/debug/libexec")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/libexec")
endif()

# Relocate tools to the standard vcpkg tools directory.
set(TOOL_NAMES
    lconvert lprodump lrelease lrelease-pro lupdate lupdate-pro
)
if("assistant" IN_LIST FEATURES)
    list(APPEND TOOL_NAMES assistant qcollectiongenerator qhelpgenerator)
endif()
if("designer" IN_LIST FEATURES)
    list(APPEND TOOL_NAMES designer pixeltool qdistancefieldgenerator)
endif()
if("linguist" IN_LIST FEATURES)
    list(APPEND TOOL_NAMES linguist)
endif()
if("qdbus" IN_LIST FEATURES)
    list(APPEND TOOL_NAMES qdbus qdbusviewer)
endif()
if("qdoc" IN_LIST FEATURES)
    list(APPEND TOOL_NAMES qdoc)
endif()
vcpkg_copy_tools(TOOL_NAMES ${TOOL_NAMES} AUTO_CLEAN)

# qttools also builds diagnostic and helper executables that no feature names
# (qtdiag, qtplugininfo, qtattributionsscanner, pixeltool). Left in bin/ they
# are post-build findings, and in a static build bin/ must not exist at all;
# they belong with the other tools.
file(GLOB _qt_leftover_tools
    "${CURRENT_PACKAGES_DIR}/bin/*.exe" "${CURRENT_PACKAGES_DIR}/bin/*")
foreach(_t IN LISTS _qt_leftover_tools)
    if(NOT IS_DIRECTORY "${_t}")
        get_filename_component(_n "${_t}" NAME)
        file(RENAME "${_t}" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/${_n}")
    endif()
endforeach()
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

# vcpkg_copy_tools moved executables from bin/ to tools/qttools/.
# Patch the installed CMake targets files so downstream find_package()
# resolves the relocated paths instead of the now-empty bin/.
file(GLOB_RECURSE _targets_files
    "${CURRENT_PACKAGES_DIR}/lib/cmake/Qt6*/Qt6*Targets*.cmake"
    "${CURRENT_PACKAGES_DIR}/share/Qt6*/Qt6*Targets*.cmake"
)
foreach(_f IN LISTS _targets_files)
    vcpkg_replace_string("${_f}" "{_IMPORT_PREFIX}/bin/" "{_IMPORT_PREFIX}/tools/${PORT}/" IGNORE_UNCHANGED)
    vcpkg_replace_string("${_f}" "{_IMPORT_PREFIX}/./bin/" "{_IMPORT_PREFIX}/tools/${PORT}/" IGNORE_UNCHANGED)
    vcpkg_replace_string("${_f}" "{_IMPORT_PREFIX}/./libexec/" "{_IMPORT_PREFIX}/tools/${PORT}/" IGNORE_UNCHANGED)
endforeach()

if(VCPKG_TARGET_IS_OSX)
    set(OSX_APP_FOLDERS)
    if("designer" IN_LIST FEATURES)
        list(APPEND OSX_APP_FOLDERS Designer.app pixeltool.app)
    endif()
    if("linguist" IN_LIST FEATURES)
        list(APPEND OSX_APP_FOLDERS Linguist.app)
    endif()
    if("qdbus" IN_LIST FEATURES)
        list(APPEND OSX_APP_FOLDERS qdbusviewer.app)
    endif()
    foreach(_appfolder IN LISTS OSX_APP_FOLDERS)
        if(EXISTS "${CURRENT_PACKAGES_DIR}/bin/${_appfolder}")
            file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin/${_appfolder}")
            file(RENAME "${CURRENT_PACKAGES_DIR}/bin/${_appfolder}/" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin/${_appfolder}/")
        endif()
    endforeach()
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
if(EXISTS "${CURRENT_PACKAGES_DIR}/debug/bin")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()
if(EXISTS "${CURRENT_PACKAGES_DIR}/debug/lib/cmake")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/lib/cmake")
endif()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSES/GPL-3.0-only.txt")
