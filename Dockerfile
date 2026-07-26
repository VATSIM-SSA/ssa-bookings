# Production image for VATSSA BMAC (bookings).
# Repo ships only Laravel Sail (dev) — this is the prod build.
# Multi-stage: build frontend assets with Node, then serve via PHP-Apache.

# ---------- build frontend (Laravel Mix -> public/) ----------
FROM node:20-alpine AS frontend
WORKDIR /app
COPY package.json package-lock.json webpack.mix.js ./
RUN npm ci
COPY resources/ resources/
COPY public/ public/
RUN npm run build

# ---------- final PHP-Apache image ----------
FROM php:8.1-apache-bookworm

EXPOSE 80

# System deps + Apache rewrite
RUN apt-get update && \
    apt-get install -y git unzip ca-certificates curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    a2enmod rewrite

# PHP extensions BMAC needs (Laravel 9 + Horizon + Excel + image handling)
COPY --from=mlocati/php-extension-installer:2.7.5 /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_mysql opcache zip gd bcmath intl exif pcntl

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Point Apache at Laravel's public/ dir
COPY deploy/apache-vhost.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

# App code
COPY . /var/www/html
# Built assets from the frontend stage (overwrites public/js|css + mix-manifest)
COPY --from=frontend /app/public /var/www/html/public

# PHP deps (no dev). --no-scripts: post-autoload-dump runs `artisan
# package:discover`, which boots the app and needs a .env we don't ship at
# build time. Laravel rebuilds the package manifest lazily on first request,
# so skipping scripts here is safe and avoids a build-time env dependency.
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader --no-scripts && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

COPY deploy/entrypoint.sh /usr/local/bin/bmac-entrypoint
RUN chmod +x /usr/local/bin/bmac-entrypoint

ENTRYPOINT ["bmac-entrypoint"]
CMD ["apache2-foreground"]
