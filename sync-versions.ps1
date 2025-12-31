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
    [string]$ApiKey = $null
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
if ($SpecificVersion)
{
    Write-Information "Specific Version: $SpecificVersion"
}
Write-Information "Dry Run: $DryRun"
Write-Information ""

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

# Find missing versions
$missingVersions = @($otpVersions | Where-Object { $_ -notin $publishedVersions })

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

$processedCount = 0

foreach ($version in $missingVersions)
{
    Write-Information ""
    Write-Information "[$($processedCount + 1)/$($missingVersions.Count)] Processing version $version..."

    Write-Information "  Building and pushing version $version..."
    & "$PSScriptRoot\package.ps1" -Version $version -Push -SkipTest -ApiKey $ApiKey

    $processedCount++
    Write-Information "  SUCCESS: Version $version completed successfully"
}

Write-Information ""
Write-Information "=== Summary ==="
Write-Information "All $processedCount versions processed successfully!"
exit 0
