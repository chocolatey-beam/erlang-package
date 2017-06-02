<#
.SYNOPSIS
An install script for installing Erlang silently on the machine via ChocolateyNuGet

.NOTES
Author: Onorio Catenacci - catenacci@ieee.org
Version: 19.2
#>

$package = 'erlang'
$version = '19.3'
$erl_version = '8.3'

$params = @{
  PackageName = $package
  FileType = 'exe'
  SilentArgs = '/S'
  Url = "http://www.erlang.org/download/otp_win32_$version.exe"
  CheckSum = 'a33964be7e98304a331d294921bea31b45cefa365c5049cc1a3764980b1347cf'
  CheckSumType = 'sha256'
  Url64 = "http://www.erlang.org/download/otp_win64_$version.exe"
  CheckSum64 = 'e38074ec99da22a04bd00cda83d412e07294dbaf031c2369c195f712caa0cc70'
  CheckSumType64 = 'sha256'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @params


Generate-BinFile "erl" -path "$env:ProgramFiles/erl$erl_version/erts-$erl_version/bin/erl.exe"
Generate-BinFile "werl" -path "$env:ProgramFiles/erl$erl_version/erts-$erl_version/bin/werl.exe"

