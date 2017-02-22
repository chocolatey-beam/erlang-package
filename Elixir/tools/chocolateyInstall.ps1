$package = 'Elixir'
$version = '1.4.2'
 
$params = @{
  PackageName = $package
  FileType = 'zip'
  CheckSum = '3ff610166612db10d3f97895972882a6912e99628e31116d22406389c1de48cc'
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
