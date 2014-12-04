#!/bin/bash

# set ADMIN and MAILSERVER vars for mail script
ADMINISTRATOR=emmett.traynor@gmail.com
MAILSERVER=pop.gmail.com

timestamp() {
	date +"%T"
}

# append timestamp to log file so each set of log messages is identifiable
echo $(timestamp) >> ~/MyLogs/monitor_log.txt

# Level 1 Functions

# check if apache is running
function isApacheRunning {
	isRunning apache2
	return $?
}

# check is apache is listening
function isApacheListening {
	isTCPlisten 80
	return $?
}

# check if mysql is listening
function isMysqlListening {
	isTCPlisten 3306
	return $?
}

# check if apache remote is up
function isApacheRemoteUp {
	isTCPremoteOpen 127.0.0.1 80
	return $?
}

# check if mysql is running
function isMysqlRunning {
	isRunning mysqld
	return $?
}

# check if mysql remote is up
function isMysqlRemoteUp {
	isTCPremoteOpen 127.0.0.1 3306
	return $?
}

# check if network is available
function isSomethingPingable {
	isIPalive 127.0.0.1
	return $?
}

# check if CPU usage is ok
function checkCPU {
	getCPU top
	return $?
}

# Level 0 Functions

# function to check if service is running
# pass in apache, mysql etc
function isRunning {
	PROCESS_NUM=$(ps -ef | grep "$1" | grep -v "grep" | wc -l)
	if [ $PROCESS_NUM -gt 0 ]; then
		echo $PROCESS_NUM
		return 1
	else
		return 0
	fi
}

# function to check is service is listening on TCP
# pass in mysql, apache2 etc
function isTCPlisten {
	TCPCOUNT=$(netstat -tupln | grep tcp | grep "$1" | wc -l)
	if [ $TCPCOUNT -gt 0 ]; then
		return 1
	else
		return 0
	fi
}

# function to check if service is listenin on UDP
function isUDPlisten {
	UDPCOUNT=$(netstat -tupln | grep udp | grep "$1" | wc -l)
	if [ UDPCOUNT -gt 0 ]; then
		return 1
	else
		return 0
	fi
}

# function to check if TCP Remote is open
function isTCPremoteOpen {
	timeout 1 bash -c "echo > /dev/tcp/$1/$2" && return 1 || return 0
}

# function to check if IP is alive
function isIPalive {
	PINGCOUNT=$(ping -c 1 "$1" | grep "1 received" | wc -l)
	if [ $PINGCOUNT -gt 0 ]; then
		return 1
	else
		return 0
	fi
}

# function to check CPU usage
function getCPU {
	app_name=$1
	cpu_limit="5000"
	app_pid=`ps aux | grep $app_name | grep -v grep | awk {'print $2'}`
	app_cpu=`ps aux | grep $app_name | grep -v grep | awk {'print $3*100'}`
	if [[ $app_cpu -gt $cpu_limit ]]; then
		return 0
	else
		return 1
	fi
}

# Functional Body of Script

ERRORCOUNT=0

# checking if Apache is running, logging output, increasing ERRORCOUNT if necessary
isApacheRunning
if [ "$?" -eq 1 ]; then
	echo Apache Process is Running >> ~/MyLogs/monitor_log.txt
else
	echo Apache Process is NOT running >> ~/MyLogs/monitor_log.txt
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

# checking if Apache is listening, logging output, increasing ERRORCOUNT if necessary
isApacheListening
if [ "$?" -eq 1 ]; then
	echo Apache is Listening >> ~/MyLogs/monitor_log.txt
else
	echo Apache is NOT listening >> ~/MyLogs/monitor_log.txt
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

# checking if Apache remote is up, logging output, increasing ERRORCOUNT if necessary
isApacheRemoteUp
if [ "$?" -eq 1 ]; then
	echo Remote Apache TCP port is UP >> ~/MyLogs/monitor_log.txt
else
	echo Remote Apache TCP port is DOWN >> ~/MyLogs/monitor_log.txt
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

# checking if mySQL is running, logging output, increasing ERRORCOUNT if necessary
isMysqlRunning
if [ "$?" -eq 1 ]; then
	echo mySQL process is Running >> ~/MyLogs/monitor_log.txt
else
	echo mySQL process is NOT Running >> ~/MyLogs/monitor_log.txt
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

# checking if mySQL is listening, logging output, increasing ERRORCOUNT if necessary
isMysqlListening
if [ "$?" -eq 1 ]; then
	echo mySQL is listening >> ~/MyLogs/monitor_log.txt
else
	echo mySQL is NOT listening >> ~/MyLogs/monitor_log.txt
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

# checking if mySQL remote is up, logging output, increasing ERRORCOUNT if necessary
isMysqlRemoteUp
if [ "$?" -eq 1 ]; then
	echo Remote mySQL TCP port is UP >> ~/MyLogs/monitor_log.txt
else
	echo Remote mySQL TCP port is DOWN >> ~/MyLogs/monitor_log.txt
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

# checking if network is pingable, logging output, increasing ERRORCOUNT if necessary
isSomethingPingable
if [ "$?" -eq 1 ]; then
	echo Network is alive >> ~/MyLogs/monitor_log.txt
else
	echo Network is not alive >> ~/MyLogs/monitor_log.txt
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

# checking if CPU usage is ok, logging output, increasing ERRORCOUNT if necessary
checkCPU
if [ "$?" -eq 1 ]; then
	echo CPU usage is ok >> ~/MyLogs/monitor_log.txt
else
	echo CPU usage is not ok >> ~/MyLogs/monitor_log.txt
	ERRORCOUNT=$((ERRORCOUNT+1))
fi

# checking if errors exist, logging messages, sending mail if necessary
if [ $ERRORCOUNT -gt 0 ]
then
	echo "ERROR! ERROR! There is a problem with SOMETHING!" | perl ~/sendmail.pl $ADMINISTRATOR $MAILSERVER
	echo "Something is wrong with the production environment." >> ~/MyLogs/monitor_log.txt
else
	echo "Everything is fine" >> ~/MyLogs/monitor_log.txt
