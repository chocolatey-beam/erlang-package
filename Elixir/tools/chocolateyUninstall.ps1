$package = 'Elixir'

Uninstall-ChocolateyZipPackage $packageName $package $zipFileName 'Precompiled.zip'

#And insure we remove the shortcuts to the batch files as well

Remove-BinFile "ielixir" -path "$env:ChocolateyPackageFolder/bin/iex.bat"
Remove-BinFile "elixir"  -path "$env:ChocolateyPackageFolder/bin/elixir.bat"
Remove-BinFile "elixirc"  -path "$env:ChocolateyPackageFolder/bin/elixirc.bat"
Remove-BinFile "mix"  -path "$env:ChocolateyPackageFolder/bin/mix.bat"


