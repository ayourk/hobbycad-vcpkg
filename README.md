# ayourk/hobbycad-vcpkg

[![Build Ports](https://github.com/ayourk/hobbycad-vcpkg/actions/workflows/build-ports.yml/badge.svg)](https://github.com/ayourk/hobbycad-vcpkg/actions/workflows/build-ports.yml)

Custom vcpkg registry for [HobbyCAD](https://github.com/ayourk/hobbycad) dependencies that are not available in the official vcpkg registry.

## Packages

| Port | Version | License | Description |
|---|---|---|---|
| `libslvs` | 3.2p1 | GPL 3.0 | SolveSpace constraint solver library with HobbyCAD patches |
| `opencascade` | 8.0.1 (+p1) | LGPL 2.1 | Open CASCADE Technology with HobbyCAD BSD portability patches |
| `openmesh` | 11.0.0 | BSD 3-Clause | OpenMesh polygon mesh data structure |
| `lib3mf` | 2.5.0 (+p1) | BSD 2-Clause | 3MF file format reading/writing library with HobbyCAD build-system patches |
| `meshfix` | 2.1 | GPL 3.0+ | Mesh repair tool and library |

## Usage

HobbyCAD already includes `vcpkg-configuration.json` and `vcpkg.json` in its
repository root — no manual setup is needed. The registry is resolved
automatically when building with the vcpkg toolchain.

For other projects, add this registry to your `vcpkg-configuration.json`:

```json
{
  "default-registry": {
    "kind": "builtin",
    "baseline": "2026.01.16"
  },
  "registries": [
    {
      "kind": "git",
      "repository": "https://github.com/ayourk/hobbycad-vcpkg",
      "baseline": "REPLACE_WITH_LATEST_COMMIT_HASH",
      "packages": ["libslvs", "openmesh", "lib3mf", "meshfix"]
    }
  ]
}
```

Update the `baseline` hash after each commit to this registry.  To get the
latest commit hash, visit the
[commit history](https://github.com/ayourk/hobbycad-vcpkg/commits/main) and
copy the full 40-character SHA from the latest entry.

Then reference the ports in your `vcpkg.json`:

```json
{
  "dependencies": [
    "libslvs",
    "openmesh",
    "lib3mf",
    "meshfix"
  ]
}
```

## Source Archives

Each port downloads source tarballs hosted as release assets on this repo
(tag: `sources`). These are the same sources used in the
[Launchpad PPA](https://launchpad.net/~ayourk/+archive/ubuntu/hobbycad) builds.

| Port | Upstream | Source Archive |
|---|---|---|
| `libslvs` | [solvespace/solvespace](https://github.com/solvespace/solvespace) master `952c11c0`, HobbyCAD patches cut 2026-09-08 | `libslvs_3.2.git.20260908+p1.orig.tar.gz` |
| `opencascade` | [Open-Cascade-SAS/OCCT](https://github.com/Open-Cascade-SAS/OCCT) @ `V8_0_1` + HobbyCAD BSD patches | `opencascade_8.0.1+p1.orig.tar.xz` |
| `openmesh` | [OpenMesh/OpenMesh](https://gitlab.vci.rwth-aachen.de:9000/OpenMesh/OpenMesh) @ `OpenMesh-11.0.0` | `libopenmesh_11.0.0.git.20260208.orig.tar.gz` |
| `lib3mf` | [3MFConsortium/lib3mf](https://github.com/3MFConsortium/lib3mf) @ `v2.5.0` + HobbyCAD build-system patches, without the prebuilt generator binaries | `lib3mf_2.5.0+p1.orig.tar.xz` |
| `meshfix` | [MarcoAttene/MeshFix-V2.1](https://github.com/MarcoAttene/MeshFix-V2.1) @ `6dd727b` | `meshfix_2.1.git.20260208.orig.tar.gz` |

### Updating source archives

When updating a port to a new upstream version:

1. Build and test in the PPA first
2. Upload the `.orig.tar.gz` to the `sources` release on this repo
   (GitHub stores a `~` in the asset name as `.`, so the URL spells
   `libslvs_3.2.git.20260908+p1...` for the PPA's `3.2.git~20260908+p1`)
3. Update `VERSION`, filenames, and `SHA512` in the portfile (`sha512sum <file>.tar.gz`)
4. Update `versions/` (see Maintainer Notes) in the same commit as the port

## Maintainer Notes

After modifying any port, update the version database:

```bash
# From the registry root:
vcpkg --x-builtin-ports-root=./ports --x-builtin-registry-versions-dir=./versions x-add-version --all --overwrite-version
```

Or use the provided helper script:

```bash
./scripts/update-versions.sh
```

A GitHub Actions workflow automatically test-builds all ports on Windows (`x64-windows`) whenever port files change. Check the build badge above for current status.

## License

Registry metadata is MIT licensed. Individual ports retain their upstream licenses.
