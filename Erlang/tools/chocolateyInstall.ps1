<#
.SYNOPSIS
An install script for installing Erlang silently on the machine via ChocolateyNuGet

.NOTES
Author: Onorio Catenacci - catenacci@ieee.org
Version: 20.2
#>

$package = 'erlang'
$version = '20.2'
$erl_version = '9.2'

$params = @{
  PackageName = $package
  FileType = 'exe'
  SilentArgs = '/S'
  Url = "http://www.erlang.org/download/otp_win32_$version.exe"
  CheckSum = '961f2745f4791198cc74ea6b1c36bfe3d9598f26dcc4f945df51302e4b67f7f3' 
  CheckSumType = 'sha256'
  Url64 = "http://www.erlang.org/download/otp_win64_$version.exe"
  CheckSum64 = 'd06c5f644d831f5b39654d3d191c628593c947fa2592ba282969a8298cff1a12'
  CheckSumType64 = 'sha256'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @params

$baseErlangPath = "$env:ProgramFiles/erl$erl_version/erts-$erl_version/bin"

Generate-BinFile "erl" -path "$baseErlangPath/erl.exe"
Generate-BinFile "werl" -path "$baseErlangPath/werl.exe"
Generate-BinFile "erlc" -path "$baseErlangPath/erlc.exe"
Generate-BinFile  "escript" -path "$baseErlangPath/escript.exe"
Generate-BinFile "dialyzer" -path "$baseErlangPath/dialyzer.exe"

