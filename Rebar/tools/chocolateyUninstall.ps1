$package = 'rebar3'
$version = 'beta-1'
$erl_version = '7.0'

#Note that this process will _not_ uninstall Erlang.
#And remove the shim files as well.
Remove-BinFile "rebar3" -path "$env:chocolateyPackageFolder/rebar3.cmd"
