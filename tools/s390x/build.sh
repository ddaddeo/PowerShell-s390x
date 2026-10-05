#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RID="${RID:-rhel.9-s390x}"
CONFIGURATION="${CONFIGURATION:-Debug}"
PWSH_PROJECT="$REPO_ROOT/src/powershell-unix/powershell-unix.csproj"

fatal() { echo "ERROR: $*" >&2; exit 1; }

[[ "$(uname -m)" == "s390x" ]] || fatal "This build must run on s390x"
command -v dotnet >/dev/null || fatal "dotnet is not installed"

actual_rid="$(dotnet --info | awk '/^[[:space:]]*RID:/{print $2; exit}')"
[[ "$actual_rid" == "$RID" ]] || fatal "Expected RID $RID, found ${actual_rid:-unknown}"

cd "$REPO_ROOT"

grep -q "<RuntimeIdentifiers>${RID}</RuntimeIdentifiers>" src/ResGen/ResGen.csproj \
  || fatal "ResGen RuntimeIdentifiers must contain only $RID"
grep -q "<RuntimeIdentifiers>${RID}</RuntimeIdentifiers>" src/TypeCatalogGen/TypeCatalogGen.csproj \
  || fatal "TypeCatalogGen RuntimeIdentifiers must contain only $RID"

printf 'SDK: '; dotnet --version
printf 'RID: %s\n' "$actual_rid"
printf 'Configuration: %s\n' "$CONFIGURATION"

rm -rf src/ResGen/bin src/ResGen/obj
rm -rf src/TypeCatalogGen/bin src/TypeCatalogGen/obj
rm -rf "$HOME/.nuget/packages/microsoft.netcore.app.host.win-x64"
dotnet nuget locals all --clear

echo '== ResGen =='
(
  cd src/ResGen
  dotnet run -p:NuGetAudit=false -p:TreatWarningsAsErrors=false
)

test -f src/System.Management.Automation/gen/ParserStrings.cs \
  || fatal "ResGen did not generate ParserStrings.cs"
test -f src/System.Management.Automation/gen/FormatAndOutXmlLoadingStrings.cs \
  || fatal "ResGen did not generate FormatAndOutXmlLoadingStrings.cs"

echo '== TypeCatalog dependency target =='
mkdir -p src/Microsoft.PowerShell.SDK/obj
cat > src/Microsoft.PowerShell.SDK/obj/Microsoft.PowerShell.SDK.csproj.TypeCatalog.targets <<'TARGETS'
<Project>
  <Target Name="_GetDependencies"
          DependsOnTargets="ResolveAssemblyReferencesDesignTime">
    <ItemGroup>
      <_RefAssemblyPath
        Include="%(_ReferencesFromRAR.OriginalItemSpec)%3B"
        Condition=" '%(_ReferencesFromRAR.NuGetPackageId)' != 'Microsoft.Management.Infrastructure' " />
    </ItemGroup>
    <WriteLinesToFile
      File="$(_DependencyFile)"
      Lines="@(_RefAssemblyPath)"
      Overwrite="true" />
  </Target>
</Project>
TARGETS

inc_file="powershell_${RID}.inc"
(
  cd src/Microsoft.PowerShell.SDK
  dotnet msbuild Microsoft.PowerShell.SDK.csproj \
    /t:_GetDependencies \
    "/property:DesignTimeBuild=true;_DependencyFile=../TypeCatalogGen/${inc_file}" \
    /property:NuGetAudit=false \
    /property:TreatWarningsAsErrors=false \
    /nologo
)

test -s "src/TypeCatalogGen/$inc_file" || fatal "Dependency file was not generated"

echo '== TypeCatalogGen =='
(
  cd src/TypeCatalogGen
  dotnet run \
    -p:NuGetAudit=false \
    -p:TreatWarningsAsErrors=false \
    -- \
    ../System.Management.Automation/CoreCLR/CorePsTypeCatalog.cs \
    "$inc_file"
)

grep -q InitializeTypeCatalog src/System.Management.Automation/CoreCLR/CorePsTypeCatalog.cs \
  || fatal "CorePsTypeCatalog.cs is invalid"

echo '== PowerShell managed build =='
dotnet build "$PWSH_PROJECT" \
  --source https://api.nuget.org/v3/index.json \
  -c "$CONFIGURATION" \
  -p:NuGetAudit=false \
  -p:TreatWarningsAsErrors=false \
  -p:UseAppHost=false \
  -v minimal

out="$REPO_ROOT/src/powershell-unix/bin/$CONFIGURATION/net10.0"
test -f "$out/pwsh.dll" || fatal "pwsh.dll was not produced"

echo "PASS: managed build completed"
echo "Output: $out"
