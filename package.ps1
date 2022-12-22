param(
    [switch]$PackAndTest = $false,
    [switch]$Push = $false
)

if ($Push)
{
    $PackAndTest = $true
    Write-Host "[INFO] PACKAGE WILL BE TESTED AND PUSHED"
}

$DebugPreference = "Continue"
$ErrorActionPreference = 'Stop'
# Set-PSDebug -Strict -Trace 1
Set-PSDebug -Off
Set-StrictMode -Version 'Latest' -ErrorAction 'Stop' -Verbose

New-Variable -Name curdir  -Option Constant -Value $PSScriptRoot
Write-Host "[INFO] curdir: $curdir"

try
{
    $ProgressPreference = 'SilentlyContinue'
    New-Variable -Name ej -Option Constant `
        -Value (Invoke-WebRequest -Uri https://api.github.com/repos/erlang/otp/releases/latest | ConvertFrom-Json)
}
finally
{
    $ProgressPreference = 'Continue'
}

New-Variable -Name otp_version -Option Constant `
    -Value ($ej.tag_name -replace '^OTP-', '')

Write-Host "[INFO] otp_version: $otp_version"

New-Variable -Name win32_installer_asset  -Option Constant `
    -Value ($ej.assets | Where-Object { $_.name -match '^otp_win32_[0-9.]+\.exe$' })
New-Variable -Name win64_installer_asset  -Option Constant `
    -Value ($ej.assets | Where-Object { $_.name -match '^otp_win64_[0-9.]+\.exe$' })

New-Variable -Name win32_installer_exe -Option Constant -Value $win32_installer_asset.name
New-Variable -Name win64_installer_exe -Option Constant -Value $win64_installer_asset.name

$files = @()
$jobs = @()

if (!(Test-Path -Path $win32_installer_exe))
{
    Write-Host "[INFO] downloading from " $win32_installer_asset.browser_download_url
    $files += @{
        Uri = $win32_installer_asset.browser_download_url
        OutFile = $win32_installer_exe
    }
}
if (!(Test-Path -Path $win64_installer_exe))
{
    Write-Host "[INFO] downloading from " $win64_installer_asset.browser_download_url
    $files += @{
        Uri = $win64_installer_asset.browser_download_url
        OutFile = $win64_installer_exe
    }
}

try
{
    $ProgressPreference = 'SilentlyContinue'
    foreach ($file in $files) {
        $jobs += Start-ThreadJob -Name $file.OutFile -ScriptBlock {
            $params = $using:file
            Invoke-WebRequest @params
        }
    }

    if ($jobs.Count -gt 0)
    {
        Write-Host "[INFO] Downloads started..."
        Wait-Job -Job $jobs
        foreach ($job in $jobs)
        {
            Receive-Job -Job $job
        }
        Write-Host "[INFO] Downloads complete!"
    }
    else
    {
        Write-Host "[INFO] nothing to download!"
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

Write-Host "[INFO] win32 installer sha256: $win32_installer_exe_sha256"
Write-Host "[INFO] win64 installer sha256: $win64_installer_exe_sha256"

# install
Write-Host "[INFO] installing Erlang..."
Start-Process -Wait -FilePath $win64_installer_exe -ArgumentList '/S'
Write-Host "[INFO] installation complete!"

New-Variable -Name erts_version -Option Constant `
    -Value (Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Ericsson\Erlang | Select-Object -Last 1).PSChildName
Write-Host "[INFO] erts_version: $erts_version"

New-Variable -Name erlangProgramFilesPath -Option Constant `
    -Value ((Get-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Ericsson\Erlang\$erts_version).'(default)')
Write-Host "[INFO] erlangProgramFilesPath: $erlangProgramFilesPath"

New-Variable -Name erl_exe -Option Constant `
    -Value (Join-Path -Path $erlangProgramFilesPath -ChildPath 'bin' | Join-Path -ChildPath 'erl.exe')
Write-Host "[INFO] erl_exe: $erl_exe"

# run a check
& $erl_exe -noninteractive -noshell -eval 'ok=crypto:start(),[{<<"OpenSSL">>,_,_}]=crypto:info_lib(),ok=init:stop().'
try
{
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "[INFO] erl.exe check succeeded."
    }
    else
    {
        throw "[ERROR] erl.exe check failed!"
    }
}
finally
{
    Write-Host "[INFO] UN-installing Erlang..."
    Start-Process -Wait -FilePath (Join-Path -Path $erlangProgramFilesPath -ChildPath 'uninstall.exe') -ArgumentList '/S'
    Write-Host "[INFO] uninstallation complete!"
}

(Get-Content -Raw -Path erlang.nuspec.in).Replace('@@OTP_VERSION@@', $otp_version) | Set-Content erlang.nuspec

New-Variable -Name chocolateyInstallPs1In -Option Constant `
    -Value (Join-Path -Path $curdir -ChildPath 'tools' | Join-Path -ChildPath 'chocolateyInstall.ps1.in')

New-Variable -Name chocolateyInstallPs1 -Option Constant `
    -Value (Join-Path -Path $curdir -ChildPath 'tools' | Join-Path -ChildPath 'chocolateyInstall.ps1')

(Get-Content -Raw -Path $chocolateyInstallPs1In).Replace('@@OTP_VERSION@@', $otp_version).Replace('@@ERTS_VERSION@@', $erts_version).Replace('@@WIN32_SHA256@@', $win32_installer_exe_sha256).Replace('@@WIN64_SHA256@@', $win64_installer_exe_sha256) | Set-Content $chocolateyInstallPs1

New-Variable -Name chocolateyUninstallPs1In -Option Constant `
    -Value (Join-Path -Path $curdir -ChildPath 'tools' | Join-Path -ChildPath 'chocolateyUninstall.ps1.in')

New-Variable -Name chocolateyUninstallPs1 -Option Constant `
    -Value (Join-Path -Path $curdir -ChildPath 'tools' | Join-Path -ChildPath 'chocolateyUninstall.ps1')

(Get-Content -Raw -Path $chocolateyUninstallPs1In).Replace('@@OTP_VERSION@@', $otp_version).Replace('@@ERTS_VERSION@@', $erts_version) | Set-Content $chocolateyUninstallPs1

if ($PackAndTest)
{
    & choco pack
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "[INFO] 'choco pack' succeeded."
    }
    else
    {
        throw "[ERROR] 'choco pack' failed!"
    }

    & choco install erlang --verbose --debug --yes --source ".;https://chocolatey.org/api/v2/"
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "[INFO] 'choco install' succeeded."
    }
    else
    {
        throw "[ERROR] 'choco install' failed!"
    }

    & $erl_exe -noninteractive -noshell -eval 'ok=crypto:start(),[{<<"OpenSSL">>,_,_}]=crypto:info_lib(),ok=init:stop().'
    try
    {
        if ($LASTEXITCODE -eq 0)
        {
            Write-Host "[INFO] erl.exe check succeeded."
        }
        else
        {
            throw "[ERROR] erl.exe check failed!"
        }
    }
    finally
    {
        Write-Host "[INFO] choco un-installing Erlang..."
        & choco uninstall erlang --verbose --debug --yes --source ".;https://chocolatey.org/api/v2/"
        Write-Host "[INFO] uninstallation complete!"
    }
}

if ($Push)
{
    & choco apikey --yes --key $env:CHOCOLATEY_API_KEY --source https://push.chocolatey.org/
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "[INFO] 'choco apikey' succeeded."
    }
    else
    {
        throw "[ERROR] 'choco apikey' failed!"
    }

    & choco push erlang.$otp_version.nupkg --source https://push.chocolatey.org
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "[INFO] 'choco push' succeeded."
    }
    else
    {
        throw "[ERROR] 'choco push' failed!"
    }
}

Set-PSDebug -Off
