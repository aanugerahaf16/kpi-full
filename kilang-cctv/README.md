# Monitoring CCTV - Kilang Pertamina Internasional RU VI Balongan

This repository contains deployment scaffolding and scripts to provision a fullstack Laravel 12 + Filament v4 application with TailwindCSS v4, Redis, FFmpeg, Leaflet, Laravel Excel, and realtime broadcasting.

## Quick Start (VPS, bare-metal)

1) SSH to your VPS (Ubuntu 22.04/24.04 recommended), then upload this folder `kilang-cctv` to `/opt/kilang-cctv`.

2) Run installer (as root or sudo):

```
sudo bash /opt/kilang-cctv/deploy/install_vps.sh
```

This will install PHP 8.3, Composer, Node.js, Redis, FFmpeg, Nginx, Supervisor, and bootstrap a Laravel 12 app at `/var/www/kilang-cctv`.

3) Copy env sample and edit Gmail SMTP + app URL:

```
cd /var/www/kilang-cctv
cp .env.example .env
# Or use the prefilled sample
cp /opt/kilang-cctv/deploy/env.example .env
nano .env
```

4) Initialize app:

```
php artisan key:generate
php artisan migrate --force
php artisan storage:link
npm ci && npm run build
sudo systemctl restart php8.3-fpm
sudo systemctl restart nginx
sudo systemctl enable --now supervisor
```

5) Start queues and echo server via Supervisor:

```
sudo ln -sf /opt/kilang-cctv/deploy/supervisor/laravel-worker.conf /etc/supervisor/conf.d/laravel-worker.conf
sudo ln -sf /opt/kilang-cctv/deploy/supervisor/ffmpeg-streamer.conf /etc/supervisor/conf.d/ffmpeg-streamer.conf
sudo supervisorctl reread && sudo supervisorctl update && sudo supervisorctl status
```

6) Point your domain DNS to the server IP, then adjust Nginx site config:

```
sudo ln -sf /opt/kilang-cctv/deploy/nginx/site.conf /etc/nginx/sites-available/kilang-cctv.conf
sudo ln -sf /etc/nginx/sites-available/kilang-cctv.conf /etc/nginx/sites-enabled/kilang-cctv.conf
sudo nginx -t && sudo systemctl reload nginx
```

Optionally issue SSL with certbot.

## Quick Start (Docker)

1) Install Docker and Docker Compose.

2) From `/opt/kilang-cctv/deploy/docker` run:

```
docker compose up -d --build
```

3) Exec into app container to finish setup:

```
docker compose exec app bash -lc "cp .env.example .env && php artisan key:generate && php artisan migrate --force && php artisan storage:link && npm ci && npm run build"
```

## Features and Packages (installed by scripts)

- Laravel 12
- Filament v4 (admin panel, starter auth)
- Laravel Breeze (Blade) for user UI auth
- TailwindCSS v4
- Spatie Permission (roles: admin_cpanel, user_interface)
- Laravel Excel
- Redis + Laravel Echo + laravel-echo-server
- FFmpeg + protonemedia/laravel-ffmpeg (RTSP to HLS in `public/live`)
- Leaflet + OSM/Satellite toggle

## Gmail SMTP (.env)

Use an App Password (2FA required) instead of your raw Gmail password.

```
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=you@gmail.com
MAIL_PASSWORD=your_app_password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=you@gmail.com
MAIL_FROM_NAME="KILANG PERTAMINA INTERNASIONAL"
```

## Next Steps in App (after bootstrap)

- php artisan breeze:install blade
- composer require filament/filament spatie/laravel-permission maatwebsite/excel predis/predis protonemedia/laravel-ffmpeg php-ffmpeg/php-ffmpeg
- php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" --tag="migrations"
- php artisan migrate
- php artisan make:filament-user (or use Filament auth scaffolding per v4 docs)
- Build Filament Resources: User, Building, Room, CctvCamera, Contact, Notification
- Implement streaming job runner command to convert RTSP to HLS and manage processes via Supervisor

See files under `deploy/` for system service configs.