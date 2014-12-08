#!/bin/bash

# create timestamp
timestamp() {
	date +"%T"
}

# append timestamp to log file so each set of log messages is identifiable
echo $(timestamp) >> ~/DeploymentScripts/log.txt

# change into tmp directory
cd /tmp

# create sandbox
SANDBOX=sandbox_$RANDOM
mkdir $SANDBOX
echo Using sandbox $SANDBOX
cd $SANDBOX

# set errorcheck variable to 0
ERRORCHECK=0

# create process folders
mkdir build
mkdir integrate
mkdir test

# get webpackage for testing
git clone https://github.com/traynore/WebApp.git

# tar up webpackage
tar -zcvf webpackage_preBuild.tgz WebApp

# check if MD5sum has changed
MD5SUM=$(md5sum webpackage_preBuild.tgz | cut -f 1 -d' ')
PREVMD5SUM=$(cat /tmp/md5sum)
FILECHANGE=0
if [[ "$MD5SUM" != "$PREVMD5SUM" ]]
then
	FILECHANGE=1
	echo $MD5SUM not equal to $PREVMD5SUM
else
	FILECHANGE=0
	echo $MD5SUM equal to $PREVMD5SUM
fi

# store MD5sum out in file
echo $MD5SUM > /tmp/md5sum

# exit cleanly if MD5sum hasn't changed, otherwise proceed
if [ $FILECHANGE -eq 0 ]
then
	echo no change in files, doing nothing and exiting >> ~/DeploymentScripts/log.txt
	exit
fi

# move webpackage to build dir
echo "Moving to build phase" >> ~/DeploymentScripts/log.txt
mv webpackage_preBuild.tgz build
rm -rf WebApp

# untar file
cd build
tar -zxvf webpackage_preBuild.tgz

# perform build/manipulation functions
# test form.html, accept_form.pl, hello_world.pl, testdb.pl exist
FORM="DeploymentWebApp/www/form.html"
if [ -e "$FORM" ]
then
	echo "form.html exists!" >> ~/DeploymentScripts/log.txt
else
	echo "form.html is not present!" >> ~/DeploymentScripts/log.txt
	ERRORCHECK=$((ERRORCHECK+1))
fi

ACCEPT_FORM="DeploymentWebApp/cgi-bin/accept_form.pl"
if [ -e "$ACCEPT_FORM" ]; then
	echo "accept_form.pl exists!" >> ~/DeploymentScripts/log.txt
else
	echo "accept_form.pl is not present!" >> ~/DeploymentScripts/log.txt
	ERRORCHECK=$((ERRORCHECK+1))
fi

HELLO="DeploymentWebApp/cgi-bin/hello_world.pl"
if [ -e "$HELLO" ]; then
	echo "hello_world.pl exists!" >> ~/DeploymentScripts/log.txt
else
	echo "hello_world.pl is not present!" ~/DeploymentScripts/log.txt
	ERRORCHECK=$((ERRORCHECK+1))
fi

TESTDB="DeploymentWebApp/cgi-bin/testdb.pl"
if [ -e "$TESTDB" ]; then
	echo "testdb.pl exists!" >> ~/DeploymentScripts/log.txt
else
	echo "testdb.pl is not present!" ~/DeploymentScripts/log.txt
	ERRORCHECK=$((ERRORCHECK+1))
fi

# integrate static html content from 2 or more files into 1
cat DeploymentWebApp/www/content.html WebApp/www/image.html > WebApp/www/index.html
INDEX="DeploymentWebApp/www/index.html"
if [ -e "$INDEX" ]
then
	echo "index.html created successfully" >> ~/DeploymentScripts/log.txt
else
	echo "index.html not created successfully" >> ~/DeploymentScripts/log.txt
	ERRORCHECK=$((ERRORCHECK+1))
fi

# clean environment (uninstall + reinstall apache + mysql)
# stop services
echo "Stopping services" >> ~/DeploymentScripts/log.txt
service apache2 stop
service mysql stop

# uninstall
echo "Uninstalling Apache and mySQL" >> ~/DeploymentScripts/log.txt
apt-get -q -y remove apache2
apt-get -q -y remove mysql-client mysql-server
echo mysql-server mysql-server/root_password password password | debconf-set-selections
echo mysql-server mysql-server/root_password_again password password | debconf-set-selections

# refresh apt package repo
apt-get update

# reinstall
echo "Reinstalling Apache and mySQL" >> ~/DeploymentScripts/log.txt
apt-get install apache2
apt-get install mysql-client mysql-server

# restart apache and mysql
echo "Starting services" >> ~/DeploymentScripts/log.txt
service apache2 start
service mysql start

# tar package back up
tar -zcvf webpackage_preIntegrate.tgz WebApp

# # move webpackage to Integrate dir and clean up
echo "Moving to Integration phase" >> ~/DeploymentScripts/log.txt
mv webpackage_preIntegrate.tgz ../integrate
rm -rf WebApp

# untar
cd ../integrate
tar -zxvf webpackage_preIntegrate.tgz

# move html files to apache /www
cd WebApp
cp www/* /var/www

# move perl files to /cgi-bin
cp cgi-bin/* /usr/lib/cgi-bin

# make perl files executable
chmod a+x /usr/lib/cgi-bin/*

# return to sandbox
cd ..

# check files were copied successfully
IND="/var/www/index.html"
FORM="/var/www/form.html"
AFPL="/usr/lib/cgi-bin/accept_form.pl"
HW="/usr/lib/cgi-bin/hello_world.pl"
TDB="/usr/lib/cgi-bin/testdb.pl"

if [ -e "$IND" ] && [ -e "$FORM" ] && [ -e "$AFPL" ] && [ -e "$HW" ] && [ -e "$TDB" ]
then
	echo "HTML and Perl files in place" >> ~/DeploymentScripts/log.txt
else
	echo "HTML and Perl files NOT in place" >> ~/DeploymentScripts/log.txt
	ERRORCHECK=$((ERRORCHECK+1))
fi

# tar it back up
tar -zcvf webpackage_preTest.tgz DeploymentWebApp

# # move to test dir and clean up
echo "Moving to Test phase" >> ~/DeploymentScripts/log.txt
mv webpackage_preTest.tgz ../test
rm -rf WebApp

# untar
cd ../test
tar -zxvf webpackage_preTest.tgz

# perform test/manipulation
# check static content is properly constructed
tidy /var/www/*

# test dynamic content functions as required
# ie perl script enters data into database
# configure mysql
echo "Testing if data added to mysql" >> ~/DeploymentScripts/log.txt
cat <<FINISH | mysql -uroot -ppassword
drop database if exists dbtest;
CREATE DATABASE dbtest;
GRANT ALL PRIVILEGES ON dbtest.* TO dbtestuser@localhost IDENTIFIED BY 'dbpassword';
use dbtest;
drop table if exists custdetails;
create table if not exists custdetails ( name VARCHAR(30) NOT NULL DEFAULT '', address VARCHAR(30) NOT NULL DEFAULT '' );
insert into custdetails (name,address) values ('Emmett Traynor', 'Cavan');
select * from custdetails;
FINISH

# add more tests here

# tar package back up
tar -zcvf webpackage_preDeploy.tgz WebApp

# check that ERRORCHECK is not 0
if [ $ERRORCHECK -eq 0 ]
then
	# backup content
	# mysqldump > db_backup
	# scp -i keypair1.pem db_backup testuser@whatever_backup_server_ip_is

	# move webpackage + scripts to deployment server
	echo "Moving to Production server" >> ~/DeploymentScripts/log.txt
	scp -i ~/keypair1.pem webpackage_preDeploy.tgz igayvhmsqinrwe@ec2-54-221-249-3.compute-1.amazonaws.com:~
	scp -i ~/keypair1.pem ~/DeploymentScripts/logmon.sh igayvhmsqinrwe@ec2-54-221-249-3.compute-1.amazonaws.com:~
	scp -i ~/keypair1.pem ~/DeploymentScripts/deploy.sh igayvhmsqinrwe@ec2-54-221-249-3.compute-1.amazonaws.com:~
	scp -i ~/keypair1.pem ~/DeploymentScripts/sendmail.pl igayvhmsqinrwe@ec2-54-221-249-3.compute-1.amazonaws.com:~

	# ssh into AWS instance
	ssh -i ~/keypair1.pem igayvhmsqinrwe@ec2-54-221-249-3.compute-1.amazonaws.com 'sudo bash deploy.sh'

	echo "Deployment completed successfully." >> ~/DeploymentScripts/log.txt
else
	echo "Errors in Build, Integration or Test Phase... exiting..." >> ~/DeploymentScripts/log.txt
	exit
fi
