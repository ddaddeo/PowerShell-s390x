$ErrorActionPreference = "Stop"
$failures = [System.Collections.Generic.List[string]]::new()

function Invoke-Test {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    Write-Host "`n=== $Name ===" -ForegroundColor Cyan

    try {
        & $Test
        Write-Host "PASS: $Name" -ForegroundColor Green
    }
    catch {
        $failures.Add($Name)
        Write-Host "FAIL: $Name" -ForegroundColor Red
        Write-Host $_.Exception.ToString()
    }
}

Write-Host "=== PowerShell s390x Extended Validation ===" -ForegroundColor Green

Invoke-Test "Version information" {
    $PSVersionTable | Format-Table

    if ($PSVersionTable.PSEdition -ne "Core") {
        throw "PSEdition is not Core"
    }
}

Invoke-Test "Architecture" {
    $osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    $processArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
    $rid = [System.Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier

    Write-Host "OS architecture:      $osArch"
    Write-Host "Process architecture: $processArch"
    Write-Host "Runtime identifier:   $rid"

    if ($osArch -ne "S390x") {
        throw "Unexpected OS architecture: $osArch"
    }

    if ($processArch -ne "S390x") {
        throw "Unexpected process architecture: $processArch"
    }
}

Invoke-Test "Basic mathematics" {
    $sum = (1..1000 | Measure-Object -Sum).Sum
    Write-Host "Sum 1..1000: $sum"

    if ($sum -ne 500500) {
        throw "Unexpected sum: $sum"
    }
}

Invoke-Test "Pipeline" {
    $result = 1..5 | ForEach-Object { $_ * $_ }
    $expected = 1, 4, 9, 16, 25

    $result | ForEach-Object { Write-Host $_ }

    if (Compare-Object $result $expected) {
        throw "Pipeline returned unexpected results"
    }
}

Invoke-Test "Generic collections" {
    $list = [System.Collections.Generic.List[int]]::new()

    1..10 | ForEach-Object {
        $list.Add($_)
    }

    Write-Host "List count: $($list.Count)"

    if ($list.Count -ne 10) {
        throw "Unexpected list count"
    }
}

Invoke-Test "Hashtable and objects" {
    $object = [pscustomobject]@{
        Name = "PowerShell"
        Arch = "s390x"
        Test = $true
    }

    $object | Format-List

    if ($object.Arch -ne "s390x") {
        throw "Object property validation failed"
    }
}

Invoke-Test "JSON serialization" {
    $object = @{
        Name = "PowerShell"
        Arch = "s390x"
        Test = $true
    }

    $json = $object | ConvertTo-Json
    $parsed = $json | ConvertFrom-Json

    Write-Host $json

    if ($parsed.Arch -ne "s390x") {
        throw "JSON round trip failed"
    }
}

Invoke-Test "XML parsing" {
    [xml]$xml = "<root><node>test</node></root>"
    Write-Host "XML value: $($xml.root.node)"

    if ($xml.root.node -ne "test") {
        throw "XML parsing failed"
    }
}

Invoke-Test "Regular expressions" {
    $matched = "PowerShell-s390x" -match "s390x"
    Write-Host "Regex match: $matched"

    if (-not $matched) {
        throw "Regex match failed"
    }
}

Invoke-Test "Date and time" {
    $now = Get-Date
    $tomorrow = $now.AddDays(1)

    Write-Host "Current date: $now"
    Write-Host "Tomorrow:     $tomorrow"

    if ($tomorrow -le $now) {
        throw "Date calculation failed"
    }
}

Invoke-Test "Exception handling" {
    $caught = $false

    try {
        $null = 1 / 0
    }
    catch {
        $caught = $true
        Write-Host "Exception correctly caught"
    }

    if (-not $caught) {
        throw "Exception was not caught"
    }
}

Invoke-Test "Filesystem operations" {
    $tempRoot = if ([string]::IsNullOrWhiteSpace($env:TMPDIR)) { "/tmp" } else { $env:TMPDIR }
    $directory = Join-Path $tempRoot "pwsh-s390x-test-$PID"

    $file = Join-Path $directory "test.txt"

    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    "hello world" | Set-Content $file -Encoding utf8

    $content = Get-Content $file -Raw
    Write-Host $content.Trim()

    if ($content.Trim() -ne "hello world") {
        throw "File content validation failed"
    }

    Remove-Item $directory -Recurse -Force
}

Invoke-Test "UTF-8 encoding" {
    $file = "/tmp/pwsh-s390x-utf8-$PID.txt"
    $expected = "àèìòù 日本語 Ελληνικά"

    $expected | Set-Content $file -Encoding utf8
    $actual = Get-Content $file -Raw

    Write-Host $actual.Trim()

    if ($actual.Trim() -ne $expected) {
        throw "UTF-8 round trip failed"
    }

    Remove-Item $file -Force
}

Invoke-Test "Environment provider" {
    $environment = Get-ChildItem Env:

    $environment |
        Select-Object -First 5 |
        Format-Table Name, Value

    if ($environment.Count -eq 0) {
        throw "No environment variables found"
    }
}

Invoke-Test "Process provider" {
    $processes = Get-Process

    $processes |
        Select-Object -First 5 Id, Name, CPU |
        Format-Table

    if ($processes.Count -eq 0) {
        throw "No processes found"
    }
}

Invoke-Test "Module discovery" {
    $modules = Get-Module -ListAvailable

    $modules |
        Select-Object -First 10 Name, Version |
        Format-Table

    if ($modules.Count -eq 0) {
        throw "No modules found"
    }
}

Invoke-Test "Parallel runspaces" {
    $results = 1..20 | ForEach-Object -Parallel {
        [pscustomobject]@{
            Input = $_
            Square = $_ * $_
            PID = $PID
            Architecture = "$([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture)"
        }
    } -ThrottleLimit 4

    $results |
        Sort-Object Input |
        Format-Table Input, Square, PID, Architecture

    if ($results.Count -ne 20) {
        throw "Expected 20 results, received $($results.Count)"
    }

    if ($results.Where({ $_.Architecture -ne "S390x" }).Count -ne 0) {
        throw "A parallel runspace used an unexpected architecture"
    }

    foreach ($result in $results) {
        if ($result.Square -ne ($result.Input * $result.Input)) {
            throw "Incorrect parallel result for $($result.Input)"
        }
    }
}

Invoke-Test "Background job with Start-Job" {
    $job = Start-Job {
        [pscustomobject]@{
            Message = "CHILD_OK"
            Version = $PSVersionTable.PSVersion.ToString()
            PID = $PID
            Architecture = "$([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture)"
        }
    }

    try {
        $job | Wait-Job | Out-Null
        $result = $job | Receive-Job -ErrorAction Stop

        $result | Format-List

        if ($job.State -ne "Completed") {
            throw "Unexpected job state: $($job.State)"
        }

        if ($result.Message -ne "CHILD_OK") {
            throw "Unexpected message from child process"
        }

        if ($result.Architecture -ne "S390x") {
            throw "Unexpected child architecture: $($result.Architecture)"
        }

        if ($result.PID -eq $PID) {
            throw "Start-Job didte process"
        }
    }
    finally {
        $job | Remove-Job -Force -ErrorAction SilentlyContinue
    }
}

Invoke-Test "Child PowerShell process" {
    $pwsh = (Get-Command pwsh -ErrorAction Stop).Source
    Write-Host "pwsh executable: $pwsh"

    $output = & $pwsh -NoLogo -NoProfile -Command @'
[pscustomobject]@{
    Message = "PROCESS_OK"
    PID = $PID
    Architecture = "$([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture)"
} | ConvertTo-Json -Compress
'@

    $result = $output | ConvertFrom-Json
    $result | Format-List

    if ($result.Message -ne "PROCESS_OK") {
        throw "Child process test failed"
    }

    if ($result.Architecture -ne "S390x") {
        throw "Unexpected child-process architecture"
    }
}

Invoke-Test "Garbage collector" {
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    $memory = [System.GC]::GetTotalMemory($true)
    Write-Host "Managed memory: $memory bytes"

    if ($memory -le 0) {
        throw "Invalid managed-memory value"
    }
}

Write-Host "`n=== FINAL RESULT ===" -ForegroundColor Cyan

if ($failures.Count -eq 0) {
    Write-Host "ALL TESTS PASSED" -ForegroundColor Green
    exit 0
}

Write-Host "$($failures.Count) TESTS FAILED:" -ForegroundColor Red

$failures | ForEach-Object {
    Write-Host " - $_" -ForegroundColor Red
}

exit 1
