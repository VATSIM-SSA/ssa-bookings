#!/bin/bash
set -e

# Named-volume mounts can land as root — make sure the web user owns them.
chown -R www-data:www-data storage bootstrap/cache || true

# The package manifest is not built at image-build time (composer runs with
# --no-scripts because package:discover boots the app and needs a .env).
php artisan package:discover --ansi || true

# public/storage -> storage/app/public. A fresh container/volume has no symlink.
php artisan storage:link || true

# Cache config/routes/views for performance. Reads the live .env, so it must
# happen at boot, not at build. Non-fatal so a bad cache never blocks startup.
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

exec "$@"
