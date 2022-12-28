# Chocolatey Package for Erlang

https://community.chocolatey.org/packages/erlang

# Release

Open PowerShell in Administrator mode and navigate to the clone of the  `chocolatey-beam/erlang-package` repository.

Run

```
.\package.ps1 -PackAndTest
```

When satisfied, run the following to push the package:

```
.\package.ps1 -ApiKey <ApiKey> -Push

```

The ApiKey can be found in your account settings at https://community.chocolatey.org/users/account/LogOn
