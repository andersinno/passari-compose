#!/bin/bash

set -e

./update-configs

if [[ -n "$1" ]]; then
    exec "$@"
fi

if [[ "$WORKFLOW_APPLY_MIGRATIONS" = "1" ]]; then
    echo "Applying migrations"
    cd passari-workflow
    alembic upgrade head
    cd ..
fi

if [[ "$WEB_UI_CREATE_DB" = "1" ]]; then
    echo "Creating database for Web UI"
    cd passari-web-ui

    flask create-db

    if [[ -n "$WEB_UI_ADMIN_EMAIL" ]]; then
        # Either activate the admin user if it exists or create it
        flask users activate "$WEB_UI_ADMIN_EMAIL" || {
            echo "Creating admin user for Web UI"
            flask users create \
                  --active \
                  --password "$WEB_UI_ADMIN_PASSWORD" \
                  "$WEB_UI_ADMIN_EMAIL"
        }
    fi

    cd ..
fi

echo "Starting Flask dev server"
cd passari-web-ui
exec flask run --host=0.0.0.0
