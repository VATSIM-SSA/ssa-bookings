#!/bin/bash
# Install to /srv/deploy/scripts/deploy-bookings.sh on the VPS (root:root 0755).
# Invoked ONLY as an OpenSSH forced command:
#   command="/srv/deploy/scripts/deploy-bookings.sh prod"    -> gha-bookings-prod key
#   command="/srv/deploy/scripts/deploy-bookings.sh staging" -> gha-bookings-staging key
# The env comes from the key, never from the client, so a leaked key can only
# redeploy its own environment.
set -euo pipefail

ENV="${1:?usage: deploy-bookings.sh <prod|staging>}"
case "$ENV" in
  prod|staging) ;;
  *) echo "✗ invalid env: $ENV"; exit 1 ;;
esac

DIR="/srv/apps/bookings/${ENV}"
CONTAINER="bookings-${ENV}"

cd "$DIR"
docker compose pull
docker compose up -d --force-recreate
docker exec -u www-data "$CONTAINER" php artisan migrate --force
docker exec -u www-data "$CONTAINER" php artisan optimize:clear

echo "Deployed bookings: ${ENV}"
