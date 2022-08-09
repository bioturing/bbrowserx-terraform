#!/bin/bash

set -xe

CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${CONFIG_DIR}/common.sh

wait_cloud_init() {
  echo "waiting 90 seconds for cloud-init to update /etc/apt/sources.list"

  timeout 90 /bin/bash -c \
    'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'
}

mount_ebs_volume() {
  sudo mkfs -t ext4 /dev/nvme2n1
  sudo mkdir /data
  sudo mount /dev/nvme2n1 /data
}

make_default_directories() {
  sudo mkdir /data/app_data
  sudo mkdir /data/user_data
}

wait_cloud_init
mount_ebs_volume
make_default_directories
