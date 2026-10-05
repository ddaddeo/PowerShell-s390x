#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIGURATION="${CONFIGURATION:-Debug}"
PWSH_DIR="$REPO_ROOT/src/powershell-unix/bin/$CONFIGURATION/net10.0"

[[ -f "$PWSH_DIR/pwsh.dll" ]] || { echo "ERROR: pwsh.dll is missing" >&2; exit 1; }
[[ -f "$PWSH_DIR/libpsl-native.so" ]] || { echo "ERROR: libpsl-native.so is missing" >&2; exit 1; }

file "$PWSH_DIR/libpsl-native.so" | grep -Eq 'IBM S/390|s390' \
  || { echo "ERROR: libpsl-native.so is not s390x" >&2; exit 1; }

if ldd "$PWSH_DIR/libpsl-native.so" 2>&1 | grep -q 'not found'; then
  ldd "$PWSH_DIR/libpsl-native.so" >&2
  echo "ERROR: native dependencies are missing" >&2
  exit 1
fi

LD_LIBRARY_PATH="$PWSH_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
dotnet "$PWSH_DIR/pwsh.dll" -NoLogo -NoProfile -Command '
$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSEdition -ne "Core") { throw "Unexpected PSEdition" }
$osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$processArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
$rid = [System.Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier
if ($osArch -ne "S390X") { throw "Unexpected OS architecture: $osArch" }
if ($processArch -ne "S390X") { throw "Unexpected process architecture: $processArch" }
Get-Process | Select-Object -First 1 | Out-Null
Get-ChildItem / | Select-Object -First 1 | Out-Null
Write-Host "PowerShell version:" $PSVersionTable.PSVersion
Write-Host "Runtime identifier:" $rid
Write-Host "PASS: PowerShell works on s390x"
'
