# Autopilot Device Provisioning
Autopilot device provisioning package for device customisation. This package installs local experience packs and additional language features, and configures various device settings during Autopilot.

## Usage
1. Download the package and customise Install.ps1.
2. Package with the [Microsoft Win32 Content Prep Tool](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool).
3. Add to Microsoft Intune and assign device group.
4. Block device usage with ESP until Autopilot Device Provisioning is installed.


#### Install command
Powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
#### Uninstall command
Powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Uninstall.ps1
#### Install detection
%ProgramData%\Autopilot.installed
