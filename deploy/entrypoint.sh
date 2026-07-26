#!/bin/bash
set -e

# Ensure runtime-writable dirs are owned by the web user (named-volume mounts
# can land as root). Storage holds the symlinked public uploads + logs.
chown -R www-data:www-data storage bootstrap/cache || true

# Recreate the storage symlink (public/storage -> storage/app/public) — a fresh
# container/volume won't have it. Ignore if it already exists.
php artisan storage:link || true

# Cache config/routes/views for prod performance. Safe to run every boot; reads
# the live .env. Skipped silently if it fails (e.g. missing APP_KEY on first run).
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

exec "$@"
