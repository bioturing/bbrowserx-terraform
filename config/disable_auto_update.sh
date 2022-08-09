#! /usr/bin/env bash

set -xe

CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${CONFIG_DIR}/common.sh

wait_cloud_init() {
  echo "waiting 90 seconds for cloud-init to update /etc/apt/sources.list"

  timeout 90 /bin/bash -c \
    'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'
}

run() {
  cd $CONFIG_DIR
  sudo cat > "20auto-upgrades" << EOF
  APT::Periodic::Update-Package-Lists "0";
  APT::Periodic::Download-Upgradeable-Packages "0";
  APT::Periodic::AutocleanInterval "0";
  APT::Periodic::Unattended-Upgrade "0";
EOF

  sudo mv "20auto-upgrades" "/etc/apt/apt.conf.d/20auto-upgrades" &&\
  sudo apt purge --auto-remove unattended-upgrades -y &&\
  sudo systemctl disable apt-daily-upgrade.timer &&\
  sudo systemctl mask apt-daily-upgrade.service &&\
  sudo systemctl disable apt-daily.timer &&\
  sudo systemctl mask apt-daily.service
}

wait_cloud_init

run
