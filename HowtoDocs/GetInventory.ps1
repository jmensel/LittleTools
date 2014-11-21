# Created: 4.11.2013
# Original Author : Peter Stone
# Revised by JHM, CTI, to include authentication and active directory integration
#########################################################################################################


Function WMILookup{
}

Function WMILookupCred {
# GET THE DATE/TIMEC
# Ensure the the date is formated to NZ Date Standard (Powershell tends to do the American format...)
$strDate = get-date –f "dd/MM/yyyy HH:mm:ss"

# Get the values for the local host...
# $strComputer = "."
foreach ($strComputer in $colComputers){

if (! $strComputer) {
	continue
}

# If the ping check fails, move along to the next host
write-output "Running a ping check on $strComputer"

if(!(Test-Connection -Cn $strComputer -BufferSize 16 -Count 1 -ea 0 -quiet))
{
	write-output "Host $strComputer is not pingable"
	write-output "Nslookup follows:"
	$dns = [System.Net.Dns]::GetHostAddresses("$strComputer")
	write-output $dns.IPAddressToString
	continue
}

write-output "Collecting data for host $strComputer"

# Assign the contents of a WMI class and namespace to an array (collection)
$colItems = get-wmiobject -Credential $cred -class "Win32_Processor" -namespace "root\CIMV2" -computername $strComputer -ErrorVariable err | sort-object -descending "WorkingSetSize"

write-output "Col Items: $colItems"

if (! $colItems) {
	write-output "$strComputer: Call to get-wmiobject call returned no result."
	continue
}

# If the WMI action fails, move along
#if ($err) {
#write-output "$strComputer was unavailable, moving along."
#}
#return

# EXTRACT THE HOSTNAME (before getting the rest of the data)
# (Will revisit this namespace later in the script to get other values...)
$cnt = 0
foreach ($objItem in $colItems) {
	# Each line in this array represents the data returned for each processor
	# even if the processor is threaded and more than one line is returned,
	# the comparison and $cnt variable limit the output to one row per workstation. 
	if ($cnt -eq 0) {
		$strHostName = $objItem.SystemName
	}
	$cnt++
}

# ASSIGN FILE PATH TO THE OUTPUT FILE (using the Hostname)
# $htmlFilePath = "C:\" + $strHostName + ".html"
$htmlFilePath = $strHostName + ".html"
 	
# Write to screen
write-output "System Name: " $strHostName
write-output "Data collected: " $strDate

# Create and write HTML to file
$strOutputString = "<p><font size=3>"	# Initalise the file by writing the first line 									
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii	# (NOTE: Not using the -append argument)

$strOutputString = "Host: <font size=4 color=darkblue><strong>" + $strHostName + "</strong></font><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
$strOutputString = "Date: <strong>" + $strdate + "</strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "</font></p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

# HARVEST THE DATA
#########################################################################################################
# Write Subtitle to screen

write-output "Chassis Information . . ." -foregroundcolor "magenta"

# Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>Computer Chassis Information: </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<font size=3>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$colItems = get-wmiobject -class "Win32_SystemEnclosure" -namespace "root\CIMV2" -computername $strComputer

foreach ($objItem in $colItems) {
	# Write to screen
	write-output "Manufacturer: " $objItem.Manufacturer
	write-output "Serial Number: " $objItem.SerialNumber
	#write-output "SMBIOS Asset Tag: " $objItem.SMBIOSAssetTag

	
	# Create HTML Output 
	$strOutPut01 = "Manufacturer: <strong>" + $objItem.Manufacturer + "</strong><br>"
	$strOutPut02 = "Serial Number: <strong>" + $objItem.SerialNumber + "</strong><br>"       
	#$strOutPut03 = "SMBIOS Asset Tag: <strong>" + $objItem.SMBIOSAssetTag + "</strong><br>"              
	
	# Write HTML to File    	
	$strOutPut01 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut02 | out-file -filepath $htmlFilePath -encoding ascii -append
	#$strOutPut03 | out-file -filepath $htmlFilePath -encoding ascii -append
}
$strOutputString = "</font></p>"
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append

#########################################################################################################
#########################################################################################################
# Write Subtitle to screen

write-output "Network Adapter Configuration Properties . . ." -foregroundcolor "magenta"

# Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>Network Adapter Configuration Properties: </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<font size=3>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$colItems = get-wmiobject -Credential $cred -class "Win32_NetworkAdapterConfiguration" -namespace "root\CIMV2" -computername $strComputer

foreach ($objItem in $colItems) {
	# A test is needed here as the loop will find a number of virtual network configurations with no  "Hostname" 
	# So if the "Hostname" does not exist, do NOT display it!
	if ($objItem.DNSHostName -ne $NULL) {
		# Write to screen
		# write-output "Caption: " $objItem.Caption
		write-output "Default IP Gateway: " $objItem.DefaultIPGateway
		write-output "Description: " $objItem.Description
		write-output "DHCP Enabled: " $objItem.DHCPEnabled
		write-output "DHCP Lease Expires: " $objItem.DHCPLeaseExpires
		write-output "DHCP Lease Obtained: " $objItem.DHCPLeaseObtained
		write-output "DHCP Server: " $objItem.DHCPServer
		write-output "DNS Domain: " $objItem.DNSDomain
		write-output "DNS Domain Suffix Search Order: " $objItem.DNSDomainSuffixSearchOrder
		write-output "DNS Enabled For WINS Resolution: " $objItem.DNSEnabledForWINSResolution
		write-output "DNS Host Name: " $objItem.DNSHostName
		write-output "DNS Server Search Order: " $objItem.DNSServerSearchOrder
		write-output "Domain DNS Registration Enabled: " $objItem.DomainDNSRegistrationEnabled
		#write-output "Forward Buffer Memory: " $objItem.ForwardBufferMemory
		write-output "Full DNS Registration Enabled: " $objItem.FullDNSRegistrationEnabled
		#write-output "Index: " $objItem.Index
		write-output "IP Address: " $objItem.IPAddress
		write-output "MAC Address: " $objItem.MACAddress
		write-output "WINS Enable LMHosts Lookup: " $objItem.WINSEnableLMHostsLookup
		#write-output "WINS Host Lookup File: " $objItem.WINSHostLookupFile
		write-output "WINS Primary Server: " $objItem.WINSPrimaryServer
		#write-output "WINS Scope ID: " $objItem.WINSScopeID
		write-output "WINS Secondary Server: " $objItem.WINSSecondaryServer

		
		$ipaddress = $objItem.IPAddress
		
		# Create HTML Output 
		#$strOutPut01 = "Caption: <strong>" + $objItem.Caption + "</strong><br>"                                             
		$strOutPut02 = "Default IP Gateway: <strong>" + $objItem.DefaultIPGateway + "</strong><br>"                         
		$strOutPut03 = "Description: <strong>" + $objItem.Description + "</strong><br>"                                     
		$strOutPut04 = "DHCP Enabled: <strong>" + $objItem.DHCPEnabled + "</strong><br>"                                    
		$strOutPut05 = "DHCP Lease Expires: <strong>" + $objItem.DHCPLeaseExpires + "</strong><br>"                         
		$strOutPut06 = "DHCP Lease Obtained: <strong>" + $objItem.DHCPLeaseObtained + "</strong><br>"                       
		$strOutPut07 = "DHCP Server: <strong>" + $objItem.DHCPServer + "</strong><br>"                                      
		$strOutPut08 = "DNS Domain: <strong>" + $objItem.DNSDomain + "</strong><br>"                                        
		$strOutPut09 = "DNS Domain Suffix Search Order: <strong>" + $objItem.DNSDomainSuffixSearchOrder + "</strong><br>"   
		$strOutPut10 = "DNS Enabled For WINS Resolution: <strong>" + $objItem.DNSEnabledForWINSResolution + "</strong><br>" 
		$strOutPut11 = "DNS Host Name: <strong>" + $objItem.DNSHostName + "</strong><br>"                                   
		$strOutPut12 = "DNS Server Search Order: <strong>" + $objItem.DNSServerSearchOrder + "</strong><br>"                
		$strOutPut13 = "Domain DNS Registration Enabled: <strong>" + $objItem.DomainDNSRegistrationEnabled + "</strong><br>"
		#$strOutPut14 = "Forward Buffer Memory: <strong>" + $objItem.ForwardBufferMemory + "</strong><br>"                   
		$strOutPut15 = "Full DNS Registration Enabled: <strong>" + $objItem.FullDNSRegistrationEnabled + "</strong><br>"    
		#$strOutPut16 = "Index: <strong>" + $objItem.Index + "</strong><br>"                                                 
		$strOutPut17 = "IP Address: <strong>" + $objItem.IPAddress + "</strong><br>"                                        
		$strOutPut18 = "MAC Address: <strong>" + $objItem.MACAddress + "</strong><br>"                                      
		$strOutPut19 = "WINS Enable LMHosts Lookup: <strong>" + $objItem.WINSEnableLMHostsLookup + "</strong><br>"          
		#$strOutPut20 = "WINS Host Lookup File: <strong>" + $objItem.WINSHostLookupFile + "</strong><br>"                    
		$strOutPut21 = "WINS Primary Server: <strong>" + $objItem.WINSPrimaryServer + "</strong><br>"                       
		#$strOutPut22 = "WINS Scope ID: <strong>" + $objItem.WINSScopeID + "</strong><br>"                                   
		$strOutPut23 = "WINS Secondary Server: <strong>" + $objItem.WINSSecondaryServer + "</strong><br>"                   
		
		# Write HTML to File    	
		#$strOutPut01 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut02 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut03 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut04 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut05 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut06 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut07 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut08 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut09 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut10 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut11 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut12 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut13 | out-file -filepath $htmlFilePath -encoding ascii -append
		#$strOutPut14 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut15 | out-file -filepath $htmlFilePath -encoding ascii -append
		#$strOutPut16 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut17 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut18 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut19 | out-file -filepath $htmlFilePath -encoding ascii -append
		#$strOutPut20 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut21 | out-file -filepath $htmlFilePath -encoding ascii -append
		#$strOutPut22 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut23 | out-file -filepath $htmlFilePath -encoding ascii -append
	}
}
$strOutputString = "</font></p>"
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append

#########################################################################################################
#########################################################################################################
# Write Subtitle to screen

write-output "CPU Data . . ." -foregroundcolor "magenta"

# Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>Processor Details: </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<font size=3>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$colItems = get-wmiobject -Credential $cred -class "Win32_Processor" -namespace "root\CIMV2" -computername $strComputer

$cnt = 0
foreach ($objItem in $colItems) {
	# Each line in this array represents the data returned for each processor
	# even if the processor is threaded and more than one line is returned,
	# the comparison and $cnt variable limit the output to one row per workstation. 
	if ($cnt -eq 0) {
		
		# Write to screen
		write-output "Current Clock Speed: " $objItem.CurrentClockSpeed "MHz or [" ($objItem.CurrentClockSpeed/1000)"GHz ]"
		write-output "Current Voltage: " $objItem.CurrentVoltage
		write-output "Description: " $objItem.Description
		write-output "Manufacturer: " $objItem.Manufacturer
		write-output "Maximum Clock Speed: " $objItem.MaxClockSpeed "MHz or [" ($objItem.MaxClockSpeed/1000)"GHz ]"
		write-output "Name: " $objItem.Name
		write-output "Processor ID: " $objItem.ProcessorId
		write-output "Role: " $objItem.Role
		write-output "Socket Designation: " $objItem.SocketDesignation

		
		# Create HTML Output 
		$strOutPut01 = "Current Clock Speed: <strong>" + $objItem.CurrentClockSpeed + "MHz <font color=#6699cc>(" + ($objItem.CurrentClockSpeed/1000) +"GHz)</font></strong><br>"
		$strOutPut02 = "Current Voltage: <strong>" + $objItem.CurrentVoltage + "</strong><br>"       
		$strOutPut03 = "Description: <strong>" + $objItem.Description + "</strong><br>"              
		$strOutPut04 = "Manufacturer: <strong>" + $objItem.Manufacturer + "</strong><br>"            
		$strOutPut05 = "Maximum Clock Speed: <strong>" + $objItem.MaxClockSpeed + "MHz <font color=#6699cc>(" + ($objItem.MaxClockSpeed/1000) +"GHz)</font></strong><br>"    
		$strOutPut06 = "Name: <strong>" + $objItem.Name + "</strong><br>"                         
		$strOutPut07 = "Processor ID: <strong>" + $objItem.ProcessorId + "</strong><br>"             
		$strOutPut08 = "Role: <strong>" + $objItem.Domain + "</strong><br>"                          
		$strOutPut09 = "Socket Designation: <strong>" + $objItem.SocketDesignation + "</strong><br>" 
		   	
		# Write HTML to File    	
		$strOutPut01 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut02 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut03 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut04 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut05 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut06 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut07 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut08 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut09 | out-file -filepath $htmlFilePath -encoding ascii -append
	}
	$cnt++
}
$strOutputString = "</font></p>"
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append

########################################################################################################
##############################################################################################################
# Write Subtitle to screen

write-output "Basic Computer Information . . ." -foregroundcolor "magenta"

# Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>Workstation Details: </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<font size=3>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$colItems = get-wmiobject -Credential $cred -class "Win32_ComputerSystem" -namespace "root\CIMV2" -computername $strComputer

foreach ($objItem in $colItems) {
	#Output to screen
	write-output "Automatic Reset Boot Option: " $objItem.AutomaticResetBootOption
	write-output "Automatic Reset Capability: " $objItem.AutomaticResetCapability
	write-output "Boot ROM Supported: " $objItem.BootROMSupported
	write-output "Bootup State: " $objItem.BootupState
	#write-output "Creation Class Name: " $objItem.CreationClassName
	write-output "Daylight In Effect: " $objItem.DaylightInEffect
	write-output "Description: " $objItem.Description
	write-output "Domain: " $objItem.Domain
	write-output "Enable Daylight Savings Time: " $objItem.EnableDaylightSavingsTime
	write-output "Infrared Supported: " $objItem.InfraredSupported
	write-output "Installation Date: " $objItem.InstallDate
	write-output "Last Load Information: " $objItem.LastLoadInfo
	write-output "Manufacturer: " $objItem.Manufacturer
	write-output "Model: " $objItem.Model
	write-output "Network Server Mode Enabled: " $objItem.NetworkServerModeEnabled
	write-output "Number Of Processors: " $objItem.NumberOfProcessors
	write-output "Part Of Domain: " $objItem.PartOfDomain
	write-output "Roles: " $objItem.Roles
	write-output "System Startup Delay: " $objItem.SystemStartupDelay
	write-output "System Startup Options: " $objItem.SystemStartupOptions
	write-output "System Type: " $objItem.SystemType
	write-output "Total Physical Memory: " $objItem.TotalPhysicalMemory
	write-output "Username Logged On: " $objItem.UserName

	   
	# Create HTML Output 
	$strOutPut01 = "Automatic Reset Boot Option: <strong>" + $objItem.AutomaticResetBootOption + "</strong><br>"
	$strOutPut02 = "Automatic Reset Capability: <strong>" + $objItem.AutomaticResetCapability + "</strong><br>"
	$strOutPut03 = "Boot ROM Supported: <strong>" + $objItem.BootROMSupported + "</strong><br>"
	$strOutPut04 = "Bootup State: <strong>" + $objItem.BootupState + "</strong><br>"
	#$strOutPut05 = "Creation Class Name: <strong>" + $objItem.CreationClassName + "</strong><br>"
	$strOutPut06 = "Daylight In Effect: <strong>" + $objItem.DaylightInEffect + "</strong><br>"
	$strOutPut07 = "Description: <strong>" + $objItem.Description + "</strong><br>"
	$strOutPut08 = "Domain: <strong>" + $objItem.Domain + "</strong><br>"
	$strOutPut09 = "Enable Daylight Savings Time: <strong>" + $objItem.EnableDaylightSavingsTime + "</strong><br>"
	$strOutPut10 = "Infrared Supported: <strong>" + $objItem.InfraredSupported + "</strong><br>"
	$strOutPut11 = "Installation Date: <strong>" + $objItem.InstallDate + "</strong><br>"
	$strOutPut12 = "Last Load Information: <strong>" + $objItem.LastLoadInfo + "</strong><br>"
	$strOutPut13 = "Manufacturer: <strong>" + $objItem.Manufacturer + "</strong><br>"
	$strOutPut14 = "Model: <strong>" + $objItem.Model + "</strong><br>"
	$strOutPut15 = "Network Server Mode Enabled: <strong>" + $objItem.NetworkServerModeEnabled + "</strong><br>"
	$strOutPut16 = "Number Of Processors: <strong>" + $objItem.NumberOfProcessors + "</strong><br>"
	$strOutPut17 = "Part Of Domain: <strong>" + $objItem.PartOfDomain + "</strong><br>"
	$strOutPut18 = "Roles: <strong>" + $objItem.Roles + "</strong><br>"
	$strOutPut19 = "System Startup Delay: <strong>" + $objItem.SystemStartupDelay + "</strong><br>"
	$strOutPut20 = "System Startup Options: <strong>" + $objItem.SystemStartupOptions + "</strong><br>"
	$strOutPut21 = "System Type: <strong>" + $objItem.SystemType + "</strong><br>"
	
	# Improve the display of the higher order values of MB and GB 
	$displayMB = [math]::round($objItem.TotalPhysicalMemory/1024/1024, 2)
	$displayGB = [math]::round($objItem.TotalPhysicalMemory/1024/1024/1024, 2)
	
	$strOutPut22 = "Total Physical Memory: <strong>" + $objItem.TotalPhysicalMemory + " Bytes <font color=#6699cc>(" + $displayMB + "MB) or (" + $displayGB + "GB)</font></strong><br>"
	$strOutPut23 = "Username Logged On: <strong>" + $objItem.UserName + "</strong><br>"
	      	
	# Write HTML to File    	
	$strOutPut01 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut02 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut03 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut04 | out-file -filepath $htmlFilePath -encoding ascii -append
	#$strOutPut05 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut06 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut07 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut08 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut09 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut10 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut11 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut12 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut13 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut14 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut15 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut16 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut17 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut18 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut19 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut20 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut21 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut22 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut23 | out-file -filepath $htmlFilePath -encoding ascii -append
	}
$strOutputString = "</font></p>"
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append

#########################################################################################################
#########################################################################################################
# Write Subtitle to screen

write-output "Hard Drive Information . . ." -foregroundcolor "magenta"

# Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>Hard Drive Information: </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<font size=3>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

# Get the variables form the c that will be needed
$colItems = get-wmiobject -Credential $cred -class "Win32_DiskDrive" -namespace "root\CIMV2" -computername $strComputer

# Insert a subheading for physial drive data
$strOutputString = "<strong><font size=3 color=#6699cc>Physical Drive(s): </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
foreach ($objItem in $colItems) {
	# Write to screen
	write-output "Caption: " $objItem.Caption
	write-output "Size: " $objItem.Size
	write-output "Physical Drive: " $objItem.Name
	write-output "Manufacturer: " $objItem.Manufacturer

		
	# Improve the display of the higher order values of MB and GB 
	$displayMB = [math]::round($objItem.Size/1024/1024, 2)
	$displayGB = [math]::round($objItem.Size/1024/1024/1024, 2)
	
	$strOutPut01 = "Caption: <strong>" + $objItem.Caption + "</strong><br>"           
	$strOutPut02 = "Details: <strong>" + $objItem.Name + " <font color=#6699cc>(" + $displayGB + " GB)</font></strong><br>"           
	#$strOutPut03 = "Manufacturer: <strong>" + $objItem.Manufacturer + "</strong><br>" 		
	#$strOutPut04 = "Size: <strong> "+ $displayGB + " GB</strong><br>"
	
	# Write HTML to File    	
	$strOutPut01 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut02 | out-file -filepath $htmlFilePath -encoding ascii -append
	#$strOutPut03 | out-file -filepath $htmlFilePath -encoding ascii -append
	#$strOutPut04 | out-file -filepath $htmlFilePath -encoding ascii -append
}

#########################################################################################################
# Get the values for the drive(s) from the "Win32_LogicalDisk" class
$colItems = get-wmiobject -Credential $cred -class "Win32_LogicalDisk" -namespace "root\CIMV2" -computername $strComputer

# Insert a subheading for physial drive data
$strOutputString = "<strong><font size=3 color=#6699cc>Logical Drive(s): </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
foreach ($objItem in $colItems) {
	# Hard Disks are of the "$objItem.DriveType" value of 3	
	if ($objItem.DriveType -eq 3){
		# Write to screen
		#write-output "Drive Type: " $objItem.DriveType
		write-output "Name: " $objItem.Name
		write-output "FileSystem: " $objItem.FileSystem
		write-output "VolumeSerialNumber: " $objItem.VolumeSerialNumber
		write-output "Size: " $objItem.Size
		write-output "FreeSpace: " $objItem.FreeSpace

			
		# Create HTML Output 
		$strOutPut01 = "<font color=#6699cc>Drive: <strong>" + $objItem.Name + "</strong></font><br>"
			
		# Improve the display of the higher order values of MB and GB 
		$displayMB = [math]::round($objItem.Size/1024/1024, 2)
		$displayGB = [math]::round($objItem.Size/1024/1024/1024, 2)
	
		$strOutPut02 = "Drive Size: <strong>"+ $objItem.Name +"\ "+ $displayGB + " GB</strong><br>"

		# Improve the display of the higher order values of MB and GB 
		$displayMB = [math]::round($objItem.FreeSpace/1024/1024, 2)
		$displayGB = [math]::round($objItem.FreeSpace/1024/1024/1024, 2)
	
		$strOutPut03 = "Free Space: <strong>"+ $objItem.Name +"\ "+ $displayGB + " GB</strong><br>"
		$strOutPut04 = "File System: <strong>" + $objItem.FileSystem + "</strong><br>"             
		$strOutPut05 = "Volume Serial Number: <strong>" + $objItem.VolumeSerialNumber + "</strong><br>"
		
		# Write HTML to File    	
		$strOutPut01 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut02 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut03 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut04 | out-file -filepath $htmlFilePath -encoding ascii -append
		$strOutPut05 | out-file -filepath $htmlFilePath -encoding ascii -append
	}
}
$strOutputString = "</font></p>"
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append

#########################################################################################################
#########################################################################################################
# Write Subtitle to screen

write-output "Desktop Monitor Properties . . ." -foregroundcolor "magenta"

# Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>Desktop Monitor Properties: </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<font size=3>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$colItems = get-wmiobject -Credential $cred -class "Win32_DesktopMonitor" -namespace "root\CIMV2" -computername $strComputer

foreach ($objItem in $colItems) {
	#output to screen
	write-output "Description: " $objItem.Description
	write-output "Device ID: " $objItem.DeviceID
	write-output "Display Type: " $objItem.DisplayType
	write-output "Monitor Manufacturer: " $objItem.MonitorManufacturer
	write-output "Monitor Type: " $objItem.MonitorType
	write-output "Name: " $objItem.Name
	#write-output "Pixels Per X Logical Inch: " $objItem.PixelsPerXLogicalInch
	#write-output "Pixels Per Y Logical Inch: " $objItem.PixelsPerYLogicalInch
	write-output "PNP Device ID: " $objItem.PNPDeviceID
	write-output "Screen Height: " $objItem.ScreenHeight
	write-output "Screen Width: " $objItem.ScreenWidth

	   
	# Create HTML Output 
	$strOutPut01 = "Description: <strong>" + $objItem.Description + "</strong><br>"
	$strOutPut02 = "Device ID: <strong>" + $objItem.DeviceID + "</strong><br>"
	$strOutPut03 = "Display Type: <strong>" + $objItem.DisplayType + "</strong><br>"
	$strOutPut04 = "Monitor Manufacturer: <strong>" + $objItem.MonitorManufacturer + "</strong><br>"
	$strOutPut05 = "Monitor Type: <strong>" + $objItem.MonitorType + "</strong><br>"
	$strOutPut06 = "Name: <strong>" + $objItem.Name + "</strong><br>"
	#$strOutPut07 = "Pixels Per X Logical Inch: <strong>" + $objItem.PixelsPerXLogicalInch + "</strong><br>"
	#$strOutPut08 = "Pixels Per Y Logical Inch: <strong>" + $objItem.PixelsPerYLogicalInch + "</strong><br>"
	$strOutPut09 = "PNP Device ID: <strong>" + $objItem.PNPDeviceID + "</strong><br>"
	$strOutPut10 = "Screen Height: <strong>" + $objItem.ScreenHeight + "</strong><br>"
	$strOutPut11 = "Screen Width: <strong>" + $objItem.ScreenWidth + "</strong><br>"
	        	
	# Write HTML to File    	
	$strOutPut01 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut02 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut03 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut04 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut05 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut06 | out-file -filepath $htmlFilePath -encoding ascii -append
	#$strOutPut07 | out-file -filepath $htmlFilePath -encoding ascii -append
	#$strOutPut08 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut09 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut10 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut11 | out-file -filepath $htmlFilePath -encoding ascii -append
}
$strOutputString = "</font></p>"
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append

#########################################################################################################
#########################################################################################################
# Write Subtitle to screen

write-output "Operating System Properties . . ." -foregroundcolor "magenta"

# Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>Operating System Properties: </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<font size=3>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$colItems = get-wmiobject -Credential $cred -class "Win32_OperatingSystem" -namespace "root\CIMV2" -computername $strComputer

foreach ($objItem in $colItems) {
	# Output to screen
	write-output "Build Number: " $objItem.BuildNumber
	write-output "Build Type: " $objItem.BuildType
	write-output "Caption: " $objItem.Caption
	write-output "CSD Version: " $objItem.CSDVersion
	write-output "Free Physical Memory: " $objItem.FreePhysicalMemory
	write-output "Free Space In Paging Files: " $objItem.FreeSpaceInPagingFiles
	write-output "Free Virtual Memory: " $objItem.FreeVirtualMemory
	# Convert the install date string to a "real" date variable  and ensure the date is formated to NZ Date Standard (Powershell tends to do the American format...)
	$installdate = $colItems.ConvertToDateTime($objItem.InstallDate) | get-date  –f "dd/MM/yyyy HH:mm:ss" 
	write-output "Installation Date: " $installdate	
	# Convert the Last Boot-Up Time string to a "real" date/time variable and ensure the date is formated to NZ Date Standard (Powershell tends to do the American format...)
	$lastbootuptime = $colItems.ConvertToDateTime($colItems.LocalDateTime) | get-date  –f "dd/MM/yyyy HH:mm:ss"	
	write-output "Last Boot-Up Time: " $lastbootuptime
	write-output "Manufacturer: " $objItem.Manufacturer
	#write-output "Number Of Users: " $objItem.NumberOfUsers
	write-output "Organization: " $objItem.Organization
	write-output "Operating System Language: " $objItem.OSLanguage
	write-output "Primary: " $objItem.Primary
	write-output "Registered User: " $objItem.RegisteredUser
	write-output "Serial Number: " $objItem.SerialNumber
	write-output "Service Pack Major Version: " $objItem.ServicePackMajorVersion
	write-output "Service Pack Minor Version: " $objItem.ServicePackMinorVersion
	write-output "System Directory: " $objItem.SystemDirectory
	write-output "System Drive: " $objItem.SystemDrive
	write-output "Total Swap Space Size: " $objItem.TotalSwapSpaceSize
	write-output "Total Virtual Memory Size: " $objItem.TotalVirtualMemorySize
	write-output "Total Visible Memory Size: " $objItem.TotalVisibleMemorySize
	write-output "Version: " $objItem.Version
	write-output "Windows Directory: " $objItem.WindowsDirectory

	
	# Create HTML Output 
	$strOutPut01 = "Build Number: <strong>" + $objItem.BuildNumber + "</strong><br>"
	$strOutPut02 = "Build Type: <strong>" + $objItem.BuildType + "</strong><br>"
	$strOutPut03 = "Caption: <strong>" + $objItem.Caption + "</strong><br>"
	$strOutPut04 = "CSD Version: <strong>" + $objItem.CSDVersion + "</strong><br>"
	
	# Improve the display of the higher order values of MB and GB 
	$displayMB = [math]::round($objItem.FreePhysicalMemory/1024, 2)
	$displayGB = [math]::round($objItem.FreePhysicalMemory/1024/1024, 2)
	
	$strOutPut05 = "Free Physical Memory: <strong>" + $objItem.FreePhysicalMemory + " KB <font color=#6699cc>(" + $displayMB + "MB)(" + $displayGB + "GB)</font></strong><br>"
	
	# Improve the display of the higher order values of MB and GB 
	$displayGB = [math]::round($objItem.FreeSpaceInPagingFiles/1024/1024, 2)
	
	$strOutPut06 = "Free Space In Paging Files: <strong>" + $objItem.FreeSpaceInPagingFiles + " KB <font color=#6699cc>(" + $displayGB + "GB)</font></strong><br>"
	
	# Improve the display of the higher order values of MB and GB 
	$displayGB = [math]::round($objItem.FreeVirtualMemory/1024/1024, 2)
	
	$strOutPut07 = "Free Virtual Memory: <strong>" + $objItem.FreeVirtualMemory + " KB <font color=#6699cc>(" + $displayGB + "GB)</font></strong><br>"
#	$strOutPut08 = "Installation Date: <strong>" + $objItem.InstallDate + "</strong><br>"
	$strOutPut08 = "Installation Date: <strong>" + $installdate + "</strong><br>"
#	$strOutPut09 = "Last Boot-Up Time: <strong>" + $objItem.LastBootUpTime + "</strong><br>"
	$strOutPut09 = "Last Boot-Up Time: <strong>" + $lastbootuptime + "</strong><br>"
	$strOutPut10 = "Manufacturer: <strong>" + $objItem.Manufacturer + "</strong><br>"
	#$strOutPut11 = "Number Of Users: <strong>" + $objItem.NumberOfUsers + "</strong><br>"
	$strOutPut12 = "Organization: <strong>" + $objItem.Organization + "</strong><br>"
	$strOutPut13 = "Operating System Language: <strong>" + $objItem.OSLanguage + "</strong><br>"
	$strOutPut14 = "Primary: <strong>" + $objItem.Primary + "</strong><br>"
	$strOutPut15 = "Registered User: <strong>" + $objItem.RegisteredUser + "</strong><br>"
	$strOutPut16 = "Serial Number: <strong>" + $objItem.SerialNumber + "</strong><br>"
	$strOutPut17 = "Service Pack Major Version: <strong>" + $objItem.ServicePackMajorVersion + "</strong><br>"
	$strOutPut18 = "Service Pack Minor Version: <strong>" + $objItem.ServicePackMinorVersion + "</strong><br>"
	$strOutPut19 = "System Directory: <strong>" + $objItem.SystemDirectory + "</strong><br>"
	$strOutPut20 = "System Drive: <strong>" + $objItem.SystemDrive + "</strong><br>"
	$strOutPut21 = "Total Swap Space Size: <strong>" + $objItem.TotalSwapSpaceSize + "</strong><br>"

	# Improve the display of the higher order values of MB and GB 
	$displayGB = [math]::round($objItem.TotalVirtualMemorySize/1024/1024, 2)
	
	$strOutPut22 = "Total Virtual Memory Size: <strong>" + $objItem.TotalVirtualMemorySize + " KB <font color=#6699cc>(" + $displayGB + "GB)</font></strong><br>"

	# Improve the display of the higher order values of MB and GB 
	$displayGB = [math]::round($objItem.TotalVisibleMemorySize/1024/1024, 2)
	
	$strOutPut23 = "Total Visible Memory Size: <strong>" + $objItem.TotalVisibleMemorySize + " KB <font color=#6699cc>(" + $displayGB + "GB)</font></strong><br>"
	$strOutPut24 = "Version: <strong>" + $objItem.Version + "</strong><br>"
	$strOutPut25 = "Windows Directory: <strong>" + $objItem.WindowsDirectory + "</strong><br>"
	    	
	# Write HTML to File
	$strOutPut01 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut02 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut03 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut04 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut05 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut06 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut07 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut08 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut09 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut10 | out-file -filepath $htmlFilePath -encoding ascii -append
	#$strOutPut11 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut12 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut13 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut14 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut15 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut16 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut17 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut18 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut19 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut20 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut21 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut22 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut23 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut24 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut25 | out-file -filepath $htmlFilePath -encoding ascii -append
}
$strOutputString = "</font></p>"
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append

#########################################################################################################
#########################################################################################################
# Write Subtitle to screen

write-output "BIOS Information . . ." -foregroundcolor "magenta"

# Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>BIOS Information: </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<font size=3>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$colItems = get-wmiobject -Credential $cred -class "Win32_BIOS" -namespace "root\CIMV2" -computername $strComputer

foreach ($objItem in $colItems) {
	# write to screen
	write-output "BIOS Version: " $objItem.BIOSVersion
	write-output "Description: " $objItem.Description
	write-output "Manufacturer: " $objItem.Manufacturer
	write-output "Release Date: " $objItem.ReleaseDate
	write-output "Serial Number: " $objItem.SerialNumber

	
	# Create HTML Output 
	$strOutPut01 = "BIOS Version: <strong>" + $objItem.Description + "</strong><br>"
	$strOutPut02 = "Description: <strong>" + $objItem.DeviceID + "</strong><br>"
	$strOutPut03 = "Manufacturer: <strong>" + $objItem.DisplayType + "</strong><br>"
	$strOutPut04 = "Release Date: <strong>" + $objItem.MonitorManufacturer + "</strong><br>"
	$strOutPut05 = "Serial Number: <strong>" + $objItem.MonitorType + "</strong><br>"
	
	# Write HTML to File    	
	$strOutPut01 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut02 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut03 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut04 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut05 | out-file -filepath $htmlFilePath -encoding ascii -append
}
$strOutputString = "</font></p>"
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append

#########################################################################################################
#########################################################################################################
# Write Subtitle to screen

write-output "Loaded Printer Drivers . . ." -foregroundcolor "magenta"

# Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>Loaded Printer Drivers: </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<font size=3>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$colItems = get-wmiobject -Credential $cred -class "Win32_PrinterDriver" -namespace "root\CIMV2" -computername $strComputer

foreach ($objItem in $colItems) {
	# write to screen
    write-output "Name: " $objItem.Name
    write-output "Configuration File: " $objItem.ConfigFile
    write-output "Data File: " $objItem.DataFile
    write-output "Driver Path: " $objItem.DriverPath
    ##write-output "Creation Class Name: " $objItem.CreationClassName
    ##write-output "File Path: " $objItem.FilePath
    ##write-output "Supported Platform: " $objItem.SupportedPlatform
    ##write-output "System Creation Class Name: " $objItem.SystemCreationClassName

	
	# Create HTML Output 
	$strOutPut01 = "<font size=3>Name: <strong>" + $objItem.Name + "</strong></font><br>"
	$strOutPut02 = "<font size=1 color=#6699cc>Configuration File: <strong>" + $objItem.ConfigFile + "</strong></font><br>"
	$strOutPut03 = "<font size=1 color=#6699cc>Data File: <strong>" + $objItem.DataFile + "</strong></font><br>"
	$strOutPut04 = "<font size=1 color=#6699cc>Driver Path: <strong>" + $objItem.DriverPath + "</strong></font><br>"
	
	# Write HTML to File    	
	$strOutPut01 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut02 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut03 | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutPut04 | out-file -filepath $htmlFilePath -encoding ascii -append
}
$strOutputString = "</font></p>"
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append

#########################################################################################################
#########################################################################################################
# Write Subtitle to screen

write-output "Peripheral Equipment . . ." -foregroundcolor "magenta"

# Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>Peripheral Equipment (from Text Files on C:\ ): </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<font size=3>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

# Test for the presence of 3 files  C:\monitor.txt C:\printer.txt and C:\scanner.txt and tranfer 
# their content to the output of this script.

if ((Test-Path C:\monitor.txt) -eq "True"){
	# write to screen
	$strMonitor = get-content -Path C:\monitor.txt
	write-output "Monitor Serial Number: " + $strMonitor
}
if ((Test-Path C:\printer.txt) -eq "True"){
	# write to screen
	$strPrinter = get-content -Path C:\printer.txt
	write-output "Printer Serial Number: " + $strPrinter
}
if ((Test-Path C:\scanner.txt) -eq "True"){
	# write to screen
	$strScanner = get-content -Path C:\scanner.txt
	write-output "Scanner Serial Number: " + $strScanner
}

# write to HTML file
$strOutputString = " Monitor Serial Number: <strong>" + $strMonitor + "</strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
$strOutputString = " Printer Serial Number: <strong>" + $strPrinter + "</strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
$strOutputString = " Scanner Serial Number: <strong>" + $strScanner + "</strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "</font></p>"
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append

#########################################################################################################
#########################################################################################################
# Write Subtitle to screen
<#
write-output
write-output "Application Software . . ." -foregroundcolor "magenta"

 Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>Application Software Data: </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$colItems = get-wmiobject -Credential $cred -class "Win32_Product" -namespace "root\CIMV2" -computername $strComputer

foreach ($objItem in $colItems) {
	# write to screen
	write-output "Caption: " $objItem.Caption
	#write-output "Description: " $objItem.Description
	#write-output "Identifying Number: " $objItem.IdentifyingNumber
	#write-output "Installation Date: " $objItem.InstallDate
	##write-output "Installation Date 2: " $objItem.InstallDate2
	##write-output "Installation Location: " $objItem.InstallLocation
	#write-output "Installation State: " $objItem.InstallState
	#write-output "Name: " $objItem.Name
	#write-output "Package Cache: " $objItem.PackageCache
	##write-output "SKU Number: " $objItem.SKUNumber
	#write-output "Vendor: " $objItem.Vendor
	#write-output "Version: " $objItem.Version

	  
	# write to HTML file
	#$htmlFilePath = "C:\" + $objItem.CSName + ".html"
	$strOutputString = "<font size=2> " + "Name: <strong>" + $objItem.Caption + "</strong></font>,<font size=1> Install Date: <strong>" + $objItem.InstallDate + "</strong>, Vendor: <strong>" + $objItem.Vendor + "</strong>, Version: <strong>" + $objItem.Version + "</strong>, ID Num: <strong>" + $objItem.IdentifyingNumber + "</strong></font><font size=1 color=#6699cc>, MSI Cache: <strong>" + $objItem.PackageCache + "</strong></font><br>"
	$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
	
}
$strOutputString = "</p>" 
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append

#########################################################################################################
#########################################################################################################
# Write Subtitle to screen
write-output
write-output "Patch Data . . ." -foregroundcolor "magenta"

# Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>Patch Update Details: </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$colItems = get-wmiobject -Credential $cred -class "Win32_QuickFixEngineering" -namespace "root\CIMV2" -computername $strComputer

foreach ($objItem in $colItems) {
	
	# Eliminate any "nonsense" result that returns the value "File 1"
	if ($objItem.HotFixID -notlike "File 1") {
		# remove any legacy carriage returns "\n" from the data
		$description = $objItem.Description -replace " \\n", " "
		
		# write to screen
		write-output "HotFix ID: " $objItem.HotFixID " " $description
		#write-output "HotFix ID: " $objItem.HotFixID "  Installed On: " $objItem.InstalledOn "  Installed By: " $objItem.InstalledBy
		
		# write to HTML file
		$strOutputString = "<font size=2>" + "HotFix ID: <strong>" + $objItem.HotFixID + "</strong></font>,<font size=1> Installed On: <strong>" + $objItem.InstalledOn + "</strong>, Installed By: <strong>" + $objItem.InstalledBy + "</strong></font>&nbsp &nbsp <font size=1 color=#6699cc>" + $description + "</font><br>"
		$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
	}
}
$strOutputString = "</p>" 
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append
#>

#########################################################################################################
#########################################################################################################
# Write STAFF User Profiles to screen
write-output "Username Access History. . ." -foregroundcolor "magenta"

# Write Subtitle to HTML
$strOutputString = "<p>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$strOutputString = "<strong><font size=3 color=red>Username Access History: </font></strong><br>"
$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

$profilefilepath = "C:\Documents and Settings"

$profiles = get-item "$profilefilepath\*"
foreach ($profile in $profiles) {
	# Ensure the the date is formated to NZ Date Standard (Powershell tends to do the American format...)
	$accesstime = (get-item $profile).LastAccessTime | 	get-date  –f "dd/MM/yyyy HH:mm:ss"
			
	# Strip off the directory path
	$pusername = (get-item $profile).PSChildName 
	
	$ignoreprofile = "False"
	# Ignore the following Prolifes...
	if ($pusername -eq "Administrator") {$ignoreprofile = "True"}
	if ($pusername -eq "All Users") {$ignoreprofile = "True"}
	if ($pusername -eq "Default User") {$ignoreprofile = "True"}
	if ($pusername -eq "LocalService") {$ignoreprofile = "True"}
	if ($pusername -eq "NetworkService") {$ignoreprofile = "True"}
	
	# Get the remaining profiles
	if ($ignoreprofile -eq "False") {
		
		# All student accounts end in a number and we are not interested in recording these...
		# Confirm the string ends in a number...
		$string = $pusername
		$TorF = [Regex]::IsMatch($string, '\d$')
		if ($TorF -ne "True") {
			# write to screen
			write-output "Username: " $pusername "Last Access: " $accesstime

			#write to HTML file
			$strOutputString = "<font size=3>" + "Profile Username: <strong>" + $pusername + "</strong> Last Access: <strong>" + $accesstime + "</strong></font><br>"
			$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
		}
	}
}

$strOutputString = "</p>" 
$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append

#########################################################################################################
#########################################################################################################
# Process Norton/Symantec Antivirus Status
# Test if the Virus Defination Log file path exists...	
<#
$definfofilepath = "C:\Program Files\Common Files\Symantec Shared\VirusDefs\definfo.dat"
$pathpresent = Test-path $definfofilepath
if($pathpresent -eq "True") {


	write-output "Norton/Symantec Antivirus Status. . ." -foregroundcolor "magenta"

	# Write Subtitle to HTML
	$strOutputString = "<p>"
	$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append

	$strOutputString = "<strong><font size=3 color=red>Norton/Symantec Antivirus Status: </font></strong><br>"
	$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
		
	$VirDefData = get-content $definfofilepath
	$VirDefDate = $VirDefData[1]
	$dtyear = $VirDefDate.substring(8,4)
	$dtmonth = $VirDefDate.substring(12,2)
	$dtday = $VirDefDate.substring(14,2)
	$Rev = $VirDefDate.substring(17,3)
	
	# Reform the date to New Zealand standard format!
	$ddate = "$dtday" + "/" + "$dtmonth" + "/" + "$dtyear"
	
	$DateVirDefs = $ddate
	
	# write to screen
	write-output "Virus Def Date: $DateVirDefs"
	write-output "Revision Number: $Rev"
	
	# write to HTML file
	$strOutputString = "<font size=3>" + "Virus Def Date: <strong>" + $DateVirDefs + "</strong></font><br>"
	$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutputString = "<font size=3>" + "Revision Number: <strong>" + $Rev + "</strong></font><br>"
	$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append


	# Set the $key variable to the default registry location for NAV/SAV
	$key = "hklm:\Software\INTEL\LANDesk\VirusProtect6\CurrentVersion"

	# Get All the values in the key at this point
	$values = get-itemproperty $key
	
	# Split the $values at the semi-colon + space (; )           
	$values = [regex]::split($values,'; ')
	
	# Compare all the values seeking the Product version and License Number
	foreach ($value in $values) {

		##	write-output " Value: $value"
		if ([Regex]::IsMatch($value, '^LicenseNumber=')){
			$string = [regex]::split($value,'=')
			$LicenceNum = $string[1]
		}
		if ([Regex]::IsMatch($value, '^ProductVersion=')){
			$string = [regex]::split($value,'=')
			$ProductVer = $string[1]
		}
	}
			
	# write to screen
	write-output "Licence Number: $LicenceNum"
	write-output "Registry Version Identifier: $ProductVer"

	# write to HTML file
	$strOutputString = "<font size=3>" + "Licence Number: <strong>" + $LicenceNum + "</strong></font><br>"
	$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
	$strOutputString = "<font size=3>" + "Version Identifier (Registry): <strong>" + $ProductVer + "</strong></font><br>"
	$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
	
	# Convert the Product Version Number from the registry to a "known" product number...
	Switch ($productver){
		# Norton Antivirus conversion here... (need to find list of conversion numbers for other versions of NAV)
		61407993  {$NavVersion ="7.61.937"}
		
		# Symantec Antivirus conversion here...
		328336375 {$SavVersion ="10.1.5.5010"}
		23528424 {$SavVersion = "10.0.0.359"}
		65537001 {$SavVersion = "10.0.1.1000"}
		65995753 {$SavVersion = "10.0.1.1007"}
		66061289 {$SavVersion = "10.0.1.1008"}
		131073002 {$SavVersion = "10.0.2.2000"}
		131138538 {$SavVersion = "10.0.2.2001"}
		131728362 {$SavVersion = "10.0.2.2010"}
		132383722 {$SavVersion = "10.0.2.2020"}
		132449258 {$SavVersion = "10.0.2.2021"}
		25822194 {$SavVersion = "10.1.0.394"}
		25953266 {$SavVersion = "10.1.0.396"}
		26215410 {$SavVersion = "10.1.0.400"}
		26280946 {$SavVersion = "10.1.0.401"}
		65536905 {$SavVersion = "9.0.5.1000"}
		72090503 {$SavVersion = "9.0.3.1100"}
		65536903 {$SavVersion = "9.0.3.1000"}
		65536902 {$SavVersion = "9.0.2.1000"}
		65536901 {$SavVersion = "9.0.1.1000"}
		22152068 {$SavVersion = "9.0.0.338"}
		21562155 {$SavVersion = "8.1.1.329"}
		21168939 {$SavVersion = "8.1.1.323"}
		20906795 {$SavVersion = "8.1.1.319"}
		20579115 {$SavVersion = "8.1.1.314"}
		54068001 {$SavVersion = "8.1.0.825"}
		29950753 {$SavVersion = "8.0.1.457"}
		614597408 {$SavVersion = "8.0.0.9378"}
		614335264 {$SavVersion = "8.0.0.9374"}
		29229856 {$SavVersion = "8.0.0.446"}
		28640032 {$SavVersion = "8.0.0.437"}
		28443424 {$SavVersion = "8.0.0.434"}
		28115744 {$SavVersion = "8.0.0.429"}
		27853600 {$SavVersion = "8.0.0.425"}
		85197700 {$SavVersion = "7.60.926"}
		61997817 {$SavVersion = "7.6.1.946"}
		61473529 {$SavVersion = "7.6.1.938"}
		60949241 {$SavVersion = "7.6.1.930"}
		60687096 {$SavVersion = "7.6.1.926"}
		55509743 {$SavVersion = "7.5.1.847"}
		48366268 {$SavVersion = "7.0.0"}
	}
	
	# Output the "known" NAV/SAV version number
	if ($SavVersion -ne $null) {$VersionNumber = [int]$SavVersion.substring(0,2)}
	if ($NavVersion -ne $null) {$VersionNumber = [int]$NavVersion.substring(0,2)}
	
	# write to screen
	Write-host "Version Number: $VersionNumber"
	
	# write to HTML file
	$strOutputString = "<font size=3>" + "Version Number: <strong>" + $VersionNumber + "</strong></font><br>"
	$strOutputString  | out-file -filepath $htmlFilePath -encoding ascii -append
}

	$strOutputString = "</p>" 
	$strOutputString | out-file -filepath $htmlFilePath -encoding ascii -append
#>

} # End mail foreach computer iterator
} # End Function WMILookupCred


# =============================================================================================
# Function Name 'ListComputers' - Enumerates ALL computer objects in AD
# ==============================================================================================
Function ListComputers {
$strCategory = "computer"

$objDomain = New-Object System.DirectoryServices.DirectoryEntry -ErrorAction Inquire

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher -ErrorAction Inquire

$objSearcher.SearchRoot = $objDomain
# $objSearcher.Filter = ("(objectCategory=$strCategory)")

# Find all computers that aren't explicitly disabled - JHM
$objSearcher.Filter = "(&(objectCategory=computer)(!userAccountControl:1.2.840.113556.1.4.803:=2))"

$colProplist = "name"
foreach ($i in $colPropList){$objSearcher.PropertiesToLoad.Add($i)}

$colResults = $objSearcher.FindAll()

foreach ($objResult in $colResults)
    {$objComputer = $objResult.Properties; $objComputer.name}
}

# ==============================================================================================
# Function Name 'ListServers' - Enumerates ALL Servers objects in AD
# ==============================================================================================
Function ListServers {
$strCategory = "computer"
$strOS = "Windows*Server*"

$objDomain = New-Object System.DirectoryServices.DirectoryEntry -ErrorAction Inquire

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher -ErrorAction Inquire
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = ("(&(objectCategory=$strCategory)(OperatingSystem=$strOS)(!userAccountControl:1.2.840.113556.1.4.803:=2))")

$colProplist = "name"
foreach ($i in $colPropList){$objSearcher.PropertiesToLoad.Add($i)}

$colResults = $objSearcher.FindAll()

foreach ($objResult in $colResults)
    {$objComputer = $objResult.Properties; $objComputer.name}
}

# ========================================================================
# Function Name 'ListTextFile' - Enumerates Computer Names in a text file
# Create a text file and enter the names of each computer. One computer
# name per line. Supply the path to the text file when prompted.
# ========================================================================
Function ListTextFile {
	$strText = Read-Host "Enter the path for the text file"
	$colComputers = Get-Content $strText
}

# ========================================================================
# Function Name 'SingleEntry' - Enumerates Computer from user input
# ========================================================================
Function ManualEntry {
	$colComputers = Read-Host "Enter Computer Name or IP" 
}

#########################################################################################################

# Main Script body
	
#$erroractionpreference = "SilentlyContinue"

# Gather info from user.
Write-Host "********************************" 	-ForegroundColor Green
Write-Host "Computer Inventory Script" 			-ForegroundColor Green
Write-Host "Blame JHM for this" 				-ForegroundColor Green
Write-Host "Contact: jmensel@concepttechnologyinc.com" 	-ForegroundColor Green
Write-Host "********************************" 	-ForegroundColor Green
Write-Host " "
Write-Host "Admin rights are required to enumerate information," 	-ForegroundColor Green
Write-Host "so please enter some creds that have juice."		-ForegroundColor Green
#$credResponse = Read-Host "[Y] Yes, [N] No"
#If($CredResponse -eq "y"){}
$cred = Get-Credential NETWORK\Administrator
Write-Host " "
Write-Host "Which computer resources would you like in the report?"	-ForegroundColor Green
$strResponse = Read-Host "[1] All Domain Computers, [2] All Domain Servers, [3] Computer names from a File, [4] Choose a Computer manually"
If($strResponse -eq "1"){$colComputers = ListComputers | Sort-Object}
	elseif($strResponse -eq "2"){$colComputers = ListServers | Sort-Object}
	elseif($strResponse -eq "3"){. ListTextFile}
	elseif($strResponse -eq "4"){. ManualEntry}
	else{Write-Host "You did not supply a correct response, `
	Please run script again." -foregroundColor Red}				
Write-Progress -Activity "Getting Inventory" -status "Running..." -id 1

WMILookupCred

# Fin

