<#
.SYNOPSIS
An install script for installing Erlang silently on the machine via ChocolateyNuGet

.NOTES
Author: Luke Bakken - luke@bakken.io
Version: 25.2
#>

New-Variable -Name package -Value 'erlang' -Option Constant
New-Variable -Name otp_version -Value '25.2' -Option Constant
New-Variable -Name erts_version -Value '13.1.3' -Option Constant

$params = @{
  PackageName = $package
  FileType = 'exe'
  SilentArgs = '/S'
  Url = "https://github.com/erlang/otp/releases/download/OTP-$otp_version/otp_win32_$otp_version.exe"
  CheckSum = '4d9b142556b69d4ccc449e2b79248a736c8e6e02b400cccb1656a8230427b680'
  CheckSumType = 'sha256'
  Url64 = "https://github.com/erlang/otp/releases/download/OTP-$otp_version/otp_win64_$otp_version.exe"
  CheckSum64 = '412eec08acf8b3f0305e9a16efd57ab901e30c1c24379c171cefc74fadc301c2'
  CheckSumType64 = 'sha256'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @params

New-Variable -Name erlangProgramFilesPath -Option Constant`
    -Value ((Get-ItemProperty -Path HKCU:\Software\Ericsson\Erlang\$erts_version).'(default)')

New-Variable -Name erlangErtsBinPath -Option Constant `
    -Value (Join-Path -Path $erlangProgramFilesPath -ChildPath "erts-$erts_version" | Join-Path -ChildPath 'bin')

Install-BinFile -Name 'ct_run'   -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'ct_run.exe')
Install-BinFile -Name 'erl'      -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'erl.exe')
Install-BinFile -Name 'werl'     -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'werl.exe')
Install-BinFile -Name 'erlc'     -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'erlc.exe')
Install-BinFile -Name 'escript'  -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'escript.exe')
Install-BinFile -Name 'dialyzer' -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'dialyzer.exe')
Install-BinFile -Name 'typer'    -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'typer.exe')
