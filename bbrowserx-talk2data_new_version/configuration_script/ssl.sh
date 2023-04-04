#!/bin/bash


echo "Kindly make sure you have SSL certificate handy with this server."

echo " "

echo "You can generate certificate using Let's encrypt but domain should be public"

sudo mkdir -p /config/ssl
sudo mv tls.crt /config/ssl
sudo mv tls.key /config/ssl

ls -lhrt /config/ssl

