$DebugPreference = "Continue"
$ErrorActionPreference = 'Stop'
Set-PSDebug -Strict -Trace 1
Set-StrictMode -Version 'Latest' -ErrorAction 'Stop' -Verbose

New-Variable -Name ej -Option Constant `
    -Value (Invoke-WebRequest -Uri https://api.github.com/repos/erlang/otp/releases/latest | ConvertFrom-Json)

New-Variable -Name otp_version -Option Constant -Value $ej.tag_name

Write-Host "[INFO] otp_version: $otp_version"

New-Variable -Name installer_asset  -Option Constant `
    -Value ($ej.assets | Where-Object { $_.name -match '^otp_win64_[0-9.]+\.exe$' })

New-Variable -Name installer_exe -Option Constant -Value $installer_asset.name

if (!(Test-Path -Path $installer_exe))
{
    Invoke-WebRequest -Uri $installer_asset.browser_download_url -OutFile $installer_exe
}

New-Variable -Name installer_exe_sha256 -Option Constant `
    -Value (Get-FileHash -Path $installer_exe -Algorithm SHA256).Hash.ToLowerInvariant()

Start-Process -Wait -FilePath $installer_exe -ArgumentList '/S'

New-Variable -Name erts_version -Option Constant `
    -Value (Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Ericsson\Erlang | Select-Object -Last 1).PSChildName

Write-Host "[INFO] erts_version: $erts_version"
