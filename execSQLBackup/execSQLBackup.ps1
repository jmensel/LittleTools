#####################################################
# Backup SQL instances to a central network share
# v.1.3
# PLEASE read the README file and change the variables
# in settings.ps1 before implementing this script!                                     
#####################################################
# John Mensel
# jmensel@gmail.com
# Command line arguments
param(
   [string]$ConfigFile,
   [string]$InstanceFile,
   [switch]$Help,
   [switch]$FullBackup,
   [switch]$LogBackup,
   [switch]$NotifyByEmail,
   [switch]$verbose,
   [switch]$ChecksVerbose
   )


# Include variables from specified config file or default to settings.ps1
if ($ConfigFile) {
 &$ConfigFile;
} else {
 &./settings.ps1;
}


# Messages are logged to these arrays for later output
# Set as a Global to allow log output from functions to be preserved.
$Global:logArray = @();
$Global:faillogArray = @();

## Load SMO Assemblies that we'll need for database comm.        
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo');            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Sdk.Sfc');            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO');               
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended');

# Be Helpful
function help([switch]$help) {
    Write-Output "`nUsage: Backup-SQL_instances.ps1 -Option1 -Option2 -ConfigFile [filename] ";
    Write-Output "`nExample:";
    Write-Output "  Backup-SQL-instances.ps1 -FullBackup -Verbose -InstanceFile File instances.conf";
    Write-Output "`nSwitches:";
	Write-Output "-ChecksVerbose:";
	Write-Output "  Shows all output of DB consistency Checks.  This generates a LOT of output.";
	Write-Output "-ConfigFile:"
	Write-Output "  File that contains custom variables you've set."
	Write-Output "  Defaults to settings.ps1."
    Write-Output "-InstanceFile:";
    Write-Output "  FileThat contains all of the instances you wish to back up.";
    Write-Output "-FullBackup:";
    Write-Output "  Perform a Full Database Backup and rotate the logs";
    Write-Output "-LogBackup";
    Write-Output "  Transaction Log Backup";
    Write-Output "-NotifyByEmail";
    Write-Output "  Send an Email with Job Results. You must configure variables in the script for this to work!";
    Write-Output "-Help";
    Write-Output "  Show This Dialog";
    Write-Output "-Verbose";
    Write-Output "  Maximum verbosity.";
    Write-Output "  By default, this script only outputs error reports.";
    exit 0
}
# End Function Help
 

function local:ExecFullBackup($Server)
{
                   
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $Server;            

# If it can't connect and enumerate databases, fail and move on.
# There is a better way to test for this than a foreach loop.
# --> Fix for next version
trap { $Global:failLogArray += "Could not connect to database $srv"; return } foreach ($db in $srv.Databases) {};

# If missing set default backup directory and check path validity.            
 If ($global:Dest -eq "") {
   if ($verbose) { $Global:logArray += "No Destination directory specified, writing backups to server default backup location."};
   $global:Dest = $server.Settings.BackupDirectory + "\";
   $isLocalBackup = "1";
  } elseif (Test-Path $global:Dest) {
  } else {
    throw write-host "The backup target folder $global:Dest does not exist.  Please create it and try again.";
 }  
                

$Global:logArray += ("Started full backup of instance $srv at: " + (Get-Date -format yyyy-MM-dd-HH:mm:ss));            

# Full-backup for every database            
foreach ($db in $srv.Databases)            
{    
	# Get rid of the unwanted braces in the pathnames for folder names, exclusion checks
    $dbClean = $db -replace '\[' , '' -replace '\]' , '';
	$srvClean = $srv -replace '\[' , '' -replace '\]' , '';
	
	# Now we execute stuff
    If($db.Name -ne "TempDB")  # No need to backup TempDB            
    {       
        $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;            
        $backup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup");            
        $backup.Action = "Database";
        
        # Switch comments on the next two lines to force a failure for testing
        $backup.Database = $db.Name;
        #$backup.Database = "BogusDatabase-JHM";
        
        $backupFolder= "$global:Dest\Full\$Server\$dbClean\";
		
		# Run DB Consistency Checks
		if ($ChecksVerbose) 
		{
		$db.CheckTables([Microsoft.SqlServer.Management.Smo.RepairType]::None,[Microsoft.SqlServer.Management.Smo.RepairOptions]::AllErrorMessages);
		} else {
		$db.CheckTables([Microsoft.SqlServer.Management.Smo.RepairType]::None);
		}
		
		# Is there a folder to backup to?
        if (Test-Path $backupfolder) {
            } else {
            md $backupfolder;
            } 
        if ($verbose) { $Global:logArray += ("Started Backup of $srv\$dbClean at: " + (Get-Date -format yyyy-MM-dd-HH:mm:ss))};
        $backup.Devices.AddDevice($backupFolder + $db.Name + "_full_" + $timestamp + ".bak", "File");            
        $backup.BackupSetDescription = "Full backup of " + $db.Name + " " + $timestamp;            
        $backup.Incremental = 0;            
        # Starting full backup process.            
        $backup.SqlBackup($srv);
		#Enable the next line for debugging
		#$error[0] | format-list -force;
        if ($?) {
            if ($verbose) {$Global:logArray += "Backup of $srv\$dbClean Successful."};
            # Clean Up Transaction Log Backups if Full Backup Worked
            # Doesn't run on DBs with simple recovery model
            $TodayDate=Get-Date;
            If ($db.RecoveryModel -ne 3) {
              if (Test-Path $global:Dest\Log\$Server\$dbClean) {
              Get-ChildItem $global:Dest\Log\$Server\$dbClean -Recurse |
                where { ($_.name -like '*.trn')} |
                Remove-Item -recurse -force;
              } else {
              $Global:logArray += "    The Log Directories for $dbClean haven't been generated yet, so I'm not rotating logs.";
              $Global:logArray += "    Have you run this script with -LogBackup?`n";
              }
            }
            # Truncate Full Backup Dumps to $global:xDays old
			# --> Fix next version.  This is inelegant syntax.  Tidy it up.
            if ($verbose) {
            Get-ChildItem $global:Dest\Full\$Server\$dbClean\ -Recurse |
              where { ($_.lastWriteTime -lt $TodayDate.AddDays(-$global:xDays)) -and ($_.name -like '*.bak') } |
              Remove-Item -recurse -force;
             } else {
             Get-ChildItem $global:Dest\Full\$Server\$dbClean\ -Recurse |
              where { ($_.lastWriteTime -lt $TodayDate.AddDays(-$global:xDays)) -and ($_.name -like '*.bak') } |
              Remove-Item -recurse -force | Out-Null;
             }
			# If the system performed a local backup, then pull the files to
			
            #$isBackupError=("Backup of $server complete at: " + (Get-Date -format  yyyy-MM-dd-HH:mm:ss));
			 } else {
           $Global:faillogArray += "!--> Backup of $server : $dbClean Failed!";
           $isBackupError="!--> Backup of $dbClean Failed";
         }
        if ($verbose) {$Global:logArray += (("Finished $dbClean at: " + (Get-Date -format  yyyy-MM-dd-HH:mm:ss)))};
      }; 
	  
  };
$Global:logArray += ("Backup of $server complete at: " + (Get-Date -format  yyyy-MM-dd-HH:mm:ss));
};            
# End Function ExecFullBackup

function local:ExecLogBackup($Server)
{
                  
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $Server; 

# Testing code, may be removed
#foreach ($db in $srv.Databases) {
# $db;
# }
# end testing code 
           
# If it can't connect and enumerate databases, fail and move on to the next instance.
#trap { $Global:failLogArray += "Could not connect to database $srv"; return } foreach ($db in $srv.Databases) {};

$Global:logArray += ("Started log backup of instance $srv at: " + (Get-Date -format yyyy-MM-dd-HH:mm:ss));

# Log backup for every database with Full recovery Model      
foreach ($db in $srv.Databases)            
{            
    If($db.Name -ne "TempDB")  # No need to backup TempDB            
    {            
        # For db with recovery mode <> simple: Log backup.            
        If ($db.RecoveryModel -ne 3)            
        {            
            $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;            
            $backup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup");            
            $backup.Action = "Log";            
            $backup.Database = $db.Name;
            $dbClean = $db -replace '\[' , '' -replace '\]' , '';
            $backupFolder= "$global:Dest\Log\$Server\$dbClean\"
            if (Test-Path $backupfolder) {
            } else {
            md $backupfolder;
            }         
            $backup.Devices.AddDevice($backupfolder + $db.Name + "_log_" + $timestamp + ".trn", "File");            
            $backup.BackupSetDescription = "Log backup of " + $db.Name + " " + $timestamp;            
            #Specify that the log must be truncated after the backup is complete.            
            $backup.LogTruncation = "Truncate";
            # Starting log backup process            
            $backup.SqlBackup($srv);
			#Enable the next line for debugging
			#$error[0] | format-list -force;
            if ($?) {
            if ($verbose) {$Global:logArray += ("Log Backup of $dbClean Successful.")};
            } else {
            $Global:faillogArray += "!--> Log Backup of $server : $dbClean Failed!";
            };          
        };            
    };            
};            

$Global:logArray += "`n";
$Global:logArray += ("Finished at: " + (Get-Date -format  yyyy-MM-dd-HH:mm:ss));

}
# End function ExecLogBackup

# Parse Config File and call Backup Functions
function ParseConfig($InstanceList) {

  foreach ($instance in $InstanceList) {
    #Comments and Blank Lines are legal and ignored
    if (($instance -Match '^\s*#') -or ($instance -Match '^\s*$'))
    {
        continue;
    }
    # Numbers, letters, backslashes, underscores, and dashes are legal
    if ($instance -Notmatch '^[A-Za-z0-9\\_-]*$')
    {
        throw write-host "The instance name $instance is illegal.  Please check it and try again.";
    }
    if($FullBackup) {
        ExecFullBackup($instance);
     } elseif($LogBackup) {
        ExecLogBackup($instance);
    }    
  }
}
# End Function ParseConfig

#############################################
# Excludes Function is not yet operational
# As of v.1
#############################################
function Excludes($ExcludeList) {
   $Global:ExcludeArray = @();  
  foreach ($instance in $ExcludeList) {
    #Comments and Blank Lines are legal and ignored
    if (($instance -Match '^\s*#') -or ($instance -Match '^\s*$'))
    {
        continue;
    }
    # Numbers, letters, backslashes, underscores, and dashes are legal
	# 
    if ($instance -Notmatch '^[A-Za-z0-9\\_-]*')
    {
        throw write-host "The instance name $instance in the exclude config file is illegal.  Please check it and try again.";
	}
	# Generate a multidimensional array of instances and dbs to exclude
	# By Splitting each instance/db pair on whitespace
	
	$instance = [regex]::Split($instance, "\s");
	if ($instance.Length -ne 2) {
		throw write-host "The entry $instance in the Exclude list is illegal.  The entry must be formatted as HOSTNAME\Instancename databasename"
		}
	$Global:ExcludeArray += ,@($instance);
	}
	#foreach ($line in $Global:ExcludeArray)
	#{
	#  Write-host ($line);
    #}
}	# End Function Excludes

function NotifyEmail($subject) {

# Moved this to config file.
# $from = "$($env:UserName)@smsholdings.com";
$email = New-Object System.Net.Mail.MailMessage;

foreach ($mailTo in $global:to) {
    $email.To.Add($mailTo)
    }

$email.From = $Global.from;
$email.Subject = $subject;


foreach ($line in $GLOBAL:faillogArray) {
 $email.Body += $line;
 $email.Body += "`n";
}
$email.Body += "`n#########################################`n`n"
foreach ($line in $Global:logArray) {
 $email.Body += $line;
 $email.Body += "`n";
}

# Deliver the email
if ($verbose) {$email};
if ($verbose) {write-Output "Delivering notification via $global:smtpHost"};
$client = New-Object System.Net.Mail.SmtpClient $global:smtpHost;
$client.UseDefaultCredentials = $true;
$client.Send($email);

}
# End function NotifyEmail


function TallyUp {
if ($Global:faillogArray.Count -gt 0) {
      $failCount = $Global:faillogArray.Length;
      write-output "Total Failures: $failCount";
      write-output (($Global:faillogArray) | foreach {$_});
      $subject = "SQL Backup Run failed on $failCount databases";
     } else {
      $subject = "SQL Backup Run was successful with 0 failures.";
     }
Write-Output $subject;
if ($verbose) {write-output $Global:logArray};
if ($NotifyByEmail) {NotifyEmail "$subject"};  
}   
# End Function Tallyup

# Here's where we actually run something (finally;-)
if ($InstanceFile) {
    if (test-path $InstanceFile) {
	$InstanceList = Get-Content $InstanceFile;
	ParseConfig($InstanceList);  # Parse the configfile and execute the backups
    TallyUp; # Total up failures, create final status and trigger email notification if any.
    } else {
	$Global:faillogArray += "I wasn't able to find $InstanceFile - Please check the filename.";
	TallyUp;
	}
    } else {
	Help; # I don't know what to do!
};

     
   

 
