execSQLBackup.ps1
README

John Mensel
jmensel@gmail.com


Scheduled Task Invocation:

powershell.exe c:\YourFolder\execSQLBackup.ps1 -Verbose -FullBackup -InstanceFile c:\YourFolder\instances.conf -ConfigFile c:\YourFolder\settings.ps1

Backing up to a network drive:

If you want this script to backup databases to a network location, you must do the following:

 - You must use a UNC path.  Network drives won't work.
 
 - The SQL service account on the server that you are backing up must have read/write
   access to the network share to which you are backing up.
   If you're running MSSQL as"Local System" or some other local-only account, it's not going to work.
   Best Practice is to use "Network Service", and to then grant permissions on the backup folder to the SQL server's Machine account (i.e. $HOSTNAME)
   Please don't do anything silly like using a Domain Admin account for the SQL service user.  You'll be p0wnd for sure.
   An ordinary domain user will work fine.  MS has documented the setup of this sort of service user extensively.

Backup Destination:

 - If you don't set the $dest variable, the script will back up to whatever the default backup location is on your SQL server.  This may or may not be desireable.  Please be careful not to use up all of your available disk space.
 
Removing old Backups:

 - Make sure that you set the $xDays variable to a sane value that will keep your drives from filling up.  

Email Notification:

 - The script will connect to the $smtpHost with the credentials of the user who is running the script.
 - If you're delivering this via your friendly neighborhood Exchange server, you'll need to make sure that this user has the right to send outbound mail.
 - This script doesn't do SMTP auth yet.  If you're nice to me and buy me a doughnut he'll I'll add it for you.

