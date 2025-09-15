#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo)." >&2
  exit 1
fi

APP_DIR=/var/www/kilang-cctv
REPO_DIR=/opt/kilang-cctv
PHP_VER=8.3

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y software-properties-common ca-certificates curl git unzip gnupg lsb-release
add-apt-repository -y ppa:ondrej/php || true
apt-get update -y
apt-get install -y php${PHP_VER} php${PHP_VER}-fpm php${PHP_VER}-cli php${PHP_VER}-mbstring php${PHP_VER}-xml php${PHP_VER}-curl php${PHP_VER}-bcmath php${PHP_VER}-sqlite3 php${PHP_VER}-gd php${PHP_VER}-intl php${PHP_VER}-zip php${PHP_VER}-redis
apt-get install -y ffmpeg redis-server supervisor nginx

# Node.js 22 LTS
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Composer
curl -sS https://getcomposer.org/installer -o composer-setup.php
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f composer-setup.php

# Create Laravel app if not exists
if [[ ! -d "$APP_DIR" ]]; then
  mkdir -p "$APP_DIR"
  composer create-project laravel/laravel:^12.0 "$APP_DIR"
fi

cd "$APP_DIR"

# ENV
if [[ ! -f .env ]]; then
  cp .env.example .env
fi

php artisan key:generate || true

# Permissions
chown -R www-data:www-data "$APP_DIR"
find storage -type d -exec chmod 775 {} \;
find bootstrap/cache -type d -exec chmod 775 {} \;

# Nginx site
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
if [[ -f "$REPO_DIR/deploy/nginx/site.conf" ]]; then
  ln -sf "$REPO_DIR/deploy/nginx/site.conf" /etc/nginx/sites-available/kilang-cctv.conf
  ln -sf /etc/nginx/sites-available/kilang-cctv.conf /etc/nginx/sites-enabled/kilang-cctv.conf
fi

nginx -t && systemctl reload nginx || true

# Supervisor programs
if [[ -d "$REPO_DIR/deploy/supervisor" ]]; then
  ln -sf "$REPO_DIR/deploy/supervisor/laravel-worker.conf" /etc/supervisor/conf.d/laravel-worker.conf
  ln -sf "$REPO_DIR/deploy/supervisor/ffmpeg-streamer.conf" /etc/supervisor/conf.d/ffmpeg-streamer.conf
  supervisorctl reread || true
  supervisorctl update || true
fi

systemctl enable --now php${PHP_VER}-fpm redis-server supervisor

echo "VPS provisioning completed. App: $APP_DIR"