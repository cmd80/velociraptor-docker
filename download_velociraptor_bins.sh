#!/usr/bin/env bash
#--------------------------------------------------------------
# Download the latest Velociraptor binaries (Linux, macOS, Windows)
# and place them in the repository’s bin/ directory.
# The script also updates every reference that points to an old
# binary name (entrypoint, custom_artifacts, init.vql, .env, etc.).
#--------------------------------------------------------------

set -euo pipefail

# ---- Configuration -------------------------------------------------
# Repository root (where this script lives)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Destination directory for the binaries
BIN_DIR="${REPO_ROOT}/bin"
mkdir -p "${BIN_DIR}"

# Velociraptor version to fetch – hard‑coded to the latest 0.76.x release.
# If a newer major version appears, bump this variable.
VERSION="0.76.5"

# Base URL for the GitHub release assets
BASE_URL="https://github.com/Velocidex/velociraptor/releases/download/v${VERSION}"

# Mapping of platform → filename (as published on GitHub)
declare -A ASSETS=(
    [linux_amd64]="velociraptor-${VERSION}-linux-amd64-musl"
    [linux_arm64]="velociraptor-${VERSION}-linux-arm64"
    [darwin_amd64]="velociraptor-${VERSION}-darwin-amd64"
    [darwin_arm64]="velociraptor-${VERSION}-darwin-arm64"
    [windows_amd64]="velociraptor-${VERSION}-windows-amd64.exe"
    [windows_386]="velociraptor-${VERSION}-windows-386.exe"
)

# ---- Helper functions ----------------------------------------------

download_one() {
    local platform=$1
    local fname=${ASSETS[$platform]}
    local url="${BASE_URL}/${fname}"
    local out="${BIN_DIR}/${fname}"

    echo "Downloading ${platform} → ${out}"
    curl -fsSL "${url}" -o "${out}"
    chmod +x "${out}"
}

# ---- Download all binaries ------------------------------------------

for plat in "${!ASSETS[@]}"; do
    download_one "$plat"
done

echo "All binaries stored in ${BIN_DIR}"

# ---- Update repository references ------------------------------------

# Files that contain hard‑coded binary paths
REF_FILES=(
    "${REPO_ROOT}/entrypoint"
    "${REPO_ROOT}/init.vql"
    "${REPO_ROOT}/.env"
    "${REPO_ROOT}/custom_artifacts/InitializeServer.yaml"
)

# Pattern to replace: any occurrence of "velociraptor‑*.exe" or "velociraptor‑*.linux*"
# We map the old version (if present) to the new one.
replace_in_file() {
    local file=$1
    local tmp="${file}.tmp"
    sed -E "
        s|velociraptor-v[0-9]+\.[0-9]+\.[0-9]+-linux-amd64-musl|velociraptor-${VERSION}-linux-amd64-musl|g;
        s|velociraptor-v[0-9]+\.[0-9]+\.[0-9]+-linux-arm64|velociraptor-${VERSION}-linux-arm64|g;
        s|velociraptor-v[0-9]+\.[0-9]+\.[0-9]+-darwin-amd64|velociraptor-${VERSION}-darwin-amd64|g;
        s|velociraptor-v[0-9]+\.[0-9]+\.[0-9]+-darwin-arm64|velociraptor-${VERSION}-darwin-arm64|g;
        s|velociraptor-v[0-9]+\.[0-9]+\.[0-9]+-windows-amd64\.exe|velociraptor-${VERSION}-windows-amd64.exe|g;
        s|velociraptor-v[0-9]+\.[0-9]+\.[0-9]+-windows-386\.exe|velociraptor-${VERSION}-windows-386.exe|g;
    " "${file}" > "${tmp}" && mv "${tmp}" "${file}"
}

echo "Updating binary references in project files..."
for f in "${REF_FILES[@]}"; do
    if [[ -f "${f}" ]]; then
        replace_in_file "${f}"
        echo "  → ${f}"
    fi
done

echo "Done. Remember to rebuild the Docker image if you changed the binary path:"
echo "  make build   # or: docker build -t velociraptor-server ."
