#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIGURATION="${CONFIGURATION:-Debug}"
NATIVE_ROOT="${NATIVE_ROOT:-$HOME/PowerShell-Native}"
NATIVE_URL="${NATIVE_URL:-https://github.com/PowerShell/PowerShell-Native.git}"
OUTPUT_DIR="$REPO_ROOT/src/powershell-unix/bin/$CONFIGURATION/net10.0"

fatal() { echo "ERROR: $*" >&2; exit 1; }

[[ "$(uname -m)" == "s390x" ]] || fatal "This build must run on s390x"
for cmd in git cmake make file; do command -v "$cmd" >/dev/null || fatal "$cmd is not installed"; done

if [[ ! -d "$NATIVE_ROOT/.git" ]]; then
  rm -rf "$NATIVE_ROOT"
  git clone "$NATIVE_URL" "$NATIVE_ROOT"
else
  git -C "$NATIVE_ROOT" fetch --all --tags --prune
fi

git -C "$NATIVE_ROOT" submodule update --init --recursive
rm -rf "$NATIVE_ROOT/build-libpsl"
mkdir -p "$NATIVE_ROOT/build-libpsl"

(
  cd "$NATIVE_ROOT/build-libpsl"
  cmake ../src/libpsl-native
  make -j"$(nproc)"
)

native_lib="$NATIVE_ROOT/src/powershell-unix/libpsl-native.so"
test -f "$native_lib" || fatal "libpsl-native.so was not produced"
file "$native_lib" | grep -Eq 'IBM S/390|s390' || fatal "Native library is not s390x"

mkdir -p "$OUTPUT_DIR"
cp -f "$native_lib" "$OUTPUT_DIR/"
file "$OUTPUT_DIR/libpsl-native.so"

echo "PASS: native library built and copied"
echo "Output: $OUTPUT_DIR/libpsl-native.so"
