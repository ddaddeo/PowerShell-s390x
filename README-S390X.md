# PowerShell on Linux s390x

Unofficial PowerShell port and repeatable build workflow for Linux on
IBM Z `s390x`.

This repository tracks the official PowerShell project and contains the
changes, documentation and automation required to build and run
PowerShell on Linux `s390x`.

## Project status

The following configuration has been successfully built and tested:

- PowerShell: `7.6.0`
- Operating system: Red Hat Enterprise Linux 9
- Architecture: `s390x`
- Runtime Identifier: `rhel.9-s390x`
- .NET SDK: `10.0.112`
- .NET runtime: `10.0.12`
- Port branch: `port/v7.6-s390x`
- First working port tag: `v7.6.0-s390x.1`

The validated build successfully runs:

```powershell
$PSVersionTable
Get-Process
Get-ChildItem /
```

The native PowerShell library is compiled as:

```text
ELF 64-bit MSB shared object, IBM S/390
```

## Support status

This is an unofficial community port.

It is not an official Microsoft PowerShell distribution for Linux
`s390x` or IBM Z.

## Repository model

The repository uses two Git remotes:

```text
origin    https://github.com/ddaddeo/PowerShell-s390x.git
upstream  https://github.com/PowerShell/PowerShell.git
```

The official repository is configured as `upstream`.

The s390x port repository is configured as `origin`.

Push access to `upstream` should remain disabled:

```bash
git remote set-url --push upstream DISABLED
```

Verify the remote configuration:

```bash
git remote -v
```

Expected configuration:

```text
origin    https://github.com/ddaddeo/PowerShell-s390x.git (fetch)
origin    https://github.com/ddaddeo/PowerShell-s390x.git (push)
upstream  https://github.com/PowerShell/PowerShell.git (fetch)
upstream  DISABLED (push)
```

## Branch and tag model

Port branches use the following convention:

```text
port/vX.Y-s390x
```

Examples:

```text
port/v7.6-s390x
port/v7.7-s390x
port/v8.0-s390x
```

Port tags use the following convention:

```text
vX.Y.Z-s390x.N
```

Examples:

```text
v7.6.0-s390x.1
v7.6.0-s390x.2
v7.6.1-s390x.1
```

Official upstream tags such as `v7.6.0` are never modified or replaced.

## Prerequisites

The build must run natively on a Linux `s390x` system.

The currently validated build environment uses Red Hat Enterprise Linux
9 on IBM Z.

### Install the required packages

Run the following commands as `root`, or prefix them with `sudo`:

```bash
dnf groupinstall -y "Development Tools"

dnf install -y \
  git \
  cmake \
  gcc \
  gcc-c++ \
  make \
  tar \
  gzip \
  openssl-devel \
  libicu-devel \
  zlib-devel \
  dotnet-sdk-10.0
```

### Validate the operating system

```bash
cat /etc/redhat-release
uname -m
```

Expected architecture:

```text
s390x
```

### Validate .NET

```bash
dotnet --version
dotnet --list-sdks
dotnet --list-runtimes
dotnet --info
```

Expected values for the currently validated PowerShell 7.6.0 port:

```text
.NET SDK:     10.0.112
.NET runtime: 10.0.12
Architecture: s390x
RID:          rhel.9-s390x
```

The SDK and runtime use different version formats:

```text
SDK:     10.0.112
Runtime: 10.0.12
```

This is expected.

Do not replace references to runtime version `10.0.12` with SDK version
`10.0.112`.

The exact SDK selected by the current port branch is defined in:

```text
global.json
```

Verify the selected SDK:

```bash
cat global.json
dotnet --version
```

The output of `dotnet --version` must match the SDK configured in
`global.json`.

### Validate the .NET runtime packs

The RHEL .NET installation must provide the runtime packs for
`rhel.9-s390x`.

```bash
find /usr/lib64/dotnet/packs \
  -maxdepth 2 \
  -type d \
  | grep 'rhel.9-s390x' \
  | sort
```

The output should include compatible versions of:

```text
Microsoft.NETCore.App.Host.rhel.9-s390x
Microsoft.NETCore.App.Runtime.rhel.9-s390x
Microsoft.AspNetCore.App.Runtime.rhel.9-s390x
```

## Clone the port repository

```bash
cd /root

git clone \
  --branch port/v7.6-s390x \
  https://github.com/ddaddeo/PowerShell-s390x.git \
  PowerShell

cd PowerShell
```

Configure the official repository as `upstream` if it is not already
present:

```bash
git remote add upstream \
  https://github.com/PowerShell/PowerShell.git
```

Disable accidental pushes to the official repository:

```bash
git remote set-url --push upstream DISABLED
```

Verify:

```bash
git remote -v
git branch -vv
git status
```

## Changes required for the s390x port

The port branch contains the following changes compared with the
official PowerShell release.

### .NET SDK selection

The `global.json` file selects the .NET SDK available for the validated
s390x build:

```json
{
  "sdk": {
    "version": "10.0.112",
    "rollForward": "latestPatch"
  }
}
```

Future port branches may require a different SDK version.

### ResGen Runtime Identifier

The following project:

```text
src/ResGen/ResGen.csproj
```

must contain only:

```xml
<RuntimeIdentifiers>rhel.9-s390x</RuntimeIdentifiers>
```

### TypeCatalogGen Runtime Identifier

The following project:

```text
src/TypeCatalogGen/TypeCatalogGen.csproj
```

must contain only:

```xml
<RuntimeIdentifiers>rhel.9-s390x</RuntimeIdentifiers>
```

Do not append `rhel.9-s390x` to the original list:

```text
win-x86;win-x64;osx-x64;linux-x64
```

If `win-x64` remains in the list, MSBuild can attempt to download:

```text
Microsoft.NETCore.App.Host.win-x64
```

This can cause a restore failure or an Azure DevOps `401 Unauthorized`
error.

Verify the generator configuration:

```bash
grep -n RuntimeIdentifiers \
  src/ResGen/ResGen.csproj \
  src/TypeCatalogGen/TypeCatalogGen.csproj
```

Expected result in both files:

```xml
<RuntimeIdentifiers>rhel.9-s390x</RuntimeIdentifiers>
```

### NuGet configuration

The port branch uses the public NuGet feed:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org"
         value="https://api.nuget.org/v3/index.json" />
  </packageSources>
</configuration>
```

The original upstream configuration is preserved as:

```text
nuget.config.upstream
```

## Repository tools

The s390x workflow is located under:

```text
tools/s390x/
```

The available scripts are:

```text
tools/s390x/build.sh
tools/s390x/build-native.sh
tools/s390x/test.sh
tools/s390x/package.sh
```

Make sure the scripts are executable:

```bash
chmod 755 \
  tools/s390x/build.sh \
  tools/s390x/build-native.sh \
  tools/s390x/test.sh \
  tools/s390x/package.sh
```

## Managed PowerShell build

Run:

```bash
cd /root/PowerShell

./tools/s390x/build.sh
```

The build script performs the following operations:

1. Verifies that the machine architecture is `s390x`.
2. Verifies that the .NET RID is `rhel.9-s390x`.
3. Verifies the `RuntimeIdentifiers` in `ResGen`.
4. Verifies the `RuntimeIdentifiers` in `TypeCatalogGen`.
5. Cleans the generator build directories.
6. Clears the relevant NuGet cache.
7. Executes `ResGen`.
8. Generates the strongly typed resource classes.
9. Creates the temporary TypeCatalog MSBuild target.
10. Generates `powershell_rhel.9-s390x.inc`.
11. Generates `CorePsTypeCatalog.cs`.
12. Builds `pwsh.dll`.

Expected final result:

```text
Build succeeded
PASS: managed build completed
```

The default Debug output directory is:

```text
src/powershell-unix/bin/Debug/net10.0
```

The main managed executable is:

```text
src/powershell-unix/bin/Debug/net10.0/pwsh.dll
```

### Manual managed build

The equivalent managed build command is:

```bash
dotnet build src/powershell-unix/powershell-unix.csproj \
  --source https://api.nuget.org/v3/index.json \
  -p:NuGetAudit=false \
  -p:TreatWarningsAsErrors=false \
  -p:UseAppHost=false \
  -v minimal
```

## ResGen

PowerShell requires generated C# classes for its resource files.

Examples include:

```text
ParserStrings.cs
ParameterBinderStrings.cs
FormatAndOutXmlLoadingStrings.cs
CmdletizationCoreResources.cs
InternalHostStrings.cs
RemotingErrorIdStrings.cs
```

These files are generated by:

```bash
cd src/ResGen

dotnet run \
  -p:NuGetAudit=false \
  -p:TreatWarningsAsErrors=false
```

Verify that the generated files exist:

```bash
find src/System.Management.Automation/gen \
  -type f \
  | grep -E \
'ParserStrings.cs|ParameterBinderStrings.cs|FormatAndOutXmlLoadingStrings.cs|CmdletizationCoreResources.cs'
```

If only three files exist under `gen`, the resource generation did not
complete.

## TypeCatalogGen

The build also requires:

```text
src/System.Management.Automation/CoreCLR/CorePsTypeCatalog.cs
```

The generated file must contain:

```text
InitializeTypeCatalog
```

Verify:

```bash
grep -n "InitializeTypeCatalog" \
  src/System.Management.Automation/CoreCLR/CorePsTypeCatalog.cs
```

The generated dependency list is:

```text
src/TypeCatalogGen/powershell_rhel.9-s390x.inc
```

Both files are generated build artifacts and must not be committed.

## Native PowerShell library

PowerShell requires the native library:

```text
libpsl-native.so
```

This library is specific to PowerShell.

It is not the RHEL `libpsl` package used for the Public Suffix List.

The library source is maintained in:

```text
https://github.com/PowerShell/PowerShell-Native
```

## Build the native library

Run:

```bash
cd /root/PowerShell

./tools/s390x/build-native.sh
```

The native build script performs the following operations:

1. Clones or updates the PowerShell-Native repository.
2. Initializes the required Git submodules.
3. Configures `libpsl-native` with CMake.
4. Builds `libpsl-native.so`.
5. Verifies that it is compiled for IBM S/390.
6. Copies it next to `pwsh.dll`.

The default native repository location is:

```text
/root/PowerShell-Native
```

The generated library is produced at:

```text
/root/PowerShell-Native/src/powershell-unix/libpsl-native.so
```

The script copies it to:

```text
src/powershell-unix/bin/Debug/net10.0/libpsl-native.so
```

Verify the native architecture:

```bash
file \
  src/powershell-unix/bin/Debug/net10.0/libpsl-native.so
```

Expected result:

```text
ELF 64-bit MSB shared object, IBM S/390
```

The output must not contain:

```text
x86-64
```

Check native dependencies:

```bash
ldd \
  src/powershell-unix/bin/Debug/net10.0/libpsl-native.so
```

No dependency should be reported as:

```text
not found
```

## Automated test

Run:

```bash
cd /root/PowerShell

./tools/s390x/test.sh
```

The test verifies:

- `pwsh.dll` exists.
- `libpsl-native.so` exists.
- The native library is compiled for IBM S/390.
- The native library has no missing dependencies.
- PowerShell starts successfully.
- `PSEdition` is `Core`.
- The operating system architecture is `S390X`.
- The process architecture is `S390X`.
- The runtime identifier is available.
- `Get-Process` works.
- `Get-ChildItem` works.

Expected final result:

```text
PASS: PowerShell works on s390x
```

## Manual execution

Set the output directory:

```bash
PWSH_DIR="$PWD/src/powershell-unix/bin/Debug/net10.0"
```

Display the PowerShell version:

```bash
LD_LIBRARY_PATH="$PWSH_DIR" \
dotnet "$PWSH_DIR/pwsh.dll" \
  -NoLogo \
  -NoProfile \
  -Command '$PSVersionTable'
```

Display the architecture:

```bash
LD_LIBRARY_PATH="$PWSH_DIR" \
dotnet "$PWSH_DIR/pwsh.dll" \
  -NoLogo \
  -NoProfile \
  -Command '
[System.Runtime.InteropServices.RuntimeInformation\]::OSArchitecture
[System.Runtime.InteropServices.RuntimeInformation\]::ProcessArchitecture
[System.Runtime.InteropServices.RuntimeInformation\]::RuntimeIdentifier
'
```

Start an interactive PowerShell session:

```bash
cd src/powershell-unix/bin/Debug/net10.0

LD_LIBRARY_PATH="$PWD" \
dotnet ./pwsh.dll
```

Inside PowerShell:

```powershell
$PSVersionTable
Get-Process | Select-Object -First 5
Get-ChildItem / | Select-Object -First 5
```

Environment variables inside PowerShell use PowerShell syntax:

```powershell
$env:LD_LIBRARY_PATH = $PWD.Path
```

The Bash syntax below must not be entered inside PowerShell:

```bash
LD_LIBRARY_PATH=$PWD
```

## Package creation

Create an exportable framework-dependent package:

```bash
cd /root/PowerShell

./tools/s390x/package.sh /home/oper1
```

The script:

1. Copies the PowerShell output files.
2. Includes the s390x `libpsl-native.so`.
3. Creates a portable launcher named `pwsh`.
4. Tests the launcher.
5. Creates a compressed archive.
6. Creates a SHA-256 checksum.

Expected output files:

```text
/home/oper1/powershell-7.6.0-linux-s390x.tar.gz
/home/oper1/powershell-7.6.0-linux-s390x.tar.gz.sha256
```

The package is framework-dependent.

The destination server must provide a compatible .NET 10 runtime for
RHEL s390x.

## Run an exported package

Copy the archive to the destination server.

Extract it:

```bash
tar xzf powershell-7.6.0-linux-s390x.tar.gz
cd pwsh-s390x
```

Verify the native library:

```bash
uname -m
file libpsl-native.so
ldd libpsl-native.so
```

Run PowerShell:

```bash
./pwsh
```

Run a single command:

```bash
./pwsh \
  -NoLogo \
  -NoProfile \
  -Command '$PSVersionTable'
```

Run the functional test:

```bash
./pwsh \
  -NoLogo \
  -NoProfile \
  -Command '
$PSVersionTable
[System.Runtime.InteropServices.RuntimeInformation\]::OSArchitecture
Get-Process | Select-Object -First 3
Get-ChildItem / | Select-Object -First 3
'
```

## Generated files

The build creates generated files under directories such as:

```text
bin/
obj/
gen/
```

It also creates:

```text
src/System.Management.Automation/CoreCLR/CorePsTypeCatalog.cs
src/TypeCatalogGen/powershell_rhel.9-s390x.inc
```

These files are build artifacts and must not be committed.

Verify ignored files with:

```bash
git status --short --ignored
```

Ignored files are displayed with:

```text
!!
```

Do not use:

```bash
git add -f
```

for generated build artifacts.

## Troubleshooting

### `Microsoft.NETCore.App.Host.win-x64` download failure

Example:

```text
Failed to download package Microsoft.NETCore.App.Host.win-x64
```

Verify that both generator projects contain only:

```xml
<RuntimeIdentifiers>rhel.9-s390x</RuntimeIdentifiers>
```

Check with:

```bash
grep -n RuntimeIdentifiers \
  src/ResGen/ResGen.csproj \
  src/TypeCatalogGen/TypeCatalogGen.csproj
```

Clean the generator output and NuGet caches:

```bash
rm -rf src/ResGen/bin src/ResGen/obj
rm -rf src/TypeCatalogGen/bin src/TypeCatalogGen/obj
rm -rf ~/.nuget/packages/microsoft.netcore.app.host.win-x64

dotnet nuget locals all --clear
```

### NuGet HTTP 401

Verify that `nuget.config` contains only:

```text
https://api.nuget.org/v3/index.json
```

The original Azure DevOps feed can require authentication when a package
is not available in its local cache.

### Thousands of missing `*Strings` errors

Examples:

```text
ParserStrings does not exist
FormatAndOutXmlLoadingStrings
## Background jobs with `Start-Job`

Out-of-process background jobs created with `Start-Job` are supported on
Linux `s390x`.

### Original issue

Before the correction, `Start-Job` failed while opening the child runspace:

```text
Cannot perform operation because operation
"NewNotImplementedException" is not implemented.
```

The resulting job ended with a remoting transport error:

```text
System.Management.Automation.Remoting.PSRemotingTransportException
```

Diagnostic tests confirmed that the following components were already
working correctly:

- creation of an independent child `pwsh` process;
- execution of `pwsh` in out-of-process server mode;
- PSRP `Close` and `CloseAck` message exchange;
- parallel runspaces using `ForEach-Object -Parallel`;
- native `S390x` architecture detection in the child process.

The problem therefore did not originate from Linux process creation,
pipes, the basic PSRP transport or s390x parallel execution.

### Root cause

The host used by the background PowerShell process did not provide a value
for:

```text
PSHost.Version
```

The `InternalHost.Version` property treated a null external-host version
as an unimplemented operation and threw:

```csharp
PSTraceSource.NewNotImplementedException();
```

This prevented the child runspace from opening.

A second issue occurred while PowerShell tried to log the original
runspace initialization failure. Engine-health logging called:

```csharp
Host.Version.ToString()
```

Because `Host.Version` was null, logging generated a
`NullReferenceException` that masked the original error.

### Correction in `InternalHost.cs`

File:

```text
src/System.Management.Automation/engine/hostifaces/InternalHost.cs
```

When the external host does not provide its version, PowerShell now uses
the version of the running engine:

```csharp
// Some out-of-process hosts do not provide a version.
// Use the running PowerShell version instead of failing
// runspace initialization.
_versionResult =
    _externalHostRef.Value.Version ??
    PSVersionInfo.PSVersion;
```

This replaces the previous behavior that threw
`PSNotImplementedException` when the external host version was null.

### Correction in `LocalConnection.cs`

File:

```text
src/System.Management.Automation/engine/hostifaces/LocalConnection.cs
```

Engine-health logging is now null-safe:

```csharp
logContext.HostVersion =
    Host.Version?.ToString() ?? string.Empty;
```

This replaces:

```csharp
logContext.HostVersion = Host.Version.ToString();
```

Logging can therefore no longer replace the original runspace error with
a secondary `NullReferenceException`.

### Build requirements found during validation

The validated Release build uses:

```text
.NET SDK:     10.0.112
.NET runtime: 10.0.12
Runtime RID:  linux-s390x
```

A self-contained `linux-s390x` publish requires the following packages:

```text
Microsoft.NETCore.App.Runtime.linux-s390x 10.0.12
Microsoft.AspNetCore.App.Runtime.linux-s390x 10.0.12
Microsoft.NETCore.App.Host.linux-s390x 10.0.12
```

These packages are not available from the standard NuGet.org feed. They
must be supplied through the IBM `dotnet-s390x` releases or through a
local NuGet source.

The package versions must match the runtime version exactly:

```text
10.0.12
```

Do not use the SDK version `10.0.112` as the runtime-pack version.

### ReadyToRun

ReadyToRun optimization must currently be disabled for the
`linux-s390x` publish.

Otherwise, the publish step can fail with:

```text
NETSDK1094: Unable to optimize assemblies for performance:
a valid runtime package was not found.
```

The build configuration must include:

```xml
<PublishReadyToRun>false</PublishReadyToRun>
<PublishReadyToRunComposite>false</PublishReadyToRunComposite>
```

Disabling ReadyToRun does not prevent PowerShell from running. The .NET
JIT compiler generates native s390x code at runtime.

### Clean Release build

After changing the source files, run a clean build:

```bash
cd /root/PowerShell-s390x-src

pwsh -NoProfile -Command '
Remove-Module build -Force -ErrorAction SilentlyContinue
Import-Module ./build.psm1 -Force
Start-PSBuild -Configuration Release -Runtime linux-s390x -Clean
'
```

The clean build must execute:

```text
Run ResGen (generating C# bindings for resx files)
Run TypeGen (generating CorePsTypeCatalog.cs)
```

Expected successful output includes:

```text
System.Management.Automation net10.0 succeeded
Microsoft.PowerShell.ConsoleHost net10.0 succeeded
Microsoft.PowerShell.Commands.Utility net10.0 succeeded
Microsoft.PowerShell.Security net10.0 succeeded
Microsoft.PowerShell.Commands.Management net10.0 succeeded
Microsoft.PowerShell.SDK net10.0 succeeded
powershell-unix net10.0 linux-s390x succeeded
Build succeeded
```

The Release publish directory is:

```text
src/powershell-unix/bin/Release/net10.0/linux-s390x/publish
```

Do not manually delete:

```text
src/System.Management.Automation/gen
```

unless the next build uses `Start-PSBuild -Clean`.

The directory contains generated resource bindings. Deleting it without
regenerating the files can produce thousands of missing-symbol errors,
including:

```text
SessionStateStrings does not exist
ParserStrings does not exist
Authenticode does not exist
FileSystemProviderStrings does not exist
```

### Native library in the Release output

Compile `libpsl-native.so` using the existing procedure documented in the
**Build the native library** section:

```bash
./tools/s390x/build-native.sh
```

The resulting IBM S/390 library must also be present in the Release
publish directory:

```text
src/powershell-unix/bin/Release/net10.0/linux-s390x/publish/libpsl-native.so
```

Verify it with:

```bash
RELEASE_OUT="$PWD/src/powershell-unix/bin/Release/net10.0/linux-s390x/publish"

file "$RELEASE_OUT/libpsl-native.so"
ldd "$RELEASE_OUT/libpsl-native.so"
```

Expected architecture:

```text
ELF 64-bit MSB shared object, IBM S/390
```

No dependency may be reported as:

```text
not found
```

Without this native library, PowerShell fails during startup with:

```text
System.DllNotFoundException: libpsl-native
```

### Validate `Start-Job`

Set the Release output directory:

```bash
RELEASE_OUT="$PWD/src/powershell-unix/bin/Release/net10.0/linux-s390x/publish"
```

Run the validation:

```bash
LD_LIBRARY_PATH="$RELEASE_OUT" \
"$RELEASE_OUT/pwsh" \
    -NoLogo \
    -NoProfile \
    -Command '
$ErrorActionPreference = "Stop"

try {
    $job = Start-Job {
        [pscustomobject]@{
            Message      = "CHILD_OK"
            Version      = $PSVersionTable.PSVersion.ToString()
            PID          = $PID
            Architecture = [System.Runtime.InteropServices.RuntimeInformation\]::ProcessArchitecture
        }
    }

    $job | Wait-Job | Out-Null

    $result = $job | Receive-Job -ErrorAction Stop
    $result | Format-List

    if ($result.Message -ne "CHILD_OK") {
        throw "Unexpected child-process result"
    }

    $job | Remove-Job -Force

    Write-Host "START-JOB: PASS" -ForegroundColor Green
}
catch {
    Write-Host "START-JOB: FAIL" -ForegroundColor Red
    Write-Host ($_.Exception.ToString())
    exit 1
}
'
```

Validated output:

```text
Message      : CHILD_OK
Version      : 7.6.0-s390x.3
Architecture : S390x
START-JOB: PASS
```

The PID and Runspace ID are generated dynamically and will be different
for each execution.

The successful test validates:

- child PowerShell process creation;
- out-of-process PSRP communication;
- child runspace initialization;
- execution of the background script block;
- serialization of job results;
- background-job cleanup;
- native s390x execution.

### Validate parallel runspaces

Parallel runspaces can be tested separately:

```bash
LD_LIBRARY_PATH="$RELEASE_OUT" \
"$RELEASE_OUT/pwsh" \
    -NoLogo \
    -NoProfile \
    -Command '
$ErrorActionPreference = "Stop"

$results = 1..20 | ForEach-Object -Parallel {
    [pscustomobject]@{
        Input        = $_
        Square       = $_ * $_
        PID          = $PID
        Architecture = [System.Runtime.InteropServices.RuntimeInformation\]::ProcessArchitecture
    }
} -ThrottleLimit 4

$results | Format-Table Input, Square, PID, Architecture

if ($results.Count -ne 20) {
    throw "Expected 20 results, received $($results.Count)"
}

Write-Host "PARALLEL RUNSPACES: PASS" -ForegroundColor Green
'
```

Parallel results can be returned in a different order. Every result must
report:

```text
Architecture = S390x
```

### Validation status

```text
PowerShell engine                         PASS
Native s390x process                      PASS
Pipeline operations                       PASS
.NET integration                          PASS
JSON and XML serialization                PASS
Filesystem operations                     PASS
Process enumeration                       PASS
UTF-8 handling                            PASS
Child PowerShell process creation         PASS
Parallel runspaces                        PASS
Out-of-process PSRP transport             PASS
Start-Job                                 PASS
Background-job result serialization       PASS
Background-job cleanup                    PASS
