Minimum Downtime MySQL Master-Slave process.
#######

Here's an example proceedure for an (almost) zero downtime mysql cutover that I once performed.  The details have been modified to protect the innocent :-) 

The only gotcha is that we have to restart the mysql daemon on server1 so that the binlog config can take effect.  This generally doesn't cause problems - the daemon generally restarts almost instantly on most servers if we flush the tables correctly prior to a restart.

The end goal of this process is that we will have a Master/Slave configuration, where server1 is the Slave and server2 is the master.  We will continue to take backups from server1 so that the additional load from the backups will not negatively impact performance.

Create a new Mysql configuration file on server1 in /etc/my.cnf.new.  This file will convert server1 into a master server and enable the binlogs we need in order to sync the slave.

You'll need to add this on the current master:

		# my.cnf for master
		server-id=1
		binlog-format = mixed
		log-bin=mysql-bin
		innodb_flush_log_at_trx_commit=1
		sync_binlog=1

Order of operations:

Restart mysql daemon on server1 so that the master config can take effect and we can start binlogging

	server1:# cd /etc
	server1:# git commit -m "About to cut over MySQL config to master/slave" /etc/my.cnf
	server1:# cp /etc/my.cnf.new /etc/my.cnf

		mysql> FLUSH LOCAL TABLES;

		mysql> FLUSH TABLES WITH READ LOCK;

DON'T CLOSE the Mysql prompt.  Wait until the mysql prompt comes back, which means that the flush is complete.
Open another shell to restart the daemon.

		server1:# service mysql restart

...make sure everything came back up OK.

Take a full backup of server1 with the following command.  Don't do this during peak hours.
Make sure that you pause the SafeBackup backup so that they don't collide.
		
		server1:# mysqldump --skip-lock-tables --single-transaction --flush-logs --hex-blob --master-data=2 -A  > /mnt/data/dump.sql

...that's going to take a while...

Push this backup to server2 and restore it.

		server2:$ mysql < dump.sql

Get the Master Log Position

	server2:$ head dump.sql -n80 | grep "MASTER_LOG_POS"

	mysql> 
		CHANGE MASTER TO MASTER_HOST='10.1.6.33', MASTER_USER='replication',MASTER_PASSWORD='insertpasswordhere',MASTER_LOG_FILE='{{value from the grep command above}}', MASTER_LOG_POS='{{value from the grep command above}}';
			START SLAVE;

Verify slave replication:
		mysql> SHOW SLAVE STATUS \G;


At this point, all of the pieces are set, and need to queue everyone up for the handout.  Lets doubly ID the web servers:

The following servers have persistent connections to server1:

		[root@server1 tmp]# ss | grep mysql | awk '{print $5}' | cut -d':' -f1 | sort | uniq
		10.1.1.18 (web05)
		10.1.1.19 (web04)
		10.1.1.20 (web03)
		10.1.1.21 (web02)
		10.1.1.31 (web01)

Verify sql connectivity to server2 from each server with:

		$ mysql -u user -h 10.1.6.34 -p

...and use the password specified in the config file below

From this point on, things have to happen very fast.  
Make sure that everyone is 100% ready to go before you move forward.
Once you flush the logs on server1, nothing will be able to issue write queries until the cutover is complete.
SELECT queries will continue to work throughout the cutover from this point.

Now it's time to hand out the masters
On server1, flush the logs:
		mysql > flush logs;

On server2, promote it to master
		mysql> stop slave;
		mysql> reset slave all;

...and verify that all is well

	mysql> show master status \G;

Time to fix up the web servers:

Rewrite mysql config file:
/opt/somedomain/dbconf.json (updated copy below)

In the meantime, this script will log in to each box and run the command, but you'll have to enter a password each time.  Have your clipboard ready.
		#!/bin/bash

		# Makes a backup file and the performs an in-place edit of each Node.js db config file
		ssh web01.somedomain.prod 'sed -i.db02 "s/10\.1\.6\.33/10\.1\.6\.34/g" /opt/somedomain/dbconf.json'
		ssh web02.somedomain.prod 'sed -i.db02 "s/10\.1\.6\.33/10\.1\.6\.34/g" /opt/somedomain/dbconf.json'
		ssh web03.somedomain.prod 'sed -i.db02 "s/10\.1\.6\.33/10\.1\.6\.34/g" /opt/somedomain/dbconf.json'
		ssh web04.somedomain.prod 'sed -i.db02 "s/10\.1\.6\.33/10\.1\.6\.34/g" /opt/somedomain/dbconf.json'
		ssh web05.somedomain.prod 'sed -i.db02 "s/10\.1\.6\.33/10\.1\.6\.34/g" /opt/somedomain/dbconf.json'
		

Test everything, and make sure it's all good, and then test it again.
It's best to do this with the following URL on each webXX box; this Node.js route will roundtrip mysql
			http://10.1.1.31/hlthchck
			http://10.1.1.21/hlthchck
			http://10.1.1.20/hlthchck
			http://10.1.1.19/hlthchck
			http://10.1.1.18/hlthchck
The HAProxy stats page could also be useful in this process
			http://10.1.1.24/haproxy?stats

{
  "development": {
    "host": "127.0.0.1",
    "user": "root",
    "password": "",	
    "database": "BigBadDatabase",
    "port": 3306
  },
  "production": {
    "insecureAuth":"true",
    "host": "10.1.1.2",
    "user": "user",
    "password": "biguglypassword",
    "database": "BigBadDatabase",
    "port": 3306
  }
}





		
			




