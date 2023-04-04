#!/bin/bash

echo "To change the configuration for /dev/shm, add one line to /etc/fstab"

sudo chmod 666 /etc/fstab

sudo echo "tmpfs /dev/shm tmpfs defaults,size=64g 0 0" >> /etc/fstab

sudo cat /etc/fstab

sudo chmod 644 /etc/fstab
