#Requires -Version 7.0

<#
.SYNOPSIS
Synchronizes Erlang/OTP versions to Chocolatey by detecting and publishing missing versions.

.DESCRIPTION
Parses the official OTP versions table from GitHub, compares with published versions
on chocolatey.org, and builds/publishes any missing versions. Processes versions
sequentially to ensure thorough testing of each release.

.PARAMETER DryRun
Show what would be done without actually building or pushing packages.

.PARAMETER MinMajorVersion
Minimum OTP major version to process (default: 25). Only processes versions >= this value.

.PARAMETER SpecificVersion
Process only this specific version (e.g., "27.3.4"). Overrides MinMajorVersion.

.PARAMETER ApiKey
Chocolatey API key for publishing. Required unless using -DryRun.

.EXAMPLE
.\sync-versions.ps1 -DryRun
Shows which versions are missing without building anything

.EXAMPLE
.\sync-versions.ps1 -ApiKey "your-api-key"
Builds and publishes all missing versions >= 25.0

.EXAMPLE
.\sync-versions.ps1 -MinMajorVersion 26 -ApiKey "your-api-key"
Builds and publishes all missing versions >= 26.0

.EXAMPLE
.\sync-versions.ps1 -SpecificVersion "27.3.4" -ApiKey "your-api-key"
Builds and publishes only version 27.3.4 if missing
#>

param(
    [switch]$DryRun = $false,
    [ValidateRange(1, 99)]
    [int]$MinMajorVersion = 25,
    [string]$SpecificVersion,
    [ValidateRange(1, 99)]
    [int]$MaxMajorVersion = 99,
    [string]$ApiKey = $null,
    [ValidateRange(1, 100)]
    [int]$MaxPushes = 10
)

$InformationPreference = 'Continue'
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

# Validate parameters
if ($MaxMajorVersion -lt $MinMajorVersion)
{
    Write-Error "MaxMajorVersion ($MaxMajorVersion) cannot be less than MinMajorVersion ($MinMajorVersion)"
    exit 1
}

if ($SpecificVersion)
{
    $specificMajor = [int]($SpecificVersion -split '\.')[0]
    if ($specificMajor -lt $MinMajorVersion -or $specificMajor -gt $MaxMajorVersion)
    {
        Write-Error "SpecificVersion ($SpecificVersion) has major version $specificMajor which is outside the range $MinMajorVersion-$MaxMajorVersion"
        exit 1
    }
}

if (-not $DryRun -and -not $ApiKey)
{
    Write-Error "ApiKey is required unless using -DryRun"
    exit 1
}

Write-Information "=== Erlang/OTP Version Sync ==="
$versionRangeMsg = if ($MaxMajorVersion -eq 99) { ">= $MinMajorVersion" } else { "$MinMajorVersion-$MaxMajorVersion" }
Write-Information "Version Range: $versionRangeMsg"
Write-Information "Max Pushes Per Run: $MaxPushes"
if ($SpecificVersion)
{
    Write-Information "Specific Version: $SpecificVersion"
}
Write-Information "Dry Run: $DryRun"
Write-Information ""

# State file to track pushed versions
$stateFile = Join-Path $PSScriptRoot 'sync-state.json'
$pushedVersions = @()
if (Test-Path $stateFile)
{
    $state = Get-Content $stateFile | ConvertFrom-Json
    $pushedVersions = @($state.pushedVersions)
    Write-Information "Loaded state: $($pushedVersions.Count) versions previously pushed"
}

# Fetch otp_versions.table
Write-Information "Fetching otp_versions.table from GitHub..."
$otpVersionsUrl = 'https://raw.githubusercontent.com/erlang/otp/refs/heads/master/otp_versions.table'
$otpVersionsContent = Invoke-WebRequest -Uri $otpVersionsUrl -UseBasicParsing | Select-Object -ExpandProperty Content

# Parse OTP versions
Write-Information "Parsing OTP versions..."
$otpVersions = @()
foreach ($line in $otpVersionsContent -split "`n")
{
    if ($line -match '^OTP-(\d+)\.(\d+)(?:\.(\d+))?(?:\.(\d+))?')
    {
        $major = [int]$matches[1]
        $version = $matches[1]
        if ($matches[3]) { $version += ".$($matches[2]).$($matches[3])" }
        elseif ($matches[2]) { $version += ".$($matches[2])" }
        if ($matches[4]) { $version += ".$($matches[4])" }

        if ($major -ge $MinMajorVersion -and $major -le $MaxMajorVersion)
        {
            if (-not $SpecificVersion -or $version -eq $SpecificVersion)
            {
                $otpVersions += $version
            }
        }
    }
}

Write-Information "Found $($otpVersions.Count) OTP versions in range $versionRangeMsg"

# Query Chocolatey for published versions
Write-Information "Querying chocolatey.org for published versions..."
$chocoOutput = & choco.exe search erlang --exact --all-versions --limit-output
$publishedVersions = @()
foreach ($line in $chocoOutput)
{
    if ($line -match '^erlang\|(.+)$')
    {
        $publishedVersions += $matches[1]
    }
}

Write-Information "Found $($publishedVersions.Count) published versions on chocolatey.org"

# Find missing versions - normalize OTP versions to match Chocolatey format
# Chocolatey normalizes versions to Major.Minor.Build.Revision format:
# - 28.3 becomes 28.3.0
# - 27.3.4 stays 27.3.4
# - 25.1.2.1 stays 25.1.2.1
$normalizedOtpVersions = $otpVersions | ForEach-Object {
    $v = [version]$_

    # Build normalized version string based on which parts are present
    if ($v.Revision -ne -1)
    {
        # 4 parts: Major.Minor.Build.Revision
        "$($v.Major).$($v.Minor).$($v.Build).$($v.Revision)"
    }
    elseif ($v.Build -ne -1)
    {
        # 3 parts: Major.Minor.Build
        "$($v.Major).$($v.Minor).$($v.Build)"
    }
    else
    {
        # 2 parts: Major.Minor - Chocolatey adds .0
        "$($v.Major).$($v.Minor).0"
    }
}

$missingVersions = @()
for ($i = 0; $i -lt $otpVersions.Count; $i++)
{
    $otpVersion = $otpVersions[$i]
    $normalizedVersion = $normalizedOtpVersions[$i]

    # Skip if already pushed in a previous run
    if ($otpVersion -in $pushedVersions)
    {
        continue
    }

    if ($normalizedVersion -notin $publishedVersions)
    {
        $missingVersions += $otpVersion  # Keep original OTP version for processing
    }
}

Write-Information ""
Write-Information "=== Gap Analysis ==="
Write-Information "Missing versions: $($missingVersions.Count)"

if ($missingVersions.Count -eq 0)
{
    Write-Information "All versions are published! Nothing to do."
    exit 0
}

Write-Information ""
Write-Information "Missing versions:"
foreach ($version in $missingVersions)
{
    Write-Information "  - $version"
}

if ($DryRun)
{
    Write-Information ""
    Write-Information "DRY RUN - No packages will be built or pushed"
    exit 0
}

# Process missing versions
Write-Information ""
Write-Information "=== Processing Missing Versions ==="
Write-Information "Will process up to $MaxPushes versions in this run"

$processedCount = 0
$newlyPushed = @()

foreach ($version in $missingVersions)
{
    if ($processedCount -ge $MaxPushes)
    {
        Write-Information ""
        Write-Information "Reached maximum of $MaxPushes pushes for this run"
        Write-Information "Remaining versions: $($missingVersions.Count - $processedCount)"
        break
    }

    Write-Information ""
    Write-Information "[$($processedCount + 1)/$MaxPushes] Processing version $version..."

    Write-Information "  Building and pushing version $version..."
    & "$PSScriptRoot\package.ps1" -Version $version -Push -SkipTest -ApiKey $ApiKey

    $processedCount++
    $newlyPushed += $version
    Write-Information "  SUCCESS: Version $version completed successfully"
}

# Update state file with newly pushed versions
if ($newlyPushed.Count -gt 0)
{
    $allPushed = @($pushedVersions) + @($newlyPushed)
    $state = @{
        pushedVersions = $allPushed
        lastRun = (Get-Date).ToString('o')
    }
    $state | ConvertTo-Json | Set-Content $stateFile
    Write-Information ""
    Write-Information "State saved: $($allPushed.Count) total versions pushed"
}

Write-Information ""
Write-Information "=== Summary ==="
Write-Information "Processed $processedCount versions in this run"
if ($processedCount -lt $missingVersions.Count)
{
    Write-Information "Remaining: $($missingVersions.Count - $processedCount) versions"
    Write-Information "Run again to continue processing"
}
else
{
    Write-Information "All missing versions processed!"
}
exit 0
