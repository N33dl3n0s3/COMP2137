#!/bin/bash

#run to see a list of current Hardware Specs.

hwinfo --cpu --short
hwinfo --memory
hwinfo --short --block
df -h
hwinfo --network interface --short | grep Ethernet
ip addr | grep enp0s3 | grep inet
