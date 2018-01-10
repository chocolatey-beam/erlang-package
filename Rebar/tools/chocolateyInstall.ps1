$package = 'rebar3'
$version = '3.5.0'

$toolsDir = $(Split-Path -Parent $MyInvocation.MyCommand.Definition)
Get-ChocolateyWebFile -packageName $package -fileFullPath $toolsDir/$package -url "https://github.com/erlang/$package/releases/download/$version/rebar3" -Checksum 'c9c1463722e55156e12c0678c54fe6b36bf82c5ef7c26de0921da889c09de53e' -Checksumtype 'sha256'

Install-BinFile "rebar3" -path "$toolsDir/rebar3.cmd"
