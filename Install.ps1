<#
.DESCRIPTION
	Autopilot device provisioning package for device customisation.
	This package installs local experience packs and additional language features, and configures various device settings during Autopilot.
.NOTES
	Version:	1.0
	Author:		https://github.com/rh-au
#>

# PowerShell 32-bit to 64-bit process
if ("$env:PROCESSOR_ARCHITEW6432" -ne "ARM64") {
	if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe") {
		& "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath"
		Exit $lastexitcode
	}
}

Start-Transcript -Path "$env:ProgramData\Autopilot\Install.log"

# Install local experience packs
Get-ChildItem -Path "$PSScriptRoot\Assets\Language" -Recurse -Filter *.appx | ForEach-Object {
	$Language = $_.DirectoryName.Substring($_.DirectoryName.Length - 5, 5)
	if (-not(Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq "Microsoft.LanguageExperiencePack$($Language)" })) {
		Add-AppxProvisionedPackage -Online -PackagePath $_.FullName -LicensePath "$($_.DirectoryName)\License.xml"
	}
}

# Install basic language features and set system locale
Set-WinSystemLocale -SystemLocale "en-AU"
Get-WindowsCapability -Online | Where-Object { $_.Name -match "en-AU" -and $_.State -ne "Installed" } | ForEach-Object {
	Add-WindowsCapability -Online -Name $_.Name
}

# Remove built-in apps
Get-Content -Path "$PSScriptRoot\Assets\Apps.remove" | ForEach-Object {
	$Installed = $_
	Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $Installed } | ForEach-Object {
		$_ | Remove-AppxProvisionedPackage -Online
	}
}

# Install OneDrive
(New-Object Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=844652","$env:ProgramData\OneDriveSetup.exe")
$Install = Start-Process -FilePath "$env:ProgramData\OneDriveSetup.exe" -ArgumentList "/allusers" -PassThru -WindowStyle Hidden
$Install.WaitForExit()
Remove-Item -Path "$env:ProgramData\OneDriveSetup.exe" -Force

# Set registered owner and organisation
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "RegisteredOwner" -Value "Owner" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "RegisteredOrganization" -Value "Organisation" -Force

# Disable search highlights
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Windows Search"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "EnableDynamicContentInWSB" -Value "0" -Type DWord -Force

# Block AAD workplace join for external Azure tenants
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin" -Name "BlockAADWorkplaceJoin" -Value "1" -Type DWord -Force

# Disable network selection window slide
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" -Force

# Copy desktop wallpaper
Copy-Item -Path "$PSScriptRoot\Assets\Wallpaper.jpg" -Destination "$env:ProgramData\Autopilot\Wallpaper.jpg"

# Copy user account pictures
Copy-Item -Path "$PSScriptRoot\Assets\UserAccountPictures\*" -Destination "C:\ProgramData\Microsoft\User Account Pictures" -Recurse -Force

# Create Intune detection file
New-Item -Path "$env:ProgramData\Autopilot\Autopilot.installed" -ItemType file

Stop-Transcript