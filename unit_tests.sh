timestamp() {
    date +"%T"
}

# append timestamp to log file so each set of log messages is identifiable
echo $(timestamp) >> ~/DeploymentProject/TestLogs/unit_test_log.txt

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

function isRunning {
	PROCESS_NUM=$(ps -ef | grep "$1" | grep -v "grep" | wc -l)
	if [ $PROCESS_NUM -gt 0 ]; then
		echo $PROCESS_NUM
		return 1
	else
		return 0
	fi
}

function isTCPlisten {
	TCPCOUNT=$(netstat -tupln | grep tcp | grep "$1" | wc -l)
	if [ $TCPCOUNT -gt 0 ]; then
		return 1
	else
		return 0
	fi
}

function isUDPlisten {
	UDPCOUNT=$(netstat -tupln | grep udp | grep "$1" | wc -l)
	if [ UDPCOUNT -gt 0 ]; then
		return 1
	else
		return 0
	fi
}

function isTCPremoteOpen {
	timeout 1 bash -c "echo > /dev/tcp/$1/$2" && return 1 || return 0
}

function isIPalive {
	PINGCOUNT=$(ping -c 1 "$1" | grep "1 received" | wc -l)
	if [ $PINGCOUNT -gt 0 ]; then
		return 1
	else
		return 0
	fi
}

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

# Functions to test

isApacheRunning
if [ "$?" -eq 1 ]; then
	echo PASS: Apache Process is Running >> ~/DeploymentProject/TestLogs/unit_test_log.txt
else
	echo FAIL: Apache Process is NOT running >> ~/DeploymentProject/TestLogs/unit_test_log.txt
fi

isApacheListening
if [ "$?" -eq 1 ]; then
	echo PASS: Apache is Listening >> ~/DeploymentProject/TestLogs/unit_test_log.txt
else
	echo FAIL: Apache is NOT listening >> ~/DeploymentProject/TestLogs/unit_test_log.txt
fi

isApacheRemoteUp
if [ "$?" -eq 1 ]; then
	echo PASS: Remote Apache TCP port is UP >> ~/DeploymentProject/TestLogs/unit_test_log.txt
else
	echo FAIL: Remote Apache TCP port is DOWN >> ~/DeploymentProject/TestLogs/unit_test_log.txt
fi

isMysqlRunning
if [ "$?" -eq 1 ]; then
	echo PASS: mySQL process is Running >> ~/DeploymentProject/TestLogs/unit_test_log.txt
else
	echo FAIL: mySQL process is NOT Running >> ~/DeploymentProject/TestLogs/unit_test_log.txt
fi

isMysqlListening
if [ "$?" -eq 1 ]; then
	echo PASS: mySQL is listening >> ~/DeploymentProject/TestLogs/unit_test_log.txt
else
	echo FAIL: mySQL is NOT listening >> ~/DeploymentProject/TestLogs/unit_test_log.txt
fi

isMysqlRemoteUp
if [ "$?" -eq 1 ]; then
	echo PASS: Remote mySQL TCP port is UP >> ~/DeploymentProject/TestLogs/unit_test_log.txt
else
	echo FAIL: Remote mySQL TCP port is DOWN >> ~/DeploymentProject/TestLogs/unit_test_log.txt
fi

isSomethingPingable
if [ "$?" -eq 1 ]; then
	echo PASS: Network is alive >> ~/DeploymentProject/TestLogs/unit_test_log.txt
else
	echo FAIL: Network is not alive >> ~/DeploymentProject/TestLogs/unit_test_log.txt
fi

checkCPU
if [ "$?" -eq 1 ]; then
	echo PASS: CPU usage is ok >> ~/DeploymentProject/TestLogs/unit_test_log.txt
else
	echo FAIL: CPU usage is not ok >> ~/DeploymentProject/TestLogs/unit_test_log.txt
fi
