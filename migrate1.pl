#!/usr/bin/perl -w

#use strict;

$fromserver = "192.168.10.5";
$toserver = "yourserver.yourdomain.com";


# format is:
# from-server-username,from-server-password,to-server-username,to-server-password

open(DAT, USERS) || die("could not open file");

@raw_data=<DAT>;

foreach $mailbox (@raw_data) {
	chomp($mailbox);
	# skip the user if it is commented out
	if ($mailbox =~ /^#/) {
		next;
	} else {
	#split out usernames and passwords from csv
	($fromusernameraw,$frompassword,$tousernameraw,$topassword)=split(/\,/,$mailbox);
	# make them usernames lowercase
	$fromusername = lc($fromusernameraw);
	$tousername = lc($tousernameraw);
	# Log stuff
	if ( ! open LOG, ">>$tousername") {
		die "Cannot create logfile: $!";
	}
	#if ( ! open STDOUT, ">>$tousername") {
	#	die "Cannot open logfile: $!";
	#}
	#if ( ! open STDERR, ">>$tousername") {
	#	die "Cannot open logfile: $!";
	#}
	printf LOG "Syncing mailbox $fromusername on $fromserver to mailbox $tousername on $toserver.\n";
	# Define the sync command
	$cmd = "perl -I ./Mail-IMAPClient-2.2.9 /usr/bin/imapsync --host1 $fromserver --user1 $fromusername --password1 $frompassword --noauthmd5 --prefix1 / --sep1 / --skipheader '^Content-Type' --nosyncacls --maxage 3650 --host2 $toserver --user2 $tousername --password2 $topassword --noauthmd5 --syncinternaldates >> $tousername";
	# ...and execute it.  No mercy!
	`$cmd`;	
#	printf LOG "$syncresult \n";
	close(LOG);
	#close(STDERR);
	#close(STDOUT);
	}
}
# Current working command:
# /usr/bin/imapsync --host1 192.168.10.5 --user1 sbrady --password1 twe7lve --noauthmd5 --prefix1 / --sep1 / --skipheader ^Content-Type --nosyncacls --maxage 3650 --host2 sv2 --user2 shearn --password2 twe7lve --noauthmd5

