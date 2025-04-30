# Remote Access and Utility Packages Installer

==============================================

## Table of Contents

- [Remote Access and Utility Packages Installer](#remote-access-and-utility-packages-installer)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Requirements](#requirements)
  - [Packages Installed](#packages-installed)
  - [Usage](#usage)
  - [Notes](#notes)

## Introduction

This PowerShell script installs common remote access and utility packages using winget, including 7zip, PuTTY, WinSCP, TightVNC, Xming, and X2go client.

## Requirements

- Administrative privileges
- PowerShell 5+
- Winget (installed automatically if not found)

## Packages Installed

The following packages are installed by this script:

- 7zip
- PuTTY
- WinSCP (all users, not portable)
- TightVNC (VNC Viewer only, not VNC server)
- Xming
- X2go client

## Usage

1. Run the script as an Administrator.
2. The script will check for and install the NuGet provider and winget if necessary.
3. The script will accept the MSSTORE terms of transaction and set the geographic region.
4. The script will install the specified packages using winget.

## Notes

- Version: 1.02
- Author: Chris Hawkins and AI Assistant
- Date: 2025
- This script logs its output to a file in the TEMP directory.
- The script uses a hashtable to store package IDs and custom installation parameters.
- The script defines default switches for winget install, including acceptance of source and package agreements, and verbose output.
