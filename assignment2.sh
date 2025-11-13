#!/bin/bash

#==============
# Assignment 2
# Aaron Thistle
#===============

# ====================================
# Preset Variables for network section
# ====================================

desiredAddress="192.168.16.21/24" # Change this if for different target host addresses
targetNetwork="192.168.16"        # Use this variable to designate the network address where you are modifying the host address of this computer
netplanDirectory="/etc/netplan"   # Netplan files should be located here and if they are not then someone needs to be commited

# =============================================================================
# This section is only to be used when operating in safe testing file environments
# =============================================================================

testnet=~/testnet.yaml
rm "$testnet" 2>/dev/null

# ======================================================
# Find Netplan file and confirm network address presence
# ======================================================

echo "Checking for netplan file with an address configured on $targetNetwork network."

netplanFile=$(find "$netplanDirectory" -maxdepth 1 \
	-type f \
	-name "*.yaml" \
	-print0 | xargs -0 grep -l "$targetNetwork\.[0-9]\+/[0-9]\+")
if [ -z "$netplanFile" ]; then
	echo "ERROR: Could not locate a netplan file containing the $networkAddress network."
	exit 1
fi

echo "found $netplanFile" # This is simply a feedback command

# =======================================================================================================
# Check current configuration of the netplan file and confirm that the correct netowrk address is present
# =======================================================================================================

echo "Checking current configuration of $netplanFile:"

currentAddress=$(grep -E "$targetNetwork\.[0-9]+/[0-9]+" "$netplanFile" | head -n 1 | awk '{print $NF}' | tr -d '",[]')

if [ -z "$currentAddress" ]; then
	echo "ERROR: Could not locate an eligible address to modify on $targetNetwork network. Please check $netplanFile manually."
	exit 1
fi


echo "Confirmed current address is $currentAddress on $targetNetwork network. " # This is another feedback command

# =========================================================================================================
# Testing function to modify a relocated safe copy of the netplan to be used if the script is ever modified
# =========================================================================================================

cp "$netplanFile" "$testnet"
netplanFile="$testnet"
echo "modifying $testnet"

# ======================================================================
# Change the address only if it needs to be changed and if so, change it
# ======================================================================

if [ "currentAddress" == "$targetAddress" ]; then
	echo "The current configuration is correct. Moving on."
else
	echo "updating current address: $currentAddress to the desired address: $desiredAddress."
	sed -i "s@$currentAddress@$desiredAddress@1" "$netplanFile"
	if [ $? -ne 0 ]; then
	echo "an issue occured please check the netplan file and/or restore a backup copy."
	exit 1
	fi
fi

echo "Changes successfully implemented in $netplanFile, applying changes now"
netplan apply

# ==========================
# Variables related to hosts
# ==========================

hostsFile="/etc/hosts"
desiredHostAddress=${desiredAddress%/*}
targetHost="server1"
hostsChange="$desiredHostAddress\t$targetHost"

# ===========================================================
# Copy and modify safe hosts file if script has been modified
# ===========================================================

hostsTest=~/hostsTest
rm "$hostsTest" 2>/dev/null
cp "$hostsFile" "$hostsTest"
hostsFile="$hostsTest"
echo "modifying $hostsFile"

# ===============================
# Change /etc/hosts configuration
# ===============================

echo "Starting modification of hosts."
if grep -qE "^$desiredHostAddress\s+$targetHost\s*$" "$hostsFile"; then
	echo "Entry in hosts is already correctly configured."
else
	echo "Entry in hosts requires modification, updating now."
	sed -i -E "/^$targetNetwork\.[0-9]+\s+$targetHost/d" "$hostsFile"
	if [ $? -ne 0 ]; then
		echo "Warning: removal of old hosts failed please check $hostsFile for any old configurations manually"
	fi
	echo -e "$hostsChange" >> "$hostsFile"
	echo "Modification of hosts has been completed"
fi
# ===================
# Software Variables:
# ===================

requiredPackages=("apache2" "squid") # Any software packages can be added to this array in order to add them.

# ========================================
# Software Presence Check andInstallation:
# ========================================

echo "Now checking if necessary software is installed."

installPackage=()

for pkg in "${requiredPackages[@]}"; do
	installStatus=$(dpkg -l "$pkg" 2>/dev/null | grep -E "^(ii|hi)\s+$pkg")
	if [ -z "$installStatus" ]; then
	installPackage+=("$pkg")
	fi
done

if [ ${#installPackage[@]} -eq 0 ]; then
	echo "All required packages are already installed"
else
	echo "Proceeding to install: ${installPackage[*]}"
	echo "running apt update..."
	if ! apt update > /dev/null 2>&1; then
		echo  "apt update failed cannot proceed to install packages"
		exit 1
	fi
	echo "apt packages list updated successfully"
	echo "${installPackage[@]}"
	if apt install -y "${installPackage[@]}" > /dev/null 2>&1; then
		echo "successfully installed ${installPackage[@]}"
	else
		echo "installation failed"
		exit
	fi
fi

# ==========================
# User Management Variables:
# ==========================

userList=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
sudoUsers=("dennis")
sudoersKey="ssh-ed25519 AAAAC3NzaC11ZDI1NTE5AAAAIG4rT3vTt990x5kndS4HmgTrKBT8SKzhK4rhGkEVG1CI student@generic-vm"
keyAlgorithm=("rsa" "ed22519")"
# ================
# User Management:
# ================

echo "Beginning user provisioning"

# -------------
# Create Users:
# -------------

for userName in "${userList[@]}"; do
	userHome="/home/$userName"
	userSshDirectory="$userHome/.ssh"
	userAuthKeys="$userSshDirectory/authorized_keys"

	echo "Adding user account $userName"

	if id -u "$userName" &>/dev/null; then
		echo "The user, $userName already exists"
	else
		echo "Creating user: $userName"
		if useradd -m -s /bin/bash "$userName"; then
			echo "User $userName created successfully!"
		else
			echo "Failed to create user $userName"
			continue
		fi
	fi

# --------------
# SSH key Setup:
# --------------

	if [ ! -d "$userSshDirectory" ]; then
		mkdir -p "userSshDirectory"
		chown "$userName:$userName" "userSshDirectory"
		chmod 700 "$userSshDirectory"
		echo "created $userSshDirectory"
	fi
	for keyType in "${keyAlgorithm[@]}"; do
		keyDirectory="$userSshDirectory/id_$keyType"
		if [ ! -f "$keyDirectory" ]; then
			echo "creating $keyType key for $userName"
			sudo -u "$userName" ssh-keygen -t "$keyType" -f "$keyDirectory" -N "" -q
			echo "Generated $keyType key for $username"
		else
			echo "$keyType key already exists"
		pubKey=$(cat "$keyDirectory.pub")
		if ! grep -qF "$pubKey" "$userAuthKeys"; then
			echo "$pubKey" >> "$userAuthKeys"
			echo "Added generated $keyType key to $userAuthKeys."
		fi
	done
	chown "$userName:$userName" "$userAuthKeys"
	chmod 600 "$userAuthKeys"

	if [[ " ${sudoUsers[@]} " =~ " ${userName} " ]]; then
		echo "Adding $userName to sudo group"
		if usermod -aG sudo "$userName" >/dev/null 2>&1; then
			echo "$userName is now a member of the sudo group"
		else
			echo "failed to add $userName to sudo group"
		fi
	fi
done
