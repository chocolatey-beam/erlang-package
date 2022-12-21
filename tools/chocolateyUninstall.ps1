<#
.SYNOPSIS
An uninstall script for Erlang

.NOTES
Author: Luke Bakken - luke@bakken.io
Version: 25.2
#>

New-Variable -Name package -Value 'erlang' -Option Constant
New-Variable -Name otp_version -Value '25.2' -Option Constant
New-Variable -Name erts_version -Value '13.1.3' -Option Constant

New-Variable -Name erlangProgramFilesPath -Option Constant `
    -Value ((Get-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Ericsson\Erlang\$erts_version).'(default)')

Start-Process -Wait -FilePath (Join-Path -Path $erlangProgramFilesPath -ChildPath 'uninstall.exe') -ArgumentList '/S'

# ...and remove the shim files as well.

New-Variable -Name erlangErtsBinPath -Option Constant `
    -Value (Join-Path -Path $erlangProgramFilesPath -ChildPath "erts-$erts_version" | Join-Path -ChildPath 'bin')

Uninstall-BinFile -Name 'ct_run'   -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'ct_run.exe')
Uninstall-BinFile -Name 'erl'      -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'erl.exe')
Uninstall-BinFile -Name 'werl'     -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'werl.exe')
Uninstall-BinFile -Name 'erlc'     -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'erlc.exe')
Uninstall-BinFile -Name 'escript'  -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'escript.exe')
Uninstall-BinFile -Name 'dialyzer' -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'dialyzer.exe')
Uninstall-BinFile -Name 'typer'    -Path (Join-Path -Path $erlangErtsBinPath -ChildPath 'typer.exe')
