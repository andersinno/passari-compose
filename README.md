# passari-compose
Passari components **passari**, **passari-workflow** and **passari-web-ui** combined to a single Docker Compose environment running on **AlmaLinux 9** and **Python 3.12**.

> **Note**: This README is a summary to get a development environment setup quickly. For more detailed information, see the docs for each component separately.

## Services:
- `web`
- `db`
- `redis`
- `redis-commander`

## Setting Up the Environment

### 1. Install the Git Submodules

```bash
git submodule update --init
```

### 2. Build and Start the Containers

- Copy `.env.example` to `.env` and configure the environment variables.
- Run `docker compose up`

## Configuration Files

Make changes to the following configuration files as necessary before building the Docker container:
- `passari.toml`
- `passari-workflow.toml`
- `passari-web-ui.toml`

See the docs in passari, passari-workflow and passari-web-ui for more information about the configurations for each component.

## passari-workflow

To run the migrations automatically, set the following env variable:

```
APPLY_MIGRATIONS=1
```

## passari-web-ui

To create the Flask database, set the following env variable:

```
WEB_UI_CREATE_DATABASE=1
```

To create an admin user, set the following env variables:

```
WEB_UI_CREATE_ADMIN_USER=1
WEB_UI_ADMIN_USER_EMAIL=XXX
WEB_UI_ADMIN_USER_PASSWORD=XXX
```

To start the Flask server in development automatically, set the following env variable:

```
WEB_UI_DEV_SERVER=1
```

The Web UI can be accessed at http://localhost:5000

## redis-commander

If you want to access Redis Commander to monitor Redis, you can visit:

http://localhost:8081

This will give you a web UI to interact with the Redis instance running in the Docker container.

## Temp Fixes

The docker setup installs each component with `pip install .` instead of using the pinned requirements in `/passari/requirements.txt` due to some of those being incompatible with Python 3.12. 

Issues with the unpinned dependencies are fixed by installing `requirements-fixed.txt` instead.

e.g. to fix `flask create-db`:
```
werkzeug==2.2.2 (downgrade)
rq-dashboard==0.6.1 (downgrade)
sqlalchemy==1.4.32 (downgrade)
Flask-Security-Too==3.4.2 (downgrade)
pytz (required by flask-babelex)
```
