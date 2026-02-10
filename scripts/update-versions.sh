#!/bin/bash
# scripts/update-versions.sh
#
# Updates the vcpkg version database with actual git tree hashes.
#
# Usage:
#   1. Commit all port changes first:
#        git add ports/ && git commit -m "Update ports"
#   2. Run this script:
#        ./scripts/update-versions.sh
#   3. Commit the updated version files:
#        git add versions/ && git commit --amend --no-edit
#
# Alternatively, if you have vcpkg installed:
#   vcpkg --x-builtin-ports-root=./ports \
#         --x-builtin-registry-versions-dir=./versions \
#         x-add-version --all --overwrite-version

set -euo pipefail
cd "$(dirname "$0")/.."

PORTS_DIR="ports"
VERSIONS_DIR="versions"

update_port_version() {
    local port="$1"
    local first_letter="${port:0:1}"
    local version_file="${VERSIONS_DIR}/${first_letter}-/${port}.json"
    local port_dir="${PORTS_DIR}/${port}"

    if [ ! -d "$port_dir" ]; then
        echo "SKIP: ${port_dir} does not exist"
        return
    fi

    # Get the git tree hash for this port's directory
    local tree_hash
    tree_hash=$(git rev-parse "HEAD:${port_dir}" 2>/dev/null) || {
        echo "ERROR: Cannot get tree hash for ${port_dir}."
        echo "       Have you committed the port files?"
        return 1
    }

    # Read version and port-version from vcpkg.json
    local version port_version
    version=$(python3 -c "
import json, sys
with open('${port_dir}/vcpkg.json') as f:
    d = json.load(f)
    print(d.get('version', d.get('version-string', '')))
")
    port_version=$(python3 -c "
import json
with open('${port_dir}/vcpkg.json') as f:
    print(json.load(f).get('port-version', 0))
")

    # Write the version file
    mkdir -p "${VERSIONS_DIR}/${first_letter}-"
    python3 -c "
import json
data = {'versions': [{'version': '${version}', 'port-version': ${port_version}, 'git-tree': '${tree_hash}'}]}
# Preserve existing versions if updating
try:
    with open('${version_file}') as f:
        existing = json.load(f)
    # Check if this version already exists
    found = False
    for v in existing['versions']:
        if v['version'] == '${version}' and v.get('port-version', 0) == ${port_version}:
            v['git-tree'] = '${tree_hash}'
            found = True
            break
    if not found:
        existing['versions'].insert(0, data['versions'][0])
    data = existing
except (FileNotFoundError, json.JSONDecodeError):
    pass
with open('${version_file}', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
    echo "OK: ${port} ${version}#${port_version} -> ${tree_hash}"
}

# Update baseline.json
update_baseline() {
    python3 -c "
import json, os
baseline = {}
for port in sorted(os.listdir('${PORTS_DIR}')):
    manifest = os.path.join('${PORTS_DIR}', port, 'vcpkg.json')
    if os.path.isfile(manifest):
        with open(manifest) as f:
            d = json.load(f)
        baseline[port] = {
            'baseline': d.get('version', d.get('version-string', '')),
            'port-version': d.get('port-version', 0)
        }
with open('${VERSIONS_DIR}/baseline.json', 'w') as f:
    json.dump({'default': baseline}, f, indent=2)
    f.write('\n')
"
    echo "OK: baseline.json updated"
}

echo "=== Updating vcpkg version database ==="
echo ""

# Update each port
for port_dir in "${PORTS_DIR}"/*/; do
    port=$(basename "$port_dir")
    update_port_version "$port"
done

echo ""
update_baseline

echo ""
echo "Done. Now commit the version updates:"
echo "  git add versions/ && git commit --amend --no-edit"
