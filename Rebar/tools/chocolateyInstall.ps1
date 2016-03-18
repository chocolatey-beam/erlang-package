$package = 'rebar3'
$version = '3.0.0'


#Get-ChocolateyWebFile -packageName $package -fileFullPath $env:chocolateyPackageFolder/$package -url "https://github.com/rebar/$package/archive/3.0.0-$version.zip"

Get-ChocolateyWebFile -packageName $package -fileFullPath $env:chocolateyPackageFolder/$package -url "https://github.com/rebar/$package/archive/$version.zip"

Install-BinFile "rebar3" -path "$env:chocolateyPackageFolder/rebar3.cmd"
