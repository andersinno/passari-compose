#!/bin/bash

set -e

./update-configs

if [[ -n "$1" ]]; then
    exec "$@"
fi

if [[ "$WORKFLOW_APPLY_MIGRATIONS" = "1" ]]; then
    echo "Applying migrations"
    pas-db-migrate upgrade head
fi

if [[ "$WEB_UI_INIT_DB" = "1" ]]; then
    echo "Initializing database for Web UI"
    passari-web init-db

    if [[ -n "$WEB_UI_ADMIN_EMAIL" ]]; then
        # Either activate the admin user if it exists or create it
        passari-web users activate "$WEB_UI_ADMIN_EMAIL" || {
            echo "Creating admin user for Web UI"
            passari-web users create \
                  --active \
                  --password "$WEB_UI_ADMIN_PASSWORD" \
                  "$WEB_UI_ADMIN_EMAIL"
        }
    fi
fi

echo "Starting Flask dev server"
exec passari-web run --host=0.0.0.0
