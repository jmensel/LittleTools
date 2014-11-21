#!/usr/bin/perl -w
# MySql Backup script
# John Mensel, Engineer
# jmensel@gmail.com

# Load neccesary modules
use strict;
use DBI;

# Dependencies 
# You'll need the perl-DBD-MySQL module and bzip2 for this to work.
# Try 'yum install perl-DBD-MySQL bzip2' or 'apt-get install libdbd-mysql-perl bzip2'
# You'll also need a working sendmail or equivalent (postfix is good) that will allow localhost to relay

# This script executes in the context of whatever user calls it.  As such, you must create a valid
# .my.cnf file for the user who will execute the script.  Example follows: (remove the comments, of course)

# Place this in /home/username/.my.cnf and chmod it 600
# [client]
# host=localhost
# user=mysql_username_here
# password=mysql_users_password_here

# You should change all of these variables:

#Email Variables
my $TO = "";
my $CC = "";

my $BACKUP_DIR = "/var/lib/mysqlbackup";

my $LOG = "/var/log/mysqlbackup.log";

#You don't need to change anything below this line.

#General Variables
my $HOSTNAME=`hostname`;
my $DATE2 = `date +%a`;
chomp ($DATE2);
my $DATE = `date`;
chomp ($DATE);
my $FAIL="0";
# Open logfile
open(STDOUT, ">$LOG");

# Email Variables
my $FROM = "mysqlbackup\@${HOSTNAME}";
my $SUBJECT = "MySQL Backup for ${HOSTNAME} - ";

#MySQLDump Options
my $OPTIONS = ' --lock-all-tables --flush-logs';

# Database variables
my $DBHOST = 'localhost';
my $DBNAME = 'mysql';
my $DSN = DBI->connect("DBI:mysql:$DBNAME:$DBHOST;mysql_read_default_file=$ENV{HOME}/.my.cnf");
my ($DATABASE);


#####################################################

#####################################################


# Generate Email Notifications
# Syntax: sendEmail($to, $from, $subject, $message);
# Note that these email variables are of separate scope from
# the ones defined at the beginning of this script.
sub sendEmail
{
my ($to, $from, $cc, $subject, $message) = @_;
my $sendmail = "/usr/sbin/sendmail";
open(MAIL, "|$sendmail -oi -t");
print MAIL "TO: ${to}\n";
print MAIL "Cc: ${cc}\n";
print MAIL "SUBJECT: ${subject}\n";
print MAIL "FROM: ${from}\n";
print MAIL "\n${message}\n";
close(MAIL);
}


# Database queries follow
my $QUERY1 = "SHOW DATABASES";
print `date` . "Starting backup...\n";

# Prepare and execute the query
my $STH = $DSN->prepare($QUERY1);
my @DBLIST = $STH->execute();

while(@DBLIST = $STH->fetchrow()) {

    foreach $DATABASE (@DBLIST) {
        chomp ($DATABASE);
        print "Dumping and zipping $DATABASE\n";
        my $FILE = "$BACKUP_DIR/$DATABASE-$DATE2.sql";
        system("mysqldump $DATABASE $OPTIONS > $FILE");
        if ( $? == -1) { 
        	 print "Dump of ${DATABASE} failed: $?\n";
	         $FAIL++;
	      } else {
           print "Dump of ${DATABASE} successful.\n";
	}
	`sleep 10`;
	`bzip2 -zf $BACKUP_DIR/$DATABASE-$DATE2.sql`;
        print `date` . "$DATABASE done.\n\n";
    }
}

# Dump Failure Rate to Log
if ( ${FAIL} > 0 ) {
  printf "Mysql Dump failed ${FAIL} times.\n";
	${SUBJECT} .= "Failed.";
} else {
	printf "MySQL Dump was sucessful on all databases.\n";
	${SUBJECT} .= "Successful.";
}

# Close the logs and deliver notifications
close ($LOG);
my $BODY = `cat $LOG`;
sendEmail ("${TO}","$FROM","$CC","$SUBJECT","$BODY");

exit 0
