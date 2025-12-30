#Requires -Version 7.0

<#
.SYNOPSIS
Builds and optionally publishes Erlang/OTP Chocolatey package.

.DESCRIPTION
Downloads Erlang/OTP installers for a specific version, tests the installation,
generates package files from templates, and optionally tests and publishes to
chocolatey.org.

.PARAMETER PackAndTest
Build and test the package locally without pushing.

.PARAMETER Push
Test the package installation locally and push to chocolatey.org.

.PARAMETER SkipTest
Skip installation testing. Packages are built and pushed without local testing.
Useful for batch processing where Erlang installers are known to be reliable.

.EXAMPLE
.\package.ps1 -Version "28.1.1"
Downloads installers for version 28.1.1 and generates package files

.EXAMPLE
.\package.ps1 -Version "27.3.4" -PackAndTest -Verbose
Builds and tests package for version 27.3.4 with verbose choco output

.EXAMPLE
.\package.ps1 -Version "26.2.5" -Push -ApiKey "your-api-key" -SkipTest
Builds and publishes version 26.2.5 without testing
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [switch]$PackAndTest = $false,
    [switch]$Push = $false,
    [string]$ApiKey = $null,
    [switch]$SkipTest = $false
)

$InformationPreference = 'Continue'

if ($Push)
{
    $PackAndTest = $true
    Write-Information "[INFO] PACKAGE WILL BE TESTED AND PUSHED"
}

$DebugPreference = "Continue"
$ErrorActionPreference = 'Stop'
# Set-PSDebug -Strict -Trace 1
Set-PSDebug -Off
Set-StrictMode -Version 'Latest' -ErrorAction 'Stop' -Verbose

function Join-PathMultiple
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Base,
        [Parameter(Mandatory = $true)]
        [string[]]$Parts
    )
    $result = $Base
    foreach ($part in $Parts)
    {
        $result = Join-Path -Path $result -ChildPath $part
    }
    return $result
}

function Invoke-CommandWithCheck
{
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )
    & $Command
    if ($LASTEXITCODE -eq 0)
    {
        Write-Information "[INFO] '$Description' succeeded."
    }
    else
    {
        throw "[ERROR] '$Description' failed!"
    }
}


New-Variable -Name curdir  -Option Constant -Value $PSScriptRoot
Write-Information "[INFO] curdir: $curdir"

# Set choco arguments based on preference variables
if ($DebugPreference -eq 'Continue')
{
    New-Variable -Name arg_debug  -Option Constant -Value '--debug'
}
else
{
    New-Variable -Name arg_debug  -Option Constant -Value ''
}

if ($VerbosePreference -eq 'Continue')
{
    New-Variable -Name arg_verbose  -Option Constant -Value '--verbose'
}
else
{
    New-Variable -Name arg_verbose  -Option Constant -Value ''
}

New-Variable -Name otp_version -Option Constant -Value $Version
Write-Information "[INFO] Building version: $otp_version"

# Fetch release information from GitHub
New-Variable -Name erlang_release_uri -Option Constant `
    -Value "https://api.github.com/repos/erlang/otp/releases/tags/OTP-$otp_version"

Write-Information "[INFO] Fetching release information from GitHub..."
try
{
    $ProgressPreference = 'SilentlyContinue'
    New-Variable -Name erlang_json -Option Constant `
        -Value (Invoke-WebRequest -Uri $erlang_release_uri | ConvertFrom-Json)
}
catch
{
    Write-Error "Version OTP-$otp_version not found on GitHub. Please verify the version exists."
    exit 1
}
finally
{
    $ProgressPreference = 'Continue'
}

New-Variable -Name win32_installer_asset  -Option Constant `
    -Value ($erlang_json.assets | Where-Object { $_.name -match '^otp_win32_[0-9.]+\.exe$' })
New-Variable -Name win64_installer_asset  -Option Constant `
    -Value ($erlang_json.assets | Where-Object { $_.name -match '^otp_win64_[0-9.]+\.exe$' })

New-Variable -Name win32_installer_exe -Option Constant -Value $win32_installer_asset.name
New-Variable -Name win64_installer_exe -Option Constant -Value $win64_installer_asset.name

$files = @()
$jobs = @()

if (!(Test-Path -Path $win32_installer_exe))
{
    Write-Information "[INFO] downloading from $($win32_installer_asset.browser_download_url)"
    $files += @{
        Uri = $win32_installer_asset.browser_download_url
        OutFile = $win32_installer_exe
    }
}
if (!(Test-Path -Path $win64_installer_exe))
{
    Write-Information "[INFO] downloading from $($win64_installer_asset.browser_download_url)"
    $files += @{
        Uri = $win64_installer_asset.browser_download_url
        OutFile = $win64_installer_exe
    }
}

try
{
    $ProgressPreference = 'SilentlyContinue'
    foreach ($file in $files)
    {
        $jobs += Start-ThreadJob -Name $file.OutFile -ScriptBlock {
            $params = $using:file
            Invoke-WebRequest @params
        }
    }

    if ($jobs.Count -gt 0)
    {
        Write-Information "[INFO] Downloads started..."
        Wait-Job -Job $jobs
        foreach ($job in $jobs)
        {
            Receive-Job -Job $job
        }
        Write-Information "[INFO] Downloads complete!"
    }
    else
    {
        Write-Information "[INFO] nothing to download!"
    }
}
finally
{
    $ProgressPreference = 'Continue'
}

New-Variable -Name win32_installer_exe_sha256 -Option Constant `
    -Value (Get-FileHash -Path $win32_installer_exe -Algorithm SHA256).Hash.ToLowerInvariant()
New-Variable -Name win64_installer_exe_sha256 -Option Constant `
    -Value (Get-FileHash -Path $win64_installer_exe -Algorithm SHA256).Hash.ToLowerInvariant()

Write-Information "[INFO] win32 installer sha256: $win32_installer_exe_sha256"
Write-Information "[INFO] win64 installer sha256: $win64_installer_exe_sha256"

# install
Write-Information "[INFO] installing Erlang..."
Start-Process -Wait -FilePath $win64_installer_exe -ArgumentList '/S'
Write-Information "[INFO] installation complete!"

New-Variable -Name erts_version -Option Constant `
    -Value (Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Ericsson\Erlang | Select-Object -Last 1).PSChildName
Write-Information "[INFO] erts_version: $erts_version"

New-Variable -Name erlangProgramFilesPath -Option Constant `
    -Value ((Get-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Ericsson\Erlang\$erts_version).'(default)')
Write-Information "[INFO] erlangProgramFilesPath: $erlangProgramFilesPath"

New-Variable -Name erl_exe -Option Constant `
    -Value (Join-PathMultiple -Base $erlangProgramFilesPath -Parts @('bin', 'erl.exe'))
Write-Information "[INFO] erl_exe: $erl_exe"

# run a check
& $erl_exe -noninteractive -noshell -eval 'ok=crypto:start(),[{<<"OpenSSL">>,_,_}]=crypto:info_lib(),ok=init:stop().'
try
{
    if ($LASTEXITCODE -eq 0)
    {
        Write-Information "[INFO] erl.exe check succeeded."
    }
    else
    {
        throw "[ERROR] erl.exe check failed!"
    }
}
finally
{
    Write-Information "[INFO] UN-installing Erlang..."
    Start-Process -Wait -FilePath (Join-Path -Path $erlangProgramFilesPath -ChildPath 'uninstall.exe') -ArgumentList '/S'
    Write-Information "[INFO] uninstallation complete!"
}

(Get-Content -Raw -Path erlang.nuspec.in).Replace('@@OTP_VERSION@@', $otp_version) | Set-Content erlang.nuspec

New-Variable -Name chocolateyInstallPs1In -Option Constant `
    -Value (Join-PathMultiple -Base $curdir -Parts @('tools', 'chocolateyInstall.ps1.in'))

New-Variable -Name chocolateyInstallPs1 -Option Constant `
    -Value (Join-PathMultiple -Base $curdir -Parts @('tools', 'chocolateyInstall.ps1'))

(Get-Content -Raw -Path $chocolateyInstallPs1In).Replace('@@OTP_VERSION@@', $otp_version).Replace('@@ERTS_VERSION@@', $erts_version).Replace('@@WIN32_SHA256@@', $win32_installer_exe_sha256).Replace('@@WIN64_SHA256@@', $win64_installer_exe_sha256) | Set-Content $chocolateyInstallPs1

New-Variable -Name chocolateyUninstallPs1In -Option Constant `
    -Value (Join-PathMultiple -Base $curdir -Parts @('tools', 'chocolateyUninstall.ps1.in'))

New-Variable -Name chocolateyUninstallPs1 -Option Constant `
    -Value (Join-PathMultiple -Base $curdir -Parts @('tools', 'chocolateyUninstall.ps1'))

(Get-Content -Raw -Path $chocolateyUninstallPs1In).Replace('@@OTP_VERSION@@', $otp_version).Replace('@@ERTS_VERSION@@', $erts_version) | Set-Content $chocolateyUninstallPs1

if ($PackAndTest -or ($Push -and -not $SkipTest))
{
    Invoke-CommandWithCheck -Command { choco.exe pack } -Description 'choco pack'

    Invoke-CommandWithCheck -Command { choco.exe install erlang $arg_debug $arg_verbose --yes --skip-virus-check --source ".;https://chocolatey.org/api/v2/" } -Description 'choco install'

    Invoke-CommandWithCheck -Command { & $erl_exe -noninteractive -noshell -eval 'ok=crypto:start(),[{<<"OpenSSL">>,_,_}]=crypto:info_lib(),ok=init:stop().' } -Description 'erl.exe check'

    Write-Information "[INFO] choco un-installing Erlang..."
    & choco.exe uninstall erlang $arg_debug $arg_verbose --yes --source ".;https://chocolatey.org/api/v2/"
    Write-Information "[INFO] uninstallation complete!"
}
elseif ($Push -and $SkipTest)
{
    Invoke-CommandWithCheck -Command { choco.exe pack } -Description 'choco pack'
}

if ($Push)
{
    Invoke-CommandWithCheck -Command { choco.exe apikey --yes --key $ApiKey --source https://push.chocolatey.org/ } -Description 'choco apikey'

    Invoke-CommandWithCheck -Command { choco.exe push erlang.$otp_version.nupkg --source https://push.chocolatey.org } -Description 'choco push'
}

Set-PSDebug -Off
