# vcpkg cmake wrapper for OpenCASCADE
# OpenCASCADE targets reference Freetype::Freetype but don't call find_package first
# This wrapper ensures dependencies are found before importing OpenCASCADE targets

find_package(Freetype QUIET)

_find_package(${ARGS})
