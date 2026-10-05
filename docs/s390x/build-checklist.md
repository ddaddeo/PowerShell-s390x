# Build checklist for PowerShell on Linux s390x

## Scope

This document describes the repeatable workflow validated for PowerShell 7.6.0 on RHEL 9 s390x. The repository is intentionally version-neutral: future PowerShell versions should use new `port/vX.Y-s390x` branches and retain the same script layout.

## Required repository changes

The port branch must contain these committed changes:

1. `global.json` selects the .NET SDK available on s390x.
2. `src/ResGen/ResGen.csproj` uses only:

   ```xml
   <RuntimeIdentifiers>rhel.9-s390x</RuntimeIdentifiers>
   ```

3. `src/TypeCatalogGen/TypeCatalogGen.csproj` uses only:

   ```xml
   <RuntimeIdentifiers>rhel.9-s390x</RuntimeIdentifiers>
   ```

4. `nuget.config` uses the public NuGet feed.

Do not append `rhel.9-s390x` to the original Windows/macOS/x64 list. If `win-x64` remains, restore can request `Microsoft.NETCore.App.Host.win-x64`.

## Prerequisites

Run as root or add `sudo`:

```bash
dnf groupinstall -y "Development Tools"
dnf install -y \
  git cmake gcc gcc-c++ make tar gzip \
  openssl-devel libicu-devel zlib-devel \
  dotnet-sdk-10.0
```

Validate:

```bash
uname -m
dotnet --info
```

Expected architecture and RID:

```text
s390x
rhel.9-s390x
```

## Repository validation

```bash
git branch --show-current
git status --short
cat global.json
grep -n RuntimeIdentifiers \
  src/ResGen/ResGen.csproj \
  src/TypeCatalogGen/TypeCatalogGen.csproj
cat nuget.config
```

## Managed build

```bash
./tools/s390x/build.sh
```

The script performs:

1. platform, RID and SDK validation;
2. NuGet/build cache cleanup for the generators;
3. ResGen execution;
4. generation of `powershell_rhel.9-s390x.inc`;
5. generation of `CorePsTypeCatalog.cs`;
6. build of `src/powershell-unix/powershell-unix.csproj`.

Expected final result:

```text
Build succeeded
```

## Native build

PowerShell requires `libpsl-native.so`. The similarly named RHEL `libpsl` package is unrelated.

```bash
./tools/s390x/build-native.sh
```

Expected file identification:

```text
ELF 64-bit MSB shared object, IBM S/390
```

## Functional test

```bash
./tools/s390x/test.sh
```

Expected final line:

```text
PASS: PowerShell works on s390x
```

## Package creation

```bash
./tools/s390x/package.sh /home/oper1
```

The command creates a framework-dependent archive named like:

```text
powershell-7.6.0-rhel9-s390x.tar.gz
```

The destination server needs a compatible .NET 10 runtime.

## Running an extracted package

```bash
tar xzf powershell-7.6.0-rhel9-s390x.tar.gz
cd pwsh-s390x
./pwsh -NoLogo -NoProfile -Command '$PSVersionTable'
```

## Troubleshooting

### `Microsoft.NETCore.App.Host.win-x64` or HTTP 401

Verify that both generator projects contain only `rhel.9-s390x` and that `nuget.config` contains only `nuget.org`.

### Thousands of missing `*Strings` symbols

ResGen did not complete. Run `tools/s390x/build.sh` again and verify that `src/System.Management.Automation/gen/ParserStrings.cs` exists.

### `InitializeTypeCatalog` does not exist

`CorePsTypeCatalog.cs` was not generated. The managed build script recreates the temporary target, dependency list and catalog.

### `DllNotFoundException: libpsl-native`

Run `tools/s390x/build-native.sh`. Verify that the copied library is IBM S/390 and start PowerShell through the supplied launcher or with `LD_LIBRARY_PATH` set to the output directory.
