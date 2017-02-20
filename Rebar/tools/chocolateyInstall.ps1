$package = 'rebar3'
$version = '3.3.5'

$toolsDir = $(Split-Path -Parent $MyInvocation.MyCommand.Definition)
Get-ChocolateyWebFile -packageName $package -fileFullPath $toolsDir/$package -url "https://github.com/erlang/$package/releases/download/$version/rebar3"

Install-BinFile "rebar3" -path "$toolsDir/rebar3.cmd"
