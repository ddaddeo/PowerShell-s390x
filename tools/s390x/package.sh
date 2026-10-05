#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIGURATION="${CONFIGURATION:-Debug}"
DEST_ROOT="${1:-/home/oper1}"
PWSH_DIR="$REPO_ROOT/src/powershell-unix/bin/$CONFIGURATION/net10.0"
PACKAGE_DIR="$DEST_ROOT/pwsh-s390x"

[[ -f "$PWSH_DIR/pwsh.dll" ]] || { echo "ERROR: pwsh.dll is missing" >&2; exit 1; }
[[ -f "$PWSH_DIR/libpsl-native.so" ]] || { echo "ERROR: libpsl-native.so is missing" >&2; exit 1; }

version="$(LD_LIBRARY_PATH="$PWSH_DIR" dotnet "$PWSH_DIR/pwsh.dll" -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' | tr -d '\r' | tail -1)"
[[ -n "$version" ]] || { echo "ERROR: unable to determine PowerShell version" >&2; exit 1; }

rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"
cp -a "$PWSH_DIR/." "$PACKAGE_DIR/"

cat > "$PACKAGE_DIR/pwsh" <<'LAUNCHER'
#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="${DIR}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
exec dotnet "${DIR}/pwsh.dll" "$@"
LAUNCHER
chmod 755 "$PACKAGE_DIR/pwsh"

"$PACKAGE_DIR/pwsh" -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion' >/dev/null
archive="$DEST_ROOT/powershell-${version}-linux-s390x.tar.gz"
tar -C "$DEST_ROOT" -czf "$archive" pwsh-s390x
sha256sum "$archive" > "$archive.sha256"

echo "PASS: package created"
echo "$archive"
echo "$archive.sha256"
