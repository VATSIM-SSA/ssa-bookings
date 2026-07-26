# Production image for VATSSA Bookings (BMAC fork of daveroverts/bmac).
# Upstream ships only Laravel Sail (dev), so this is the prod build.
#
# Three stages: Composer vendor, Vite assets, then a PHP-Apache runtime.
# Built by GitHub Actions and published to ghcr.io/vatsim-ssa/bookings.

# ---------- composer vendor ----------
# Runs BEFORE the frontend stage on purpose: PurgeCSS scans
# vendor/laravel/framework/.../Pagination/resources/views for the Bootstrap
# pagination templates. Without vendor/ present it strips .pagination,
# .page-item and .page-link, and pagination renders as bare bullet lists.
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
# --no-scripts: post-autoload-dump runs `artisan package:discover`, which boots
# the app and needs an .env we deliberately do not ship at build time.
RUN composer install --no-dev --no-interaction --prefer-dist \
      --no-scripts --no-autoloader --ignore-platform-reqs

# ---------- frontend assets (Vite -> public/build) ----------
FROM node:22-alpine AS frontend
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
# vite-plugin-static-copy reads from resources/ and public/, so copy the tree.
COPY . .
COPY --from=vendor /app/vendor ./vendor
RUN npm run build

# ---------- runtime ----------
FROM php:8.4-apache-bookworm

EXPOSE 80

RUN apt-get update && \
    apt-get install -y --no-install-recommends git unzip ca-certificates curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    a2enmod rewrite

# Extensions Laravel 12 + this app need (MySQL, zip/xlsx export, image handling,
# intl for date formatting, pcntl for queue workers if they are ever enabled).
COPY --from=mlocati/php-extension-installer:2 /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_mysql opcache zip gd bcmath intl exif pcntl

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Apache serves Laravel's public/ dir
COPY deploy/apache-vhost.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

COPY . /var/www/html
COPY --from=vendor /app/vendor /var/www/html/vendor
COPY --from=frontend /app/public/build /var/www/html/public/build

RUN composer dump-autoload --no-dev --optimize --no-scripts && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

COPY deploy/entrypoint.sh /usr/local/bin/bookings-entrypoint
RUN chmod +x /usr/local/bin/bookings-entrypoint

ENTRYPOINT ["bookings-entrypoint"]
CMD ["apache2-foreground"]
