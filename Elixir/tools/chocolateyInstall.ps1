$package = 'Elixir'
$version = '1.1.0-rc.0'

$params = @{
  PackageName = $package;
  FileType = 'zip';
  Url = "https://github.com/elixir-lang/elixir/releases/download/v$version/Precompiled.zip";
  UnzipLocation = $env:chocolateyPackageFolder;
}

if (!(Test-Path($params.UnzipLocation)))
{
  New-Item $params.UnzipLocation -Type Directory | Out-Null
}

Install-ChocolateyZipPackage @params

Generate-BinFile "iex.bat" -path "$env:ChocolateyPackageFolder/bin/iex.bat"
Generate-BinFile "elixir"  -path "$env:ChocolateyPackageFolder/bin/elixir.bat"
Generate-BinFile "elixirc"  -path "$env:ChocolateyPackageFolder/bin/elixirc.bat"
Generate-BinFile "mix"  -path "$env:ChocolateyPackageFolder/bin/mix.bat"

Write-Host @'
Please restart your current shell session to access Elixir commands:
elixir
elixirc
mix
iex.bat

NB: you must type "iex.bat". Simply typing "iex" will not work.
'@
