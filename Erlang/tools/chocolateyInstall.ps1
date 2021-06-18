<#
.SYNOPSIS
An install script for installing Erlang silently on the machine via ChocolateyNuGet

.NOTES
Author: Onorio Catenacci - catenacci@ieee.org
Version: 24.0
#>

$package = 'erlang'
$version = '24.0'
$erl_version = '12.0'

$params = @{
  PackageName = $package
  FileType = 'exe'
  SilentArgs = '/S'
  Url = "https://erlang.org/download/otp_win32_$version.exe"
  CheckSum = 'ccc1e5918aefb543d2b5e7547c44e1b1ff66d62cd4ea74dd4782f694a6de8a44'
  CheckSumType = 'sha256'
  Url64 = "https://erlang.org/download/otp_win64_$version.exe"
  CheckSum64 = 'f13311ae26d5260566740f8a7f124d0ba3589a1f52aada84b236825641f53225'
  CheckSumType64 = 'sha256'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @params

$baseErlangPath = "$env:ProgramFiles\erl-$version\erts-$erl_version\bin"

Generate-BinFile "ct_run" -path "$baseErlangPath\ct_run.exe"
Generate-BinFile "erl" -path "$baseErlangPath\erl.exe"
Generate-BinFile "werl" -path "$baseErlangPath\werl.exe"
Generate-BinFile "erlc" -path "$baseErlangPath\erlc.exe"
Generate-BinFile "escript" -path "$baseErlangPath\escript.exe"
Generate-BinFile "dialyzer" -path "$baseErlangPath\dialyzer.exe"
Generate-BinFile "typer" -path "$baseErlangPath\typer.exe"
