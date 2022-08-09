#!/bin/bash

set -xe

CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${CONFIG_DIR}/common.sh

wait_cloud_init() {
  echo "waiting 90 seconds for cloud-init to update /etc/apt/sources.list"

  timeout 90 /bin/bash -c \
    'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'
}

install_common_packages() {
  sudo apt update && sudo apt upgrade -y && \
  sudo apt install build-essential curl gnupg lsb-release ca-certificates nginx xfsprogs -y
}

wait_cloud_init
install_common_packages
