$package = 'rebar3'
$version = '3.4.7'

$toolsDir = $(Split-Path -Parent $MyInvocation.MyCommand.Definition)
Get-ChocolateyWebFile -packageName $package -fileFullPath $toolsDir/$package -url "https://github.com/erlang/$package/releases/download/$version/rebar3" -Checksum '1da34bead8d765df5adac01349cae72af070993409bf5cc685b84c9af2036149' -Checksumtype 'sha256'

Install-BinFile "rebar3" -path "$toolsDir/rebar3.cmd"
