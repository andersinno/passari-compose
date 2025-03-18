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

- Copy `.env.defaults` to `.env` and configure the environment variables.
- Run `docker compose up`

## Configuration Files

This setup will automatically update the Passari configuration files on
the "web" container when the container starts.  Their contents are
generated by applying the current environment variables to the the
template TOML files in the configs directory:

- [passari.toml](configs/passari.toml)
- [passari-workflow.toml](configs/passari-workflow.toml)
- [passari-web-ui.toml](configs/passari-web-ui.toml)

See the docs in passari, passari-workflow and passari-web-ui for more
information about the configurations for each component.

## Passari Workflow

The migrations for the Passari Workflow database are run automatically
on the docker entrypoint.

## Passari Web UI

To initialize the database for Passari Web UI, set the following env
variable:

```
WEB_UI_INIT_DB=1
```

When the database is initialized an admin user is automatically created
if it it doesn't exist and the following env variables are set:

```
WEB_UI_ADMIN_USER_EMAIL=XXX
WEB_UI_ADMIN_USER_PASSWORD=XXX
```

Web UI development server is automatically started as the last command
in the docker entrypoint.

The Web UI can be accessed at http://localhost:5000

## Redis Commander

If you want to access Redis Commander to monitor Redis, you can visit:

http://localhost:8081

This will give you a web UI to interact with the Redis instance running in the Docker container.

## Temporary Fixes

The docker setup installs each component with `pip install .` instead of using the pinned requirements in `/passari/requirements.txt` due to some of those being incompatible with Python 3.12. 

Issues with the unpinned dependencies are fixed by installing `requirements-fixed.txt` instead.

e.g. to fix `passari-web init-db`:
```
werkzeug==2.2.2 (downgrade)
rq-dashboard==0.6.1 (downgrade)
sqlalchemy==1.4.32 (downgrade)
Flask-Security-Too==3.4.2 (downgrade)
pytz (required by flask-babelex)
```
