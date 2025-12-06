#!/bin/bash
# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the local /etc/hosts file

verboseOutput=false

logError () {
    local errorMsg="Error: $1"
    logger -s -t "Lab3" "$errorMsg"
    exit 1
}

logVerbose() {
    if $verboseOutput; then
    echo "verbose: $1"
    fi
}

if [ "$1" == "-verbose" ]; then
    verboseOutput=true
    echo "Verbose mode is enabled"
fi

# check for file presence

if [ ! -f "./configure-host.sh" ]; then
    logError "host-configuration.sh file is missing"
fi

# Copy file to server1 and run
logVerbose "Copying configurehost to server1"

if scp configure-host.sh remoteadmin@server1-mgmt:/root; then
    logVerbose "File transfered to Server1 successfully."
else
    logError "Unsable to transfer to Server1."
fi
if [ "$verboseOutput" == "true" ]; then
    if ssh remoteadmin@server1-mgmt -- /root/configure-host.sh -verbose -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4; then
        logVerbose "Successfully run configure-host.sh on server1"
    else
        logError "An error occured running configure-host.sh on server1"
    fi
else
    if ssh remoteadmin@server1-mgmt -- /root/configure-host.sh -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4; then
        logVerbose "Successfully ran configure-host on server1"
    else
        logError "An error occured running configure-host.sh on server1"
    fi
fi

# copy file to server2 and run

if scp configure-host.sh remoteadmin@server2-mgmt:/root; then
    logVerbose "File successfully transfered to Server2"
else
    logError "An error occured transferring configure-host.sh to server2"
fi
if [ "$verboseOutput" == "true" ]; then
    if ssh remoteadmin@server2-mgmt -- /root/configure-host.sh -verbose -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3; then
        logVerbose "configure-host succesfully run on server2 in verbose mode"
    else
        logError "an error occured running configure-host on server2 in verbose mode"
    fi
else
    if ssh remoteadmin@server2-mgmt -- /root/configure-host.sh -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3; then
        logVerbose "successfully ran configure-host on server2"
        else
        logError "An error occured when running configure-host on server2"
    fi
fi

# run configure-host locally
if [ "$verboseOutput" == "true" ]; then
    logVerbose "updating hosts with configure-hosts.sh"
    if ./configure-host.sh -hostentry loghost 192.168.16.3; then
        logVerbose "successfully updated /etc/hosts with loghost 192.168.16.3"
    else
        logError "An error occured updating /etc/hosts with loghost."
    fi
    if ./configure-host.sh -hostentry webhost 192.168.16.4; then
        logVerbose "Succesfully updated /etc/hosts with web host at 192.168.16.4"
    else
        logError "An error occured while updating /etc/hosts with webhost."
    fi
fi