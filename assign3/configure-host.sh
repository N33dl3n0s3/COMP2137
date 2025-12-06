#!/bin/bash

# =====================
# Assignment 3
# Aaron Thistle
# Student No. 200635336
# =====================

# ==============
# Block Signals:
# ==============

trap "" HUP INT TERM

# =================
# Initial Variables:
# =================

verboseOutput=false
desiredName=""
desiredIPAddress=""
hostEntryDesiredName=""
hostEntryDesiredIPAddress=""

# =================
# Helper Functions:
# =================

logVerbose() {
    if [ "$verboseOutput" = true ]; then
        echo "$1"
    fi
}

logChange() {
    logger -t "remoteConfig" "$1"
    logVerbose "$1"
}

logError() {
    local errorMsg="Error: $1"
    logger -s -t "remoteConfigError" "$errorMsg"
    exit 1
}

# ==================
# Option Handling:
# ==================


while [ $# -gt 0 ]; do
    case "$1" in
        -verbose )
            verboseOutput=true
            shift
            ;;
        -name )
            shift
            desiredName="$1"
            shift
            ;;
        -ip )
            shift
            desiredIPAddress="$1/24"
            shift
            ;;
        -hostentry )
            shift
            hostEntryDesiredName="$1"
            shift
            hostEntryDesiredIPAddress="$1"
            shift
            ;;
    esac
done
# ==========
# Execution:
# ==========

# =================
# Hostname: (-name desiredName)
# =================

hostnameFunction() {
    if [ -n "$desiredName" ]; then
        currentName=$(hostname)

        if [[ "$currentName" == "$desiredName" ]]; then
            logVerbose "Hostname is already set to '$desiredName'. No Changes made."
            return
        else
            if ! hostnamectl set-hostname "$desiredName"; then
                logError "Failed to set hostname to '$desiredName'."
            else
                logChange "hostname set to $desiredName."
            fi
        fi

        if grep -qw "$currentName" /etc/hosts; then
            sed -i -E "s/(^|[[:space:]])$currentName($|[[:space:]])/\1$desiredName\2/g" /etc/hosts || logError "failed to update /etc/hosts"
            logChange "Updated hostname from $currentName to $desiredName in /etc/hosts"        
        elif grep -q "^127\.0\.1\.1" /etc/hosts; then
            sed -i "s/^127\.0\.1\.1[[:space:]]\+.*/127.0.1.1 $desiredName/" /etc/hosts || logError "Failed to update 127.0.1.1 entry in /etc/hosts"
            logChange "Replaced existing 127.0.1.1 entry with $desiredName in /etc/hosts"
        else
            echo "127.0.1.1 $desiredName" >> /etc/hosts || logError "Failed to append new entry in /etc/hosts"
            logChange "Added new 127.0.1.1 entry for $desiredName in /etc/hosts"
        fi

    echo "$desiredName" > /etc/hostname

    else 
        logError "Desired Name is empty or unset"
    fi
}
# ==============================
# Set IP: (-ip desiredIPAddress)
# ==============================

# ====================================
# Confirm Environment Before Changing:
# ====================================

iPFunction () {
    if [ -n "$desiredIPAddress" ]; then
        defaultInterface=$(ip route | grep default | awk '{print $5}' | head -n1)
    
        if [ -z "$defaultInterface" ]; then
            logError "Could not detect a default LAN interface."
        else
            logVerbose "Default interface confirmed as $defaultInterface."
        fi

        currentIPAddress=$(ip -br addr show "$defaultInterface" | awk '{print $3}')
        if [ -z "$currentIPAddress" ]; then
            logError "Could not determine current IP address for $defaultInterface."
        fi
    
        if [[ "$currentIPAddress" == "$desiredIPAddress" ]]; then
            logVerbose "Interface $defaultInterface is already configured with $desiredIPAddress, no changes made."
            return
        else
            logVerbose "IP address before changes is $currentIPAddress."
            netplanFile=$(find /etc/netplan -maxdepth 1 -name "*.yaml" -type f \
            -exec grep -l "$defaultInterface" {} +)
        fi

        if [ -z "$netplanFile" ]; then
            logError "No Netplan file found that matches default interface."
        else
            logVerbose "$defaultInterface found in $netplanFile."
        fi

# =================================================
# Make Changes and Test Before Full Implementation:
# =================================================

        if ! sed -i "s@$currentIPAddress@$desiredIPAddress@1" "$netplanFile"; then
            logError "Failed to update address in $netplanFile."
        else
            logChange "Netplan updated with $desiredIPAddress."
        fi

        logVerbose "testing new netplan configuration. If a connection issue occurs please try again shortly"
        if netplan try --timeout=15; then
            updatedIPAddress=$(ip -br addr show "$defaultInterface" | awk '{print $3}')
            if [ "$updatedIPAddress" == "$desiredIPAddress" ]; then
                if netplan apply; then
                    logVerbose "IP was changed successfully."
                    hostnameDuringIP=$(hostname)
                    cleanedIPAddress="${desiredIPAddress%%/*}"
                    if ! grep -E -qe "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+$hostnameDuringIP" /etc/hosts; then
                        echo "$cleanedIPAddress $hostnameDuringIP" >> /etc/hosts
                        logChange "existing hosts entry for $hostnameDuringIP not found. Created new Entry in /etc/hosts."
                    else
                        sed -i -E "s@^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)([[:space:]]+$hostnameDuringIP)@$cleanedIPAddress\2@" /etc/hosts
                        logChange "Updated entry for $hostnameDuringIP in /etc/hosts"
                    fi
                else
                    logError "IP Changes failed at netplan Apply"
                fi
            else
            logError "IP was not updated correctly in $netplanFile during netplan try"
            fi
        else
        logError "Netplan Try failed to run."
        fi
    else
        logError "a desired IP was not provided. please enter an IP formatted 'x.x.x.x/x'."
    fi
}
# ================================================================
# Host Entry: (-hostentry hostEntryDesiredName hostEntryDesiredIP)
# ================================================================
hostEntryFunction() {
    if [ -n "$hostEntryDesiredName" ] && [ -n "$hostEntryDesiredIPAddress" ]; then
        logVerbose "Checking for entry that matches inputs in /etc/hosts."
    
        if grep -q "[[:space:]]$hostEntryDesiredName\$" /etc/hosts; then 
            logVerbose "Entry for $hostEntryDesiredName found in /etc/hosts"
            entryIP=$(grep "[[:space:]]$hostEntryDesiredName\$" /etc/hosts | awk '{print $1}')
        
            if [ "$entryIP" = "$hostEntryDesiredIPAddress" ]; then
                logVerbose "Entry already exists in /etc/hosts"
            
            else
                logVerbose "Current entry for $hostEntryDesiredName IP will be updated."
                sed -i "s/^$entryIP[[:space:]]\+$hostEntryDesiredName\$/$hostEntryDesiredIPAddress $hostEntryDesiredName/" /etc/hosts
                logChange "/etc/hosts entry updated with $hostEntryDesiredIPAddress"    
            fi
    
        else
            logVerbose "Creating new entry in /etc/hosts."
            echo "$hostEntryDesiredIPAddress $hostEntryDesiredName" >> /etc/hosts
        fi

    else
        logError "Please make sure that a desired name and desired IP have been provided."
    fi
}

# ==========
# Execution:
# ==========

[ -n "$desiredName" ] && hostnameFunction
[ -n "$desiredIPAddress" ] && iPFunction
[ -n "$hostEntryDesiredName" ] && [ -n "$hostEntryDesiredIPAddress" ] && hostEntryFunction