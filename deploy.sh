#!/bin/bash

timestamp() {
	date +"%T"
}

# log timestamp to file to make errors more identifiable
echo $(timestamp) >> ~/MyLogs/deploy_log.txt

# create sandbox
SANDBOX=sandbox_$RANDOM
cd /tmp
mkdir $SANDBOX
cd $SANDBOX

# test resources
# check memory
top

# check disk
df -h

# check network
netstat

# clean environment ie un- and re-install apache and mysql
# stop services
echo "Stopping services" >> ~/MyLogs/deploy_log.txt
service apache2 stop
service mysql stop

# uninstall
echo "Uninstalling Apache and mySQL" >> ~/MyLogs/deploy_log.txt
apt-get -q -y remove apache2
apt-get -q -y remove mysql-client mysql-server
echo mysql-server mysql-server/root_password password password | debconf-set-selections
echo mysql-server mysql-server/root_password_again password password Z debconf-set-selections

# update apt repo
apt-get update

# reinstall
echo "Reinstalling Apache and mySQL" >> ~/MyLogs/deploy_log.txt
apt-get -q -y install apache2
apt-get -q -y install mysql-client mysql-server

# restart services
echo "Restarting services" >> ~/MyLogs/deploy_log.txt
service apache2 start
service mysql start

cd ~

# untar app
tar -zxvf webpackage_preDeploy.tgz WebApp

# move components to /www and /cgi-bin
echo "Moving components" >> ~/MyLogs/deploy_log.txt
cp ~/WebApp/www/* /var/www
cp ~/WebApp/cgi-bin/* /usr/lib/cgi-bin

# make scripts executable
chmod a+x /usr/lib/cgi-bin/*

# test necessary files are in place
DEPINDEX="/var/www/index.html"
DEPAFPL="/usr/lib/cgi-bin/accept_form.pl"
DEPHW="/usr/lib/cgi-bin/hello_world.pl"
DEPTDB="/usr/lib/cgi-bin/testdb.pl"
if [ -e "$DEPINDEX" ] && [ -e "$DEPAFPL" ] && [ -e "$DEPHW" ] && [ -e "$DEPTDB" ]
then
	echo "All files in place" >> ~/MyLogs/deploy_log.txt
else
	echo "Files not in place, exiting..." >> ~/MyLogs/deploy_log.txt
	exit
fi

# configure crontab to run monitoring script
# configure crontab, make sure new cron job is unique

echo "Setting up monitoring Cron job" >> ~/MyLogs/deploy_log.txt
(crontab -l ; echo "40 15 * * * bash ~/logmon.sh") | uniq - | crontab -

# run monitoring script because Cron is being annoying and not working
bash ~/logmon.sh

echo "A new version of your Web Application has been successfully deployed LIVE" >> ~/MyLogs/deploy_log.txt | perl ~/sendmail.pl $ADMINISTRATOR $MAILSERVER
exit
