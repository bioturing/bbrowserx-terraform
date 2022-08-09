#! /usr/bin/env bash

set -xe

CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${CONFIG_DIR}/common.sh

wait_cloud_init() {
  echo "waiting 90 seconds for cloud-init to update /etc/apt/sources.list"

  timeout 90 /bin/bash -c \
    'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'
}

install() {
  sudo apt install linux-headers-$(uname -r) &&\
  distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g') &&\
  wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-keyring_1.0-1_all.deb &&\
  sudo dpkg -i cuda-keyring_1.0-1_all.deb &&\
  sudo apt update &&\
  sudo apt -y install cuda-drivers
}

wait_cloud_init

install
