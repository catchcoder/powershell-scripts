# Windows 10 Domain to Standalone Conversion Script

## Synopsis

This PowerShell script converts a Windows 10 machine from a domain-joined configuration to a standalone system, performing essential configuration and cleanup tasks.

## Description

The script automates the transition of a Windows 10 computer from a domain environment to a standalone setup. It performs the following actions:

- Confirms user intent before proceeding.
- Starts a transcript log for auditing.
- Checks for required PowerShell version and administrative privileges.
- Sets and activates a Windows MAK key.
- Modifies local password policies for simplified management.
- Creates new local standard and administrator user accounts.
- Enables and configures the built-in Administrator account.
- Removes Office 365 if present.
- Configures the Security Event Log to overwrite as needed.
- Exports BitLocker recovery keys for all fully encrypted volumes.
- Blocks Microsoft consumer account authentication.
- Adds default system accounts to the local 'Users' group.
- Hides the Administrator account from the login screen.
- Download and installs LibreOffice.
- Removes the computer from the domain using provided credentials.
- Displays next steps for the user, including BitLocker key management and network changes.

## Usage

1. Run this script in an elevated PowerShell session (Run as Administrator).
2. Follow the prompts to confirm the operation and provide necessary credentials.
3. Review the log file generated in the TEMP directory for details of the actions performed.
4. After completion, follow the displayed next steps to finalize the standalone configuration.

## Notes

- Internet access is required for downloading LibreOffice and other online resources.
- Ensure you have backups of important data before running this script.
- Replace placeholder MAK keys and passwords with your organization's actual values before use.
- The script requires PowerShell 5.0 or later.
- Some actions (such as domain removal and BitLocker key export) may require additional permissions.
- Test this script in a non-production environment before deploying widely.

## Metadata

- Author: Chris Hawkins - Academic Applications Team
- Version: 1.0.4
- Date: 3/7/2025

## Requirements

- Requires elevation (Run as Administrator)
- PowerShell 5.0 or later