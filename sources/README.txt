Source Archives for HobbyCAD vcpkg Registry
=============================================

These are git snapshots taken on 2026-02-08 from the upstream
repositories listed below. They are the same .orig.tar.gz files
used for the Launchpad PPA builds.

Upload these files as GitHub release assets under the tag "sources":

  libslvs_3.2.git~20260208.orig.tar.gz
    Upstream:  https://github.com/solvespace/solvespace
    Commit:    02ec4e57aa90f70052f6a312aa5c286a64a7ec90

  libopenmesh_11.0.0.git~20260208.orig.tar.gz
    Upstream:  https://gitlab.vci.rwth-aachen.de:9000/OpenMesh/OpenMesh
    Tag:       OpenMesh-11.0.0

  lib3mf_2.4.1.git~20260208.orig.tar.gz
    Upstream:  https://github.com/3MFConsortium/lib3mf
    Tag:       v2.4.1 (20c335489c69d15c64f3eaf1e15143b8176901f5)

  meshfix_2.1.git~20260208.orig.tar.gz
    Upstream:  https://github.com/MarcoAttene/MeshFix-V2.1
    Commit:    6dd727b6d1ee04e7a5554aaf05fa6c7106c0dccb

To create the release:

  gh release create sources --title "Source Archives" \
      --notes "Source tarballs for vcpkg port builds" \
      libslvs_3.2.git~20260208.orig.tar.gz \
      libopenmesh_11.0.0.git~20260208.orig.tar.gz \
      lib3mf_2.4.1.git~20260208.orig.tar.gz \
      meshfix_2.1.git~20260208.orig.tar.gz
