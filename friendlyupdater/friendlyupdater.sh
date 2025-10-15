#!/bin/bash

# creating the log early
find ./tmp >/dev/null 2>&1 || mkdir ./tmp
logFile="./tmp/friendlyupdater.$$"
echo "all logs will go to $logFile" #remove this line when finished

# First command to check if user is root
if [ $EUID -ne 0 ]; then
	echo "You are not root. Please use sudo to proceed."
	exit 1
else
	echo "You are root. Proceeding to check for updates."
fi

# run apt update only share success or fail

apt update >> "$logFile" 2>&1
if [ $? -ne 0 ]; then 
	echo "apt update has failed."
	exit 1
else
	echo "apt update finished succesfully."
	upgradesAvailable=$(grep -w "packages" "$logFile" | awk '{print $1}')
	echo "there are $upgradesAvailable upgrades ready"
fi

# First prompt to continue
read -p "Do you want to proceed to check available space? (y/n): " firstResponse
if [[ "${firstResponse,,}" != "y" ]]; then
	echo "Ending updater"
	exit 0
fi
echo "the user said yes"

# Provide available disk space
df -h | grep sda | awk '{print "There is " $4 " available on " $1 }'

# Second prompt to continue
read -p "Do you want to proceed with upgrade? (y/n): " secondResponse
if [[ "${secondResponse,,}" != "y" ]]; then
	echo "Ending updater"
	exit 0
fi

# Upgrade if yes
apt upgrade -y >> "$logFile" 2>&1
if [ $? -ne 0 ]; then 
	echo "upgrage has failed."
	exit 1
else
	echo "upgrade finished succesfully."
	df -h | grep sda | awk '{print "There is " $4 " remaining on " $1 }'
fi
echo "have a nice day"
