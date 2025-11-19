#!/bin/bash

# Prompt user for group name to create

#echo "Group Name:"
read -p "Enter a Group to be created:" name

# Create Group
sudo groupadd "$name" && echo "Group '$name' created"
sudo mkdir -p /groupdirectories/"$name" && echo "Directory for group '$name' created"
sudo chown -hR root:"$name" /groupdirectories/"$name"
sudo chmod 760 /groupdirectories/"$name"


# Testing Scripts
# echo $groupname
