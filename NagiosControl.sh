#!/bin/bash

# NAGIOS AddHost Script
# By John Mensel
# This is a kind of silly bit of bash that I used once upon a time
# to allow people to add simple hosts checks to a Nagios installation.
# I don't suggest that you use it in a production environment - it is
# included here for archival/example purposes only.

# Prevent unset variables from being evaluated
set -o nounset 

#Directories
nagiosconf="/etc/nagios3/nagios.cfg"
NAGIOSPATH="/etc/nagios"
SERVERDIR="/etc/nagios/servers"
BACKUPDIR="/var/nagios/backup"
WORKINGDIR="/etc/nagios/servers"
CONFDIR="conf.d"
ALERTLOG="/var/log/nagios-control.log"
fail=""
args=$@
servicecount=""

#Service Configuration Files

SMTPCONF="conf.d/smtp_services.cfg"
RDPCONF="conf.d/rdp_services.cfg"
PPTPCONF="conf.d/pptp_services.cfg"
WWWCONF="conf.d/www_services.cfg"

servicesarray=( $SMTPCONF $RDPCONF $PPTPCONF $WWWCONF )

######################################################
# You Shouldn't need to touch anything below this line
######################################################

# This is for datstamping backup files
THEDATE=`date +%A.%H.%M.%S`

# Commands we need
NSLOOKUPCMD=`which nslookup`

# Variables for GetOpts
cflag=""
dflag=""
rflag=""
lflag=""
smtpflag=""
allflag=""
rdpflag=""
aliasflag=""
aliasflagval=""
tidyflag=""
wwwflag=""

#######################
# Function Definitions#
#######################

function usage {

printf "\nUsage: $0 [options] HOSTNAME\n"
printf "\nBy Default, $0 HOSTNAME creates a host entry\n"
printf "with no associated services.\n"
printf "\nThis results in a host ICMP ping check, and nothing else.\n"
printf "\nOptions:\n"
printf "  -c, (Default) Create Config File for HOSTNAME \n"
printf "  -l, List Existing Hosts\n"
printf "     If run with hostnames as arguments, prints service information\n"
printf "     for those hosts.\n"
#printf "  -t, Disables automatic services file removal\n"
printf "  -d, Delete Config File for HOSTNAME\n"
#printf "  -a, Create Config with all Available Services\n"
printf "  -n  'ALIAS', Create Config with an Alias\n"
printf "     ALIAS must be quoted if it contains spaces\n"
printf "  -s, Create Config with SMTP service entry\n"
printf "  -r, Create Config with RDP service entry\n"
printf "  -p, Create Config with PPTP service entry\n"
printf "  -w, Create Config with WWW service entry (port 80)\n"
#printf "  -z, Create Config with WWW-SSL service entry (port 443)\n"
printf "\nStandard Usage:\n"
printf "\nThis will create a new host entry with SMTP services and a"
printf "\nhost alias (friendly name that appears in the web interface).\n\n"
echo 'nagios-control.bash -s -n "Evil Industries Inc Mail Server" mail.evilind.com'
printf "\n"
exit 1

} # End function usage

function choice {
    CHOICE=''
    printf "\n"
    local prompt="Create Config for ${hostname}?[Y/n]"
    local answer

    read -p "$prompt" answer
    case "$answer" in
       [yY1] ) CHOICE='y';;
       [nN0] ) CHOICE='n';;
       *     ) CHOICE='y';;
    esac

} # end function choice

function check {

if ( ! sudo /usr/sbin/nagios3 -v $nagiosconf )
  then 
   printf "\nArrgh, the existing config is bad.\n"
   printf "\nYou must fix the existing configuration before I will run.\n"
   printf "\nDying a Horrible Death......\n\n"
   exit 1
fi

    # Check Hostname and alias for naughty bits
    # We're banning anything but letters, numbers,
    # Dashes, and periods.
 echo $hostname | egrep "^[a-zA-Z0-9.-]*$"
 if [ $? -gt 0 ]
 then echo "You can't have any special characters in a hostname. "
      echo "Periods and dashes only, please."
      echo "Seriously, that was either a typo or you're being very"
      echo "naughty.  I will now heroically sacrifice myself for "
      echo "the good of the system.  *DIES HORRIBLY*"
      exit 1
  fi
 
echo $aliasflagval | egrep "^[a-zA-Z0-9 .-]*$" 
 if [ $? -gt 0 ]
 then echo "You can't have any special characters in an alias. "
      echo "Periods, underscores, and dashes only, please."
      echo "Seriously, that was either a typo or you're being very"
      echo "naughty.  I will now heroically sacrifice myself for "
      echo "the good of the system.  *DIES HORRIBLY*"
      exit 1
  fi

# Check to see if the host resolves 
    
$NSLOOKUPCMD $hostname | grep "Non-authoritative answer"
 if [ $? -gt 0 ]
 then printf "\n\n$hostname Does Not Resolve.\n"
      echo "This is not the end of the world, but it might"
      echo "indicate a problem.  Are you sure?"
      echo ""
  choice
   if [ $CHOICE == 'n' ]
   then printf "\nOK, quitting without any changes.\n"
   exit 0
   fi
   else echo ""
        echo "${hostname} seems to resolve OK."
   fi
echo ""

# Check to see if hostfile already exists
if [ -e ${WORKINGDIR}/${OUTFILE} ]
 then  printf "\n${OUTFILE} already exists.  Overwrite\?\n\n"
 choice
 if [ $CHOICE == 'n' ]
 then echo "OK, quitting without any changes."
  exit 0
 fi
fi
echo "Checks passed, moving right along."


} # End Function check

function backup {

printf "Backing Up configs to ${BACKUPDIR}/${THEDATE}\n" 

if [ ! -d ${BACKUPDIR}/${THEDATE} ] 
then mkdir -p ${BACKUPDIR}/${THEDATE}
  if ( ! cp -Rf /etc/nagios/ ${BACKUPDIR}/${THEDATE}/ )
  then 
   printf "\nAaarrgh, I cannot copy the backup files.\n"
   printf "\nI am sure this was all YOUR fault.\n"
   printf "Dying a horrible death.....\n\n"
   exit 1
  fi
else echo "BackupDir already exists, dying a horrible death."
  exit 1
fi

} #End function backup


function create {
printf "Spawning $hostname in nagios.\n"
  
# Generate the Host File Config
echo "define host{" > ${WORKINGDIR}/${OUTFILE}
echo "    use                  generic-host" >> ${WORKINGDIR}/${OUTFILE}
echo "    host_name             ${hostname}" >> ${WORKINGDIR}/${OUTFILE}
if [ "$aliasflag" ]
 then echo "    alias            ${aliasflagval}" >> ${WORKINGDIR}/${OUTFILE}
 else echo "    alias                 ${hostname}" >> ${WORKINGDIR}/${OUTFILE}
fi
echo "    address		     ${hostname}" >> ${WORKINGDIR}/${OUTFILE}

if [ "$smtpflag" -o "$allflag" ]
then 
 echo "    check_command            check-host-smtp" \
  >> ${WORKINGDIR}/${OUTFILE}
fi

if [ "$rdpflag" -o "$allflag" ]
then
 echo '    check_command            check_tcp!3389' \
  >> ${WORKINGDIR}/${OUTFILE}
fi

if [ "$pptpflag" -o "$allflag" ]
then
 echo "   check_command		   check-host-pptp" \
  >> ${WORKINGDIR}/${OUTFILE}
fi

if [ "$wwwflag" -o "$allflag" ]
then
 echo "   check_command            check_http" \
  >> ${WORKINGDIR}/${OUTFILE}
fi

echo "" >> ${WORKINGDIR}/${OUTFILE}   
echo "}" >> ${WORKINGDIR}/${OUTFILE}

# End Host File Config  
  
  # Update SMTP_Services file
  # Looks for a line that starts with host_name and
  # Appends to the end of that line

  if [ "$smtpflag" -o "$allflag" ]
   then
   if ( egrep -i "\b${hostname}\b" ${NAGIOSPATH}/${SMTPCONF} ) 
   then printf "\n$hostname is already in $SMTPCONF - skipping.\n" 
   else
   printf "\nAdding $hostname to $SMTPCONF Services File.\n"
   
    if [ -r ${BACKUPDIR}/${THEDATE}/nagios/${SMTPCONF} ]
    then
     sed "/host_name/s|$|, ${hostname}|" \
      ${BACKUPDIR}/${THEDATE}/nagios/${SMTPCONF} \
      >  ${NAGIOSPATH}/${SMTPCONF}
    else
     printf "\nI cannot read the backup file. Ugh, dying a horrible  death.\n"
     printf "\nYou probably are not running me with the right privileges.\n"
    fi

   fi 
  fi
 
  # Update rdp_services file

  if [ "$rdpflag" -o "$allflag" ]
   then
   if ( egrep -i "\b${hostname}\b" ${NAGIOSPATH}/${RDPCONF} ) 
   then 
   printf "\n$hostname is already in $RDPCONF - skipping.\n"
   else
   printf "\nAdding $hostname to $RDPCONF Services File.\n" 
   
    if [ -r ${BACKUPDIR}/${THEDATE}/nagios/${RDPCONF} ]
    then 
     sed "/host_name/s|$|, ${hostname}|" \
      ${BACKUPDIR}/${THEDATE}/nagios/${RDPCONF} \
      >  ${NAGIOSPATH}/${RDPCONF}
    else
     printf "\nI cannot read the backup file. Ugh, dying a horrible  death.\n"
     printf "\nYou probably are not running me with the right privileges.\n"
    fi

   fi
  fi

  # Update pptp_services file

  if [ "$pptpflag" -o "$allflag" ]
   then
   if ( egrep -i "\b${hostname}\b" ${NAGIOSPATH}/${PPTPCONF} ) 
   then 
   printf "\n$hostname is already in $PPTPCONF - skipping.\n"
   else
   printf "\nAdding $hostname to $PPTPCONF Services File.\n" 
   
    if [ -r ${BACKUPDIR}/${THEDATE}/nagios/${PPTPCONF} ]
    then 
     sed "/host_name/s|$|, ${hostname}|" \
      ${BACKUPDIR}/${THEDATE}/nagios/${PPTPCONF} \
      >  ${NAGIOSPATH}/${PPTPCONF}
    else
     printf "\nI cannot read the backup file. Ugh, dying a horrible  death.\n"
     printf "\nYou probably are not running me with the right privileges.\n"
    fi

   fi
  fi


  # Update www_services file

  if [ "$wwwflag" -o "$allflag" ]
   then
   if ( egrep -i "\b${hostname}\b" ${NAGIOSPATH}/${WWWCONF} )
   then
   printf "\n$hostname is already in $WWWCONF - skipping.\n"
   else
   printf "\nAdding $hostname to $WWWCONF Services File.\n"

    if [ -r ${BACKUPDIR}/${THEDATE}/nagios/${WWWCONF} ]
    then
     sed "/host_name/s|$|, ${hostname}|" \
      ${BACKUPDIR}/${THEDATE}/nagios/${WWWCONF} \
      >  ${NAGIOSPATH}/${WWWCONF}
    else
     printf "\nI cannot read the backup file. Ugh, dying a horrible  death.\n"
     printf "\nYou probably are not running me with the right privileges.\n"
    fi

   fi
  fi

# Set Permissions on Outfile
     #chown root."domain users" ${WORKINGDIR}/${OUTFILE}
     chmod 774 ${WORKINGDIR}/${OUTFILE}


} # end function create

function tidyservices {
# Removes host from services files

for service in ${servicesarray[*]}
do
 printf "\nChecking ${service}\n."
 if ( egrep -i "\b${hostname}\b" ${NAGIOSPATH}/${service} )
 then 
  printf "\nRemoving $hostname entry from ${service}.\n"
  #This is hard to read.
  #Removes hostname from services file, removes trailing comma,
  # and removes doubled comma and trims whitespace
  sed -e s/${hostname}//g -e s/\,[[:space:]]*$//g \
   -e s/\,[[:space:]]*\,/\,/g ${BACKUPDIR}/${THEDATE}/nagios/${service} \
    > ${NAGIOSPATH}/${service} 
 fi 
done
} # End Function tidyservices

function validate {
# Validates config and rolls back if there are problems
printf "Validating config...\n"
sudo /usr/sbin/nagios3 -v /etc/nagios/nagios.cfg
if [ $? -gt 0 ]
   then printf "The config is bad, rolling back.\n"
   printf "Removing Generated Config...\n"
   #rm -f ${WORKINGDIR}/{$OUTFILE}
   # Restore hostname configfile

   if [ -f ${BACKUPDIR}/${THEDATE}/nagios/servers/${hostname} ]
   then cp -f ${BACKUPDIR}/${THEDATE}/nagios/servers/${hostname} \
              ${SERVERDIR}/${hostname}
        printf "Restoring ${hostname} from ${BACKUPDIR}/${THEDATE}\n"
   else rm -f ${SERVERDIR}/${hostname}
        printf "Removing ${SERVERDIR}/${hostname}\n"
    for service in ${servicesarray[*]}
     do
     printf "Rolling back ${service} config file.\n"
     cp -f ${BACKUPDIR}/${THEDATE}/nagios/${service} ${NAGIOSPATH}/${service}
     done
   fi

else echo "Config Check Suceeded."
  if ( ! sudo /usr/sbin/service nagios restart )
   then printf "Wow, I totally Failed.  Please call JHM and blame him.\n"
    exit 1
  fi

fi
} # end function validate

    
function old-validate {
    printf "Validating config......\n"
    sudo /usr/sbin/nagios3 -v /etc/nagios/nagios.cfg
    if [ $? -gt 0 ]
     then echo "The config is bad, rolling back."
      echo "Removing Generated Config..."
      rm -f ${WORKINGDIR}/{$OUTFILE}
      echo "Rolling back to original SMTP service config file ${SMTPCONF}"
      cp -f ${BACKUPDIR}/${THEDATE}/nagios/${SMTPCONF} ${NAGIOSPATH}/${SMTPCONF}
      echo "Rolling back to original RDP service config file ${RDPCONF}"
      cp -f ${BACKUPDIR}/${THEDATE}/nagios/${RDPCONF} ${NAGIOSPATH}/${RDPCONF}
     else echo "Config Check Suceeded."
      if ( ! sudo /usr/sbin/service nagios restart )
       then fail=1
      fi
    fi
} # end function old-validate

function deleteconfig {
echo "JHM disabled this function due to a bug on 11-22-2011."
echo "Blame him if you see this message."
exit 1
# Deletes the host completely
#printf "\nThis will purge the config for ${hostname}, and cannot be undone.\n"
#local DELETECHOICE=''
#printf "\n"
#local prompt="Destroy Config for ${hostname}?[y/N]"
#local answer
#
#read -p "$prompt" answer
#  case "$answer" in
#     [yY1] ) DELETECHOICE='y';;
#     [nN0] ) DELETECHOICE='n';;
#     *     ) DELETECHOICE='n';;
#  esac
#if [ $DELETECHOICE == 'n' ]
# then echo "OK, quitting without any changes."
#  exit 0
# else
#  if [ -f ${WORKINGDIR}/${OUTFILE} ]
#  then
#   rm -f ${WORKINGDIR}/${OUTFILE}
#   printf "Destroying ${hostname}\n"
#  else
#   printf "Hehe - that hostfile does not exist.\n"
#   printf "I blame user-error, personally.\n"
#   exit 1
#  fi
#fi
} # End function deleteconfig

function alert {

if [ ! $ALERTLOG ]
then touch $ALERTLOG
fi

printf "nagios-control.bash changelog for ${hostname}\n" > $ALERTLOG
printf "\n${USER} ran ${0} $args \n\n" >> $ALERTLOG
printf "Thanks,\n\n" >> $ALERTLOG
printf "Nagios\n" >> $ALERTLOG

mail -s "Nagios-Control Changelog for ${hostname}" jmensel@concepttechnologyinc.com -c jmcmahan@concepttechnologyinc.com < $ALERTLOG

exit 0

} # End Function alert

function list {
if [ -z "$*" ]
 then
  printf "\n\nCurrently Available Hosts:\n\n"
  /usr/bin/find ${SERVERDIR} -type f -name *.cfg | sed -e  s%/etc/nagios/servers/%%g -e s%.cfg%%g | column
  exit 0
 else

 for hostname in $*
 do
 servicecount=""
 # This is most ugly, but necessary.  Note the use of the word boundary
 # delimiter in egrep, which is a reqirement for accurate ID of hostnames
 if ( /usr/bin/find ${SERVERDIR} -type f -name *.cfg | sed -e  s%/etc/nagios/servers/%%g -e s%.cfg%%g | egrep -e "\b${hostname}\b")
 then
  for service in ${servicesarray[*]}
  do
   if ( egrep -i "\b${hostname}\b" ${NAGIOSPATH}/${service} > /dev/null )
   then
    printf "\n$hostname has an entry in ${service}.\n"
    let "servicecount = $servicecount + 1"
   fi
  done

  if [ $servicecount > 0 ]
  then
  printf "\nFound ${hostname} in $servicecount service entries.\n"
  else
  printf "\nThere were no service entries for ${hostname}.\n"
  fi
 else
  printf "\nHost ${hostname} does not exist.\n"
 fi 
 done

 fi
printf "\n"
exit 0
} # End Function List

#########################
# End Functions

#########################
# Parse Command Line Options
#########################

while getopts 'dn:tcrashwlp?' OPTION
do 
  case $OPTION in
  c)   cflag=1
       # Set Create Mode
       ;;
  d)   dflag=1
       # Set Delete Mode
       ;;
  s)   smtpflag=1
       # Add Mail Checks
       ;;
  r)   rdpflag=1
       # Add RDP Checks
       ;;
  #a)   allflag=1
       # Do Everything!  No mercy!
  #     ;;
  n)   aliasflag=1
       aliasflagval="$OPTARG"
       # Add Host Alias
       ;;
  t)   tidyflag=1
       # Disables servicefile cleaning 
       ;;  
  l)   lflag=1
       # Enable List Mode
       ;;
  p)   pptpflag=1
       # Add pptp vpn checks
       ;;
  w)   wwwflag=1
       # Add www checks on port 80
       ;;
  [?hH] )   usage
            exit 2
            ;;
  *)   cflag=1
       # Use Create Mode with no services by default
       # And remove existing services entries
       ;;
  esac
done

# Move down the argument list
shift $(($OPTIND - 1))


if [ "$lflag" ]
then
 list $*
 exit 0
fi

if [ "$cflag" -a "$dflag" ]
then
  printf "\nWhat sort of crazy person are you, anyway\?\n"
  printf "\nYou may not run in both create and delete mode at the same time.\n\n"
  exit 2
fi

if [ "$dflag" ]
then
  printf "\nRunning in Delete Mode.\n\n"
  hostname=${!#}
  OUTFILE=${hostname}.cfg
  backup
  deleteconfig
  tidyservices
  validate
  alert
  exit 0
fi


# If there's more or less than one argument remaining, print usage

if [ "$#" -lt 1 -o "$#" -gt 1 ]
then
# printf "Remaining args: %s\n" "$*"
 usage
else
 hostname=${!#}
 OUTFILE=${hostname}.cfg
fi

choice

if [ $CHOICE == "n" ]
  then echo "OK, quitting without any changes."
       exit 0
   else
   backup
   check
   if [ "$tidyflag" != 1 ]
   then tidyservices
   fi
   create
   validate
   alert
fi

exit 0
