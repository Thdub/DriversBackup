# Drivers Backup
Backup all 3rd party drivers, sort your drivers with a "human readable" folder name, inside driver category folders.

There is 4 values you can edit:
   - Destination path : leave "not set" value to browse and choose backup folder, or enter a backup path (existing or not) inside double quotes.
   - Behavior : Set to 1 to remove old drivers from destination path, to 0 to update backup folder without removing old drivers (default setting)
   - Remove Unused Intel System Drivers
     Intel system drivers exported from DriverStore to "Drivers without existing device\System" are replaced and usually obsolete ones, you can safely withdraw them from backup.
     Set value to 1 if you want to remove unused Intel network adapter drivers, or leave to 0 to backup them anyway (default setting)
   - Remove Unused Intel Network Drivers
      Intel Network drivers exported from DriverStore to "Drivers without existing device\Network adapters" are replaced and usually obsolete ones, you can safely withdraw them         from backup. Set value to 1 if you want to remove unused Intel network adapter drivers, or leave to 0 to backup them anyway (default setting)
