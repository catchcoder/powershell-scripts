# Windows Package Manager (winget) Upgrade Script

==============================================

## Table of Contents

- [Windows Package Manager (winget) Upgrade Script](#windows-package-manager-winget-upgrade-script)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Requirements](#requirements)
  - [Usage](#usage)
  - [Packages Installed](#packages-installed)
  - [Notes](#notes)
  - [Example Usage](#example-usage)
  - [Links](#links)

## Introduction

This PowerShell script is designed to upgrade all installed packages using the Windows Package Manager (winget). It checks if the script is running as Administrator, creates a temporary directory if it doesn't exist, and then upgrades all installed packages. It also installs specific packages (7zip, Putty, winscp (all Users), tightVNC (Viewer only) and x2go and Xming) using winget.

## Requirements

- PowerShell 5 or later
- Winget (installed automatically if not found)
- Administrator privileges

## Usage

1. Run the script as an Administrator.
2. The script will check for and install the NuGet provider and winget if necessary.
3. The script will accept the MSSTORE terms of transaction and set the geographic region.
4. The script will upgrade all installed packages using winget.
5. The script will install specific packages (7zip, Putty, winscp (all Users), tightVNC (Viewer only) and x2go and Xming) using winget.

## Packages Installed

The following packages are installed by this script:

- 7zip
- PuTTY
- WinSCP (all Users)
- TightVNC (Viewer only)
- X2go
- Xming

## Notes

- Version: 1.0.2
- Date: 2025
- Author: Chris Hawkins and AI Assistant
- This script logs its output to a file in the TEMP directory.
- The script uses a hashtable to store package IDs and custom installation parameters.
- The script defines default switches for winget install, including acceptance of source and package agreements, and verbose output.

## Example Usage

To run the script, simply execute it in PowerShell as an Administrator:

```powershell
.\upgrade-quar-packages.ps1
```

This will start the upgrade process and log the output to a file in the TEMP directory.

## Links

- [GitHub Repository](https://github.com/catchcoder/powershell-scripts)
- [Windows Package Manager (winget) Documentation](https://docs.microsoft.com/en-us/windows/package-manager/)