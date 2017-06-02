$package = 'Elixir'
$version = '1.4.4'
 
$params = @{
  PackageName = $package
  FileType = 'zip'
  CheckSum = '3fc2cc2ec39315d9894a81b9d167029e4a9cfa5bb22edb3d7e0e66971d4e43ed'
  CheckSumType = 'sha256'
  Url = "https://github.com/elixir-lang/elixir/releases/download/v$version/Precompiled.zip"
 
  UnzipLocation = $env:chocolateyPackageFolder;
}
 
if (!(Test-Path($params.UnzipLocation)))
{
  New-Item $params.UnzipLocation -Type Directory | Out-Null
}
 
Install-ChocolateyZipPackage @params
 
$elixirPath = "$env:ChocolateyPackageFolder/bin"
if (![System.IO.Directory]::Exists($elixirPath)) {$elixirPath = "$env:ChocolateyPackageFolder/bin";}
 
$machine_path = [Environment]::GetEnvironmentVariable('Path', 'Machine') 
Install-ChocolateyEnvironmentVariable "Path" "$($machine_path);$elixirPath" Machine
Update-SessionEnvironment
 
Write-Host @'
The Elixir commands have been added to your path.
 
Please restart your current shell session to access Elixir commands:
elixir
elixirc
mix
iex.bat
'@
