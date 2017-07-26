<#
.SYNOPSIS
An install script for installing Erlang silently on the machine via ChocolateyNuGet

.NOTES
Author: Onorio Catenacci - catenacci@ieee.org
Version: 20.0
#>

$package = 'erlang'
$version = '20.0'
$erl_version = '9.0'

$params = @{
  PackageName = $package
  FileType = 'exe'
  SilentArgs = '/S'
  Url = "http://www.erlang.org/download/otp_win32_$version.exe"
  CheckSum = 'b92f326d8988b0a98c654ffe9bceccf5b7d0baffe6ec224bc8e4cfdc0e53fd8f' 
  CheckSumType = 'sha256'
  Url64 = "http://www.erlang.org/download/otp_win64_$version.exe"
  CheckSum64 = '60dc4b43b18271e90bb09e96164dab78e7205e698401010f23f135b2f64ee564'
  CheckSumType64 = 'sha256'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @params


Generate-BinFile "erl" -path "$env:ProgramFiles/erl$erl_version/erts-$erl_version/bin/erl.exe"
Generate-BinFile "werl" -path "$env:ProgramFiles/erl$erl_version/erts-$erl_version/bin/werl.exe"

