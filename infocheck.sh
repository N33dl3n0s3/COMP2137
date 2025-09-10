#!/bin/bash

echo "Hostname and Operating System:"
hostname
hostnamectl | grep Operating System
echo "Connected to internet Via:"
ip addr | grep enp0s3
echo "CPU load average" && uptime | awk '{print$6$7$8}'
echo "Total Memory:"
free -h |grep "Mem" | awk '{print$2}'
echo "Free Memory:"
free -h | grep "Mem" | awk '{print$4}'
echo "Free Space on Primary Drive:" && df -h | grep /dev/sda2 | awk '{print$4}'
