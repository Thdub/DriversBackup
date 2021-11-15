# Export 3rd party drivers
# Rename driver folders to a human readable mode
# Sort everything by class
# Printer drivers are excluded by default (inf-file names have been changed automatically)

# ####################
# SCRIPT CONFIGURATION
# ####################

# You can set a default folder to export drivers, useful for routine tasks.
# Example: $DestinationPath = "$PSScriptRoot\DriversBackup"
# Example: $DestinationPath = "$PSScriptRoot\DriversBackup"
# Leave "notset" (default setting) if you want to set folder manually within the script browser.
$DestinationPath = "notset"

# Choose between replacing or updating drivers in backup folder, useful if you want to periodically backup your drivers and replace with new backup.
# Set below value to 0 to UPDATE backup folder with new backup.(Default setting)
# Set below value to 1 to REPLACE backup folder with new backup. BEWARE setting this switch will remove all drivers found in destination folder!
$Behavior = 0

# Unused Intel system drivers exported from DriverStore to "Drivers without existing device\System" are (usually) obsolete ones.
# You can safely withdraw them from backup.
# If you want to remove unused Intel network adapter drivers, set below value to 1.
# If you want to backup them anyway, leave below value to 0.(Default setting)
$Remove_Unused_Intel_System_Drivers = 0

# Unused Intel network drivers exported from DriverStore to "Drivers without existing device\Network adapters" are (usually) obsolete ones.
# You can safely withdraw them from backup.
# If you want to remove unused Intel network adapter drivers, set below value to 1.
# If you want to backup them anyway, leave below value to 0.(Default setting)
$Remove_Unused_Intel_Network_Drivers = 0

# ###########################
# END OF SCRIPT CONFIGURATION
# ###########################


# Self-elevate the script
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
	exit;
}

# Check user variables
If (($Behavior -ne 1) -and ($Behavior -ne 0)) {
	Write-Host "Wrong value, use 0 or 1."
	Write-Host "Edit Behavior value and run the script again."
	Start-Sleep -Seconds 3
	Exit 0
}

If (($Remove_Unused_Intel_Network_Drivers -ne 0) -and ($Remove_Unused_Intel_Network_Drivers -ne 1)) {
	Write-Host "Wrong value, use 0 or 1."
	Write-Host "Edit Remove_Unused_Intel_Network_Drivers value and run the script again."
	Start-Sleep -Seconds 3
	Exit 0
}

If (($Remove_Unused_Intel_System_Drivers -ne 0) -and ($Remove_Unused_Intel_System_Drivers -ne 1)) {
	Write-Host "Wrong value, use 0 or 1."
	Write-Host "Edit Remove_Unused_Intel_System_Drivers value and run the script again."
	Start-Sleep -Seconds 3
	Exit 0
}

# Set destination path
# Test path if "DestinationPath" is set by user
if (($DestinationPath -ne "notset") -and (Test-Path $DestinationPath)) { $RealPath = 1 }

# BuildDialog function if path is not set
if ($DestinationPath -eq "notset") {
	Function BuildDialog {
		$sourcecode = @"
		using System;
		using System.Windows.Forms;
		using System.Reflection;
		namespace FolderSelect
		{
			public class FolderSelectDialog
			{
				System.Windows.Forms.OpenFileDialog ofd = null;
				public FolderSelectDialog()
				{
					ofd = new System.Windows.Forms.OpenFileDialog();
					ofd.Filter = "Folders|\n";
					ofd.AddExtension = false;
					ofd.CheckFileExists = false;
					ofd.DereferenceLinks = true;
					ofd.Multiselect = false;
				}
				public string InitialDirectory
				{
					get { return ofd.InitialDirectory; }
					set { ofd.InitialDirectory = value == null || value.Length == 0 ? Environment.CurrentDirectory : value; }
				}
				public string Title
				{
					get { return ofd.Title; }
					set { ofd.Title = value == null ? "Select a folder" : value; }
				}
				public string FileName
				{
					get { return ofd.FileName; }
				}
				public bool ShowDialog()
				{
					return ShowDialog(IntPtr.Zero);
				}
				public bool ShowDialog(IntPtr hWndOwner)
				{
					bool flag = false;
					if (Environment.OSVersion.Version.Major >= 6)
					{
						var r = new Reflector("System.Windows.Forms");
						uint num = 0;
						Type typeIFileDialog = r.GetType("FileDialogNative.IFileDialog");
						object dialog = r.Call(ofd, "CreateVistaDialog");
						r.Call(ofd, "OnBeforeVistaDialog", dialog);
						uint options = (uint)r.CallAs(typeof(System.Windows.Forms.FileDialog), ofd, "GetOptions");
						options |= (uint)r.GetEnum("FileDialogNative.FOS", "FOS_PICKFOLDERS");
						r.CallAs(typeIFileDialog, dialog, "SetOptions", options);
						object pfde = r.New("FileDialog.VistaDialogEvents", ofd);
						object[] parameters = new object[] { pfde, num };
						r.CallAs2(typeIFileDialog, dialog, "Advise", parameters);
						num = (uint)parameters[1];
						try
						{
							int num2 = (int)r.CallAs(typeIFileDialog, dialog, "Show", hWndOwner);
							flag = 0 == num2;
						}
						finally
						{
							r.CallAs(typeIFileDialog, dialog, "Unadvise", num);
							GC.KeepAlive(pfde);
						}
					}
					else
					{
						var fbd = new FolderBrowserDialog();
						fbd.Description = this.Title;
						fbd.SelectedPath = this.InitialDirectory;
						fbd.ShowNewFolderButton = true;
						if (fbd.ShowDialog(new WindowWrapper(hWndOwner)) != DialogResult.OK) return false;
						ofd.FileName = fbd.SelectedPath;
						flag = true;
					}
					return flag;
				}
			}
			public class WindowWrapper : System.Windows.Forms.IWin32Window
			{
				public WindowWrapper(IntPtr handle)
				{
					_hwnd = handle;
				}
				public IntPtr Handle
				{
					get { return _hwnd; }
				}

				private IntPtr _hwnd;
			}
			public class Reflector
			{
				string m_ns;
				Assembly m_asmb;
				public Reflector(string ns)
					: this(ns, ns)
				{ }
				public Reflector(string an, string ns)
				{
					m_ns = ns;
					m_asmb = null;
					foreach (AssemblyName aN in Assembly.GetExecutingAssembly().GetReferencedAssemblies())
					{
						if (aN.FullName.StartsWith(an))
						{
							m_asmb = Assembly.Load(aN);
							break;
						}
					}
				}
				public Type GetType(string typeName)
				{
					Type type = null;
					string[] names = typeName.Split('.');
					if (names.Length > 0)
						type = m_asmb.GetType(m_ns + "." + names[0]);

					for (int i = 1; i < names.Length; ++i) {
						type = type.GetNestedType(names[i], BindingFlags.NonPublic);
					}
					return type;
				}
				public object New(string name, params object[] parameters)
				{
					Type type = GetType(name);
					ConstructorInfo[] ctorInfos = type.GetConstructors();
					foreach (ConstructorInfo ci in ctorInfos) {
						try {
							return ci.Invoke(parameters);
						} catch { }
					}
					return null;
				}
				public object Call(object obj, string func, params object[] parameters)
				{
					return Call2(obj, func, parameters);
				}
				public object Call2(object obj, string func, object[] parameters)
				{
					return CallAs2(obj.GetType(), obj, func, parameters);
				}
				public object CallAs(Type type, object obj, string func, params object[] parameters)
				{
					return CallAs2(type, obj, func, parameters);
				}
				public object CallAs2(Type type, object obj, string func, object[] parameters) {
					MethodInfo methInfo = type.GetMethod(func, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
					return methInfo.Invoke(obj, parameters);
				}
				public object Get(object obj, string prop)
				{
					return GetAs(obj.GetType(), obj, prop);
				}
				public object GetAs(Type type, object obj, string prop) {
					PropertyInfo propInfo = type.GetProperty(prop, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
					return propInfo.GetValue(obj, null);
				}
				public object GetEnum(string typeName, string name) {
					Type type = GetType(typeName);
					FieldInfo fieldInfo = type.GetField(name);
					return fieldInfo.GetValue(null);
				}
			}
		}
"@ # THIS IS A CRITICAL LINE
		$assemblies = ('System.Windows.Forms', 'System.Reflection')
		Add-Type -TypeDefinition $sourceCode -ReferencedAssemblies $assemblies -ErrorAction STOP
	} # ENF OF FUNCTION
	cd c: # THIS IS A CRITICAL LINE
	BuildDialog
	$fsd = New-Object FolderSelect.FolderSelectDialog
	$fsd.Title = "Choose or create backup folder";
	$fsd.InitialDirectory = $PSScriptRoot
	$fsd.ShowDialog() | Out-Null
	$DestinationPath = $fsd.FileName
	if($DestinationPath -eq "") { Exit 0 }
	$RealPath = 1
}

# Create destination path if it doesn't exist
if ($RealPath -ne 1) { New-Item $DestinationPath -ItemType Directory | out-null }

# Remove drivers from previous backup if behavior is set to 1 and path does exist
if (($RealPath -eq 1) -And ($Behavior -eq 1)) {
	$SearchIfEmpty = Get-ChildItem $DestinationPath | Measure-Object
	if ($SearchIfEmpty.count -ne 0) {
		$OldDrivers = Get-ChildItem -Path "$DestinationPath\*" -Recurse | Where {($_.Extension -eq ".inf") -or ($_.Extension -eq ".inf_DO_NOT_IMPORT")} | Select -ExpandProperty FullName
		Write-Host "Removing old drivers from destination path..." -NoNewline
		Foreach ($OldDriver in $OldDrivers) {
			$OldDriverParentFolder = (get-item $OldDriver).Directory.FullName
			Remove-Item $OldDriverParentFolder -Force -Recurse
			Get-ChildItem $DestinationPath -Recurse -Force -Directory | Sort-Object -Property FullName -Descending | Where-Object { $($_ | Get-ChildItem -Force | Select-Object -First 1).Count -eq 0 } | Remove-Item | out-null
		}
		Write-Host "Done`n`n" -NoNewline -ForegroundColor "Green"
	}
}

# Export Drivers
Write-Host "Exporting drivers to `"$DestinationPath`"..." -NoNewline
Dism /Online /Export-Driver /Destination:$DestinationPath | Out-Null
Write-Host "Done" -NoNewline -ForegroundColor "Green"

# Sorting drivers
Write-Host "`n`nSorting drivers..." -NoNewline
$3rdpartydrivers = Get-WindowsDriver -Online
$win32pnpsigneddriver = Get-WmiObject win32_pnpsigneddriver
$win32pnpentity = Get-WmiObject Win32_PNPEntity

foreach($Driver in $3rdpartydrivers) {
	# Set inf-file path to variable. Just in case we need to do more inf-file magic
	$InfFilePath = $Driver.OriginalFileName -match '^.*\\(.*\\.*\.inf)$'
	$InfFilePath = "$DestinationPath\$($Matches[1])"

	# Set inf-file name
	$InfFileName = $Driver.OriginalFileName -match '^.*\\(.*\.inf)_.*$'
	$InfFileName = "$($Matches[1])"

	# DriverFolder "human" name can be found from Win32PNPSignedDriver list attribute DeviceName
	# Search with oem??.inf -drivername
	$DriverFolderName = $win32pnpsigneddriver|Where-Object {$_.InfName -eq "$($Driver.Driver)" }| Select-Object DeviceName
	$DriverFolderName = $DriverFolderName.DeviceName

	if(($DriverFolderName -eq "") -OR ($DriverFolderName -eq $null)) {
		$DriverFolderName = $win32pnpsigneddriver|Where-Object {$_.InfName -eq "$($Driver.Driver)" }| Select-Object DeviceDescription
		$DriverFolderName = $DriverFolderName.DeviceDescription
	}

	# Search with right ini-file -name. Some drivers are not renamed to oem??.inf
	if(($DriverFolderName -eq "") -OR ($DriverFolderName -eq $null)) {
		$DriverFolderName = $win32pnpsigneddriver|Where-Object {$_.InfName -eq "$($InfFileName)" }| Select-Object DeviceDescription
		$DriverFolderName = $DriverFolderName.DeviceDescription
	}

	if($DriverFolderName -is [system.array]) {
		$DriverFolderName = $DriverFolderName[0]
	}

	# Set folder name to infFile name if we couldn't find better information for driver
	# There are no devices using this driver because we didn't find driver info from Win32_pnpsigneddriver
	# Usually these drivers are not needed because there are no devices for these drivers
	# However! There might be devices which will activate later on so they will need driver installed to Windows.
	# Example is SD-card reader device which exist only when SD-card is inserted
	#
	# Move these drivers to _ExtraDrivers_MayNotBeNeeded -folder
	#
	if(($DriverFolderName -eq "") -OR ($DriverFolderName -eq $null)) {
		$DriverFolderName = "$InfFileName"
		$ExtraDriver = $True
	} else {
		$ExtraDriver = $False
	}

	# Remove unsupported characters from folder name
	$pattern = '[^a-zA-Z0-9()[]{}#!&%=]'
	$DriverFolderName = $DriverFolderName -replace $pattern, ' '
	$DriverFolderName = ($DriverFolderName -replace "`t|`n|`r","")
	$DriverFolderName = ($DriverFolderName -replace "`n","")
	$DriverFolderName = ($DriverFolderName -replace "`r","")
	$DriverFolderName = ($DriverFolderName -replace "\\", " ")
	$DriverFolderName = ($DriverFolderName -replace "\/", " ")
	$DriverFolderName = ($DriverFolderName -replace "\*", " ")
	$DriverFolderName = ($DriverFolderName -replace "\?", " ")
	$DriverFolderName = ($DriverFolderName -replace '\"', ' ')
	$DriverFolderName = ($DriverFolderName -replace '®', '')
	if($($DriverFolderName.Length) -gt 70) {
		$DriverFolderName = $DriverFolderName.Substring(0,70)
	}

	$DeviceCategory = $Driver.ClassDescription
	if(($DeviceCategory -eq "") -OR ($DeviceCategory -eq $null)) {
		$DeviceCategory = $Driver.ClassName
	}
	if($DeviceCategory -is [system.array]) {
		$DeviceCategory = $DeviceCategory[0]
	}
	$pattern = '[^a-zA-Z0-9()[]{}#!&%=]'
	$DeviceCategory = $DeviceCategory -replace $pattern, ' '
	$DeviceCategory = ($DeviceCategory -replace "`t|`n|`r","")
	$DeviceCategory = ($DeviceCategory -replace "`n","")
	$DeviceCategory = ($DeviceCategory -replace "`r","")
	$DeviceCategory = ($DeviceCategory -replace "\\", " ")
	$DeviceCategory = ($DeviceCategory -replace "\/", " ")
	$DeviceCategory = ($DeviceCategory -replace "\*", " ")
	$DeviceCategory = ($DeviceCategory -replace "\?", " ")
	$DeviceCategory = ($DeviceCategory -replace '\"', ' ')
	$DeviceCategory = ($DeviceCategory -replace '®', '')
	if($($DeviceCategory.Length) -gt 50) { $DeviceCategory = $DeviceCategory.Substring(0,70) }

	if($ExtraDriver) {
		# This driver does NOT exist in Win32_pnpsigneddriver
		# Usually these drivers are not needed
		$DriverTargetDirectory = "$DestinationPath\Drivers without existing device\$DeviceCategory\$DriverFolderName $($Driver.Version)"
	} else {
		# This driver exist in Win32_pnpsigneddriver
		$DriverTargetDirectory = "$DestinationPath\$DeviceCategory\$DriverFolderName $($Driver.Version)"
	}

	# Printer drivers should not be needed
	if($DeviceCategory -eq "Printers") {
		$DriverTargetDirectory = "$DestinationPath\Drivers without existing device\$DeviceCategory\$DriverFolderName $($Driver.Version)"
	}

	if(-not (Test-Path $DriverTargetDirectory)) {
		New-Item $DriverTargetDirectory -ItemType Directory | out-null
	}

	# Set inf-file directory to variable. We will move this directory to ClassName-directory we created earlier
	$DriverDirectory = $Driver.OriginalFileName -match '^.*\\(.*)\\.*\.inf$'
	$DriverDirectory = "$DestinationPath\$($Matches[1])"

	# Move Driver-files to destination directory
	if ($Behavior -eq 1) {
		Get-ChildItem "$DriverDirectory\*" -Recurse | Move-Item -Destination $DriverTargetDirectory -Force | out-null
		Remove-Item $DriverDirectory -Force | out-null
	} Else {
		Get-ChildItem "$DriverDirectory\*" -Recurse | Copy-Item -Destination $DriverTargetDirectory -Force | out-null
		Remove-Item $DriverDirectory  -Force -Recurse | out-null
	}

	# Rename Printer inf-files so they won't be installed
	if($DeviceCategory -eq "Printers") {
		$InfFiles = Get-Childitem $DriverTargetDirectory -Filter *.inf -Recurse
		foreach($InfFile in $InfFiles) {
			Move-Item -LiteralPath $($InfFile.Fullname) "$DriverTargetDirectory\$($InfFile.Basename).inf_DO_NOT_IMPORT" -Force | out-null
		}
	}
}
Write-Host "Done" -NoNewline -ForegroundColor "Green"

# Remove Intel unused system drivers
if ($Remove_Unused_Intel_Network_Drivers -eq 1) {
	$UnusedSystemDrivers = "$DestinationPath\Drivers without existing device\System devices"
	if (Test-Path $UnusedSystemDrivers) {
		$UnusedSystemDrivers = Get-ChildItem -Path "$UnusedSystemDrivers\*" -Recurse | Where {$_.Extension -eq ".inf"} | Select -ExpandProperty FullName
		Write-Host "`n`nRemoving unused Intel system drivers" -NoNewline
		Foreach ($UnusedSystemDriver in $UnusedSystemDrivers) {
			$ProviderName = (Get-Content -Path "$UnusedSystemDriver" | Select-String "Provider").Line.Split('=')[-1].Split(' ').Split(';')
			if ($ProviderName -eq "%INTEL%") {
				$ParentName = (get-item $UnusedSystemDriver).Directory.FullName
				Remove-Item $ParentName -Force -Recurse
			}
		}
		Write-Host "Done" -NoNewline -ForegroundColor "Green"
	}
} 

# Remove Intel unused network drivers
if ($Remove_Unused_Intel_Network_Drivers -eq 1) {
	$UnusedNetworkDrivers = "$DestinationPath\Drivers without existing device\Network adapters"
	if (Test-Path $UnusedNetworkDrivers) {
		Write-Host "`n`nRemoving unused Intel network drivers" -NoNewline
		$UnusedNetworkDrivers = Get-ChildItem -Path "$UnusedNetworkDrivers \*" -Recurse | Where {$_.Extension -eq ".inf"} | Select -ExpandProperty FullName
		Foreach ($UnusedNetworkDriver in $UnusedNetworkDrivers) {
			$ProviderName = (Get-Content -Path "$UnusedSystemDriver" | Select-String "Provider").Line.Split('=')[-1].Split(' ').Split(';')
			if ($ProviderName -eq "%INTEL%") {
				$ParentName = (get-item $NetworkDriver).Directory.FullName
				Remove-Item $ParentName -Force -Recurse
			}
		}
		Write-Host "Done" -NoNewline -ForegroundColor "Green"
	}
}

# Remove any empty folder left
Get-ChildItem $DestinationPath -Recurse -Force -Directory | Sort-Object -Property FullName -Descending | Where-Object { $($_ | Get-ChildItem -Force | Select-Object -First 1).Count -eq 0 } | Remove-Item | out-null

# Exiting
Write-Host "`n`nPress any key to exit..." -NoNewline
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") > $null
