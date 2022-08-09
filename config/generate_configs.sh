#! /usr/bin/env bash

set -xe

CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${CONFIG_DIR}/common.sh

PORT=$1
DOMAIN=$2
TOKEN=$3

wait_cloud_init() {
  echo "waiting 90 seconds for cloud-init to update /etc/apt/sources.list"

  timeout 90 /bin/bash -c \
    'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'
}

run() {
  cd /data/app_data
  sudo cat > "configs.json" << EOF
  {
      "host": "0.0.0.0",
      "port": $PORT,
      "has_gpu": "TRUE",
      "private_t2d_host": "https://update.bioturing.com",
      "user_data": "/data/user_data",
      "base_url": "https://${DOMAIN}",
      "validation_string": "",
      "datapath": "/data/app_data/t2d_data",
      "temppath": "/data/app_data/t2d_temp",
      "logspath": "/data/app_data/t2d_logs",
      "token": "${TOKEN}"
  }
EOF
}

wait_cloud_init

run
