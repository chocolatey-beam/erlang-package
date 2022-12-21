# Chocolatey Package for Erlang

https://community.chocolatey.org/packages/erlang

# Release

After a new Erlang release clone the
[`chocolatey-beam/erlang-package`](https://github.com/chocolatey-beam/erlang-package)
repository and replace all instances of the previous version with the current.

Open PowerShell in Administrator mode and navigate to the `erlang-package` repository.

Run

```
choco pack
```

To test, copy the generated `erlang.*.nupkg` file to a VM and run the following to install:

```
choco install erlang -dv -source ".;https://chocolatey.org/api/v2/"
```

You should see Erlang installed to `C:\Program Files\Erlang OTP`

When satisfied, back on the original machine, run the following to set your API key and push the package:

```
choco apikey --key <ApiKey> --source https://push.chocolatey.org/
choco push erlang.[MAJOR].[MINOR].[PATCH].nupkg --source https://push.chocolatey.org/

```

The ApiKey can be found in the account settings on https://chocolatey.org (credentials in lastpass).
