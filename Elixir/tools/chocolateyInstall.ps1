$package = 'Elixir'
$version = '1.1.1'

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

Copy-Item "$env:ChocolateyPackageFolder/bin/iex.bat" "$env:ChocolateyInstall/bin/iex.bat"
Copy-Item "$env:ChocolateyPackageFolder/bin/elixir.bat" "$env:ChocolateyInstall/bin/elixir.bat"
Copy-Item "$env:ChocolateyPackageFolder/bin/elixirc.bat" "$env:ChocolateyInstall/bin/elixirc.bat"
Copy-Item "$env:ChocolateyPackageFolder/bin/mix.bat" "$env:ChocolateyInstall/bin/mix.bat"

Write-Host @'
Please restart your current shell session to access Elixir commands:
elixir
elixirc
mix
iex.bat
'@
