#!/bin/bash

set -e

./update-configs

# Apply migrations (passari-workflow)
if [[ "$WORKFLOW_APPLY_MIGRATIONS" = "1" ]]; then
    echo "Applying migrations"
    cd /app/passari-workflow
    if ! alembic upgrade head; then
        echo "Failed to apply migrations"
        exit 1
    fi
fi

# Set up Flask application (passari-web-ui)
if [[ "$WEB_UI_CREATE_DB" = "1" ]]; then
    echo "Creating database for Web UI"
    cd /app/passari-web-ui
    flask create-db
fi

if [[ "$WEB_UI_CREATE_ADMIN_USER" = "1" ]]; then
    echo "Creating admin user for Web UI"
    cd /app/passari-web-ui
    flask users create --password "${WEB_UI_ADMIN_PASSWORD}" -a "${WEB_UI_ADMIN_EMAIL}"
fi

# Execute the passed command, or start the dev server
if [[ ! -z "$@" ]]; then
    echo "Executing command: $@"
    exec "$@"
elif [[ "$WEB_UI_DEV_SERVER" = "1" ]]; then
    echo "Starting Flask dev server"
    cd /app/passari-web-ui
    exec flask run --host=0.0.0.0
else
    echo "No valid command or WEB_UI_DEV_SERVER option provided. Exiting."
    exit 1
fi
