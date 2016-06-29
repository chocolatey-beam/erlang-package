$package = 'erlang'
$version = '19.0'
$erl_version = '8.0'

Install-ChocolateyPackage $package 'EXE' '/S' http://www.erlang.org/download/otp_win32_$version.exe http://www.erlang.org/download/otp_win64_$version.exe  -validExitCodes @(0)


Generate-BinFile "erl" -path "$env:ProgramFiles/erl$erl_version/erts-$erl_version/bin/erl.exe"
Generate-BinFile "werl" -path "$env:ProgramFiles/erl$erl_version/erts-$erl_version/bin/werl.exe"

