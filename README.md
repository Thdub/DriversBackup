# Drivers Backup
Backup all 3rd party drivers, sort your drivers with a "human readable" folder name and inside "driver category" folders.

There is 4 values you can edit:
   - Destination path : "not set" default value, will open a convenient browser to choose backup folder, starting at script folder.
     You can also set a custom backup path - existing or not - inside double quotes.
   - Behavior : Set to 1 to remove old drivers from destination path, or set to 0 to update backup folder without removing old drivers (default setting).
     If set to 1, script will look for .inf files in destination path and delete every .inf file (parent) folder.
   - Remove Unused Intel System Drivers : Intel system drivers exported from DriverStore to "Drivers without existing device\System" are usually obsolete ones, you can safely          withdraw them from backup. Set value to 1 if you want to remove unused Intel System drivers, or leave to 0 to backup them anyway (default setting).
   - Remove Unused Intel Network Drivers : Intel Network drivers exported from DriverStore to "Drivers without existing device\Network adapters" are usually obsolete ones, you can      safely withdraw them from backup. Set value to 1 if you want to remove unused Intel network adapter drivers, or leave to 0 to backup them anyway (default setting).
