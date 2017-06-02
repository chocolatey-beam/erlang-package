$package = 'erlang'
$version = '19.3'
$erl_version = '8.3'

start-process -wait "C:\Program Files\erl$erl_version\uninstall.exe"

#And remove the shim files as well.
Remove-BinFile "erl" -path "$env:ProgramFiles/erl$erl_version/erts-$erl_version/bin/erl.exe"
Remove-BinFile "werl" -path "$env:ProgramFiles/erl$erl_version/erts-$erl_version/bin/werl.exe"
