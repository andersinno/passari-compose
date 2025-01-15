#!/bin/bash

set -e

./update-configs

if [[ -n "$1" ]]; then
    exec "$@"
fi

FLASK="flask --app passari_web_ui.app"

if [[ "$WORKFLOW_APPLY_MIGRATIONS" = "1" ]]; then
    echo "Applying migrations"
    pas-db-migrate upgrade head
fi

if [[ "$WEB_UI_CREATE_DB" = "1" ]]; then
    echo "Creating database for Web UI"
    $FLASK create-db

    if [[ -n "$WEB_UI_ADMIN_EMAIL" ]]; then
        # Either activate the admin user if it exists or create it
        $FLASK users activate "$WEB_UI_ADMIN_EMAIL" || {
            echo "Creating admin user for Web UI"
            $FLASK users create \
                  --active \
                  --password "$WEB_UI_ADMIN_PASSWORD" \
                  "$WEB_UI_ADMIN_EMAIL"
        }
    fi
fi

echo "Starting Flask dev server"
exec $FLASK run --host=0.0.0.0
