#!/bin/bash

set -xe

CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${CONFIG_DIR}/common.sh

wait_cloud_init() {
  echo "waiting 90 seconds for cloud-init to update /etc/apt/sources.list"

  timeout 90 /bin/bash -c \
    'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'
}

PORT=$1
DOMAIN=$2
HTPASSWD=$3
SSL_CERTIFICATE=/etc/ssl/certs/private_t2d.crt
SSL_CERTIFICATE_KEY=/etc/ssl/private/private_t2d.key
NGINX_SITES_PATH=/etc/nginx/sites-enabled
HTPASSWD_PATH=/etc/nginx/.htpasswd

make_default_directories() {
  sudo mkdir -pv /etc/nginx
  sudo mkdir -pv /etc/ssl
  sudo cp -r $CONFIG_DIR/etc/ssl/* /etc/ssl
}

generate_htpasswd_file() {
  sudo echo $HTPASSWD > $HTPASSWD_PATH
}

generate_nginx_config() {
  sudo cat > $NGINX_SITES_PATH/$DOMAIN << EOF
  server {
    listen 0.0.0.0:80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://$DOMAIN\$request_uri;
  }

  server {
    listen 0.0.0.0:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    if (\$host = 'www.$DOMAIN' ) {
      rewrite  ^/(.*)$  http://$DOMAIN/\$1  permanent;
    }

    ssl_certificate $SSL_CERTIFICATE;
    ssl_certificate_key $SSL_CERTIFICATE_KEY;

    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:20m;
    ssl_prefer_server_ciphers on;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH;

    ignore_invalid_headers off;
    client_max_body_size 0;
    client_body_timeout 1d;
    proxy_buffering off;
    proxy_read_timeout 1d;
    proxy_connect_timeout 1d;
    proxy_send_timeout 1d;

    location /t2d_iam {
      auth_basic "Private Property";
      auth_basic_user_file $HTPASSWD_PATH;
      proxy_pass http://127.0.0.1:$PORT/t2d_iam/;
      proxy_intercept_errors on;
      error_page 404 /404_not_found;
    }

    location /t2d_admin_server {
      auth_basic "Private Property";
      auth_basic_user_file $HTPASSWD_PATH;
      proxy_pass http://127.0.0.1:$PORT/t2d_admin_server/;
      proxy_intercept_errors on;
      error_page 404 /404_not_found;
    }

    location = / {
      rewrite ^(.*)$ /home\$1 permanent;
      proxy_pass http://127.0.0.1:$PORT/;
      proxy_intercept_errors on;
      error_page 404 /404_not_found;
    }

    location / {
      proxy_pass http://127.0.0.1:$PORT/;
      proxy_intercept_errors on;
      error_page 404 /404_not_found;
    }
  }
EOF
}

restart_nginx_service() {
  if sudo systemctl is-active --quiet nginx.service; then
    sudo systemctl restart nginx.service
  else
    sudo systemctl start nginx.service
  fi
}

wait_cloud_init
make_default_directories
generate_htpasswd_file
generate_nginx_config
restart_nginx_service
