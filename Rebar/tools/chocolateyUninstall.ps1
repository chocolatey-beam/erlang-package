$package = 'rebar3'
$version = '3.0.0'

#Note that this process will _not_ uninstall Erlang.
#Remove the shim file.
Remove-BinFile "rebar3" -path "$env:chocolateyPackageFolder/rebar3.cmd"
