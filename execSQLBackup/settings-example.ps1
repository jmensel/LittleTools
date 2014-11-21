# settings.conf
#################################
# Variables that need changing  #
#################################

# Destination Folder for your Backups:
# Don't change this lightly.  If this is a UNC path, every SQL service account
# has to have access to this folder.  See the README for full details.
# Don't try setting this to a network drive.  It won't work.
# If this variable is commented out, your backups will be dumped to
# each SQL server's default backup location, which may or may not be what you want.
$global:Dest = "\\myhost\SQL_Backup_Dumps";

# How long we want to keep full backups around
$global:xDays=5;

# Email variables:
$global:to = "me@mine.com";
$global:smtpHost = "my.smtphost.com";
$global:from = "$($env:UserName)@mine.com";

# Don't change anything below this line!

#################################