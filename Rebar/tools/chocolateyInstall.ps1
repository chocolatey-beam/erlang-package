$package = 'rebar3'
$version = 'beta-1'
$erl_version = '7.0'


Get-ChocolateyWebFile -packageName $package -fileFullPath $env:chocolateyPackageFolder/$package -url "https://s3.amazonaws.com/rebar3/rebar3"

Install-BinFile "rebar3" -path "$env:chocolateyPackageFolder/rebar3.cmd"
