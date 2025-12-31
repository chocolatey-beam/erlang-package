# Chocolatey Package for Erlang

https://community.chocolatey.org/packages/erlang

## Automated Version Synchronization

The package uses automated synchronization to ensure all Erlang/OTP versions >= 25.0 are available on chocolatey.org.

### Daily Automation

A GitHub Actions workflow runs daily to:
1. Parse the official `otp_versions.table` from the Erlang/OTP repository
2. Query chocolatey.org for published versions
3. Detect and publish any missing versions automatically

### Manual Synchronization

To manually sync versions:

```powershell
.\sync-versions.ps1 -ApiKey <ApiKey>
```

Options:
- `-DryRun` - Show what would be done without building/pushing
- `-MinMajorVersion` - Set minimum OTP version (default: 25)
- `-SpecificVersion` - Process only one version (e.g., "27.3.4")

Examples:

```powershell
# See what's missing
.\sync-versions.ps1 -DryRun

# Sync all versions >= 25.0
.\sync-versions.ps1 -ApiKey <ApiKey>

# Sync only OTP-28.x versions
.\sync-versions.ps1 -MinMajorVersion 28 -ApiKey <ApiKey>

# Build specific version
.\sync-versions.ps1 -SpecificVersion "27.3.4" -ApiKey <ApiKey>
```

## Building a Single Version

To build and test a specific version manually:

```powershell
.\package.ps1 -Version <Version> -PackAndTest
```

When satisfied, push to chocolatey.org:

```powershell
.\package.ps1 -Version <Version> -Push -ApiKey <ApiKey>
```

Options:
- `-SkipTest` - Skip installation testing (faster, for batch processing)
- `-Verbose` - Show detailed choco output
- `-Debug` - Show debug information

Examples:

```powershell
# Build and test locally
.\package.ps1 -Version "28.1.1" -PackAndTest

# Build and push with testing
.\package.ps1 -Version "27.3.4" -Push -ApiKey <ApiKey>

# Build and push without testing (fast)
.\package.ps1 -Version "26.2.5" -Push -SkipTest -ApiKey <ApiKey>
```

## API Key

The ApiKey can be found in your account settings at https://community.chocolatey.org/users/account/LogOn

## Architecture

### Scripts

- **`sync-versions.ps1`** - Orchestrates batch processing of missing versions
  - Parses `otp_versions.table` from GitHub
  - Queries chocolatey.org for published versions
  - Calls `package.ps1` for each missing version
  
- **`package.ps1`** - Builds and publishes a single Erlang version
  - Downloads win32 and win64 installers
  - Installs to extract ERTS version
  - Generates package files from templates
  - Packs and optionally tests/pushes

- **`Test-Package.ps1`** - Validates PowerShell scripts with PSScriptAnalyzer

### Templates

- **`erlang.nuspec.in`** - Package metadata template
- **`tools/chocolateyInstall.ps1.in`** - Installation script template
- **`tools/chocolateyUninstall.ps1.in`** - Uninstallation script template

Placeholders are replaced during build:
- `@@OTP_VERSION@@` - Erlang/OTP version (e.g., "27.3.4")
- `@@ERTS_VERSION@@` - ERTS version (e.g., "15.2.7")
- `@@WIN32_SHA256@@` - SHA256 checksum for 32-bit installer
- `@@WIN64_SHA256@@` - SHA256 checksum for 64-bit installer

### GitHub Actions

- **`validate.yml`** - Runs PSScriptAnalyzer on every push/PR
- **`ci.yml`** - Runs `sync-versions.ps1` daily to auto-publish missing versions
