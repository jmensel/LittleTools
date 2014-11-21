# EventLogPuller
# John Mensel
# jmensel@gmail.com
# This is a simple script designed to quickly pull
# errors out of Windows Event Logs for fast, efficient review.

$logdir = 'c:\EventLogs_Temp\'
$date = get-Date
$today=$date.Day
$filename="$logdir\EventLog-${today}.txt"

# Make sure that we've got a place to put stuff

Test-Path $logdir > $null
if ($?) {
    mkdir $logdir 2>&1 > $null
}

# If we're low on space (under 500MB), cancel the job

$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" 

if ($disk.FreeSpace -lt 500000000) {
    throw "C: on this server is low on disk space, aborting"
}

function GetLog2008 {

    Get-WinEvent -ListLog * -EA silentlycontinue | where-object { $_.recordcount -AND $_.lastwritetime -gt [datetime]::today} | Foreach-Object { get-winevent -LogName $_.logname -MaxEvents 1 } | Format-Table TimeCreated, ID, ProviderName, Message -AutoSize –Wrap | out-File "$filename"

} # End Function GetLog2008

function GetLog2003 {
    
    Get-Eventlog application -Newest 2000 | where {$_.entryType -Match "Error"} | Format-Table TimeGenerated, Source, Message -AutoSize –Wrap | Out-File "${logdir}${today}-application.txt"
    Get-Eventlog system -Newest 2000 | where {$_.entryType -Match "Error"} | Format-Table TimeGenerated, Source, Message -AutoSize –Wrap | Out-File "${logdir}${today}-system.txt"
    Get-Eventlog security -newest 100 | where {$_.entrytype -eq "FailureAudit"} | Format-Table TimeGenerated, InstanceID, Message -AutoSize –Wrap | Out-File "${logdir}${today}-security.txt"
    
} # EndFunction GetLog2003

function DetectOS {

    $os = Get-WmiObject Win32_OperatingSystem
    $build = $os.Version

    if ($os.Version -ge 6) {
        GetLog2008
    }
    elseif ($os.Version -ge 5) {
        GetLog2003
    }
    elseif ($os.Version -lt 5) {
        throw "This thing can't even run a powershell.  What on earth are you up to?"
    }
       
} # END FUNCTION Detect OS            

# 

# Figure out what we're running on - the Get-WinEvent cmdlet is unavailable on Win2k3
DetectOS


    