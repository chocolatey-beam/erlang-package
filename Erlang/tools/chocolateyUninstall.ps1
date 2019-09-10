$package = 'erlang'
$version = '20.2'
$erl_version = '9.2'

start-process -wait "C:\Program Files\erl$erl_version\uninstall.exe"

#And remove the shim files as well.
$baseErlangPath = "$env:ProgramFiles/erl$erl_version/erts-$erl_version/bin"

Remove-BinFile "ct_run" -path "$baseErlangPath/ct_run.exe"
Remove-BinFile "erl" -path "$baseErlangPath/erl.exe"
Remove-BinFile "werl" -path "$baseErlangPath/werl.exe"
Remove-BinFile "erlc" -path "$baseErlangPath/erlc.exe"
Remove-BinFile "escript" -path "$baseErlangPath/escript.exe"
Remove-BinFile "dialyzer" -path "$baseErlangPath/dialyzer.exe"
Remove-BinFile "typer" -path "$baseErlangPath/typer.exe"

