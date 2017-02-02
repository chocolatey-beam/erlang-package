$package = 'rebar3'
$version = '3.3.4'


Get-ChocolateyWebFile -packageName $package -fileFullPath $env:chocolateyPackageFolder/$package -url "https://github.com/erlang/$package/releases/download/$version/rebar3"

Install-BinFile "rebar3" -path "$env:chocolateyPackageFolder/rebar3.cmd"
