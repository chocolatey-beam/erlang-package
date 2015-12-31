$package = 'Elixir'

Uninstall-ChocolateyZipPackage $packageName $package $zipFileName 'Precompiled.zip'

#And insure we remove the shortcuts to the batch files as well

Remove-Item "$env:ChocolateyInstall/bin/iex.bat"
Remove-Item "$env:ChocolateyInstall/bin/elixir.bat"
Remove-Item "$env:ChocolateyInstall/bin/elixirc.bat"
Remove-Item "$env:ChocolateyInstall/bin/mix.bat"

