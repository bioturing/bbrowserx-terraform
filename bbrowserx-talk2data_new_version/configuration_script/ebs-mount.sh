#!/bin/bash

echo "User data and app data partition creation started"

sudo mkfs.ext4 /dev/sdb
sudo mkdir /data
sudo mount /dev/sdb /data
sudo mkdir /data/app_data
sudo mkdir /data/user_data

sudo df
