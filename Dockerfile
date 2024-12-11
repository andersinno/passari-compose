FROM almalinux:9

ENV LANG=C.UTF-8
ENV PYTHONUNBUFFERED=1

RUN echo keepcache=True >> /etc/dnf/dnf.conf

# Install Python 3.12
RUN --mount=type=cache,sharing=locked,target=/var/cache/dnf \
    dnf update -y && \
    dnf install -y python3.12-pip python3.12-wheel python3.12-psycopg2 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 20 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10 && \
    update-alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.12 20

# Verify Python installation
RUN python --version | grep ' 3.12' && pip --version | grep ' 3.12'

# Update system packages and install base utilities
RUN --mount=type=cache,sharing=locked,target=/var/cache/dnf \
    dnf -y update && \
    dnf -y install \
    git \
    gcc \
    make \
    openssl-devel \
    libffi-devel \
    zlib-devel \
    bzip2-devel \
    xz-devel \
    readline-devel \
    tk-devel \
    libjpeg-turbo-devel \
    libxml2-devel \
    libxslt-devel \
    postgresql \
    postgresql-devel \
    libpq-devel \
    wget \
    dnf-plugins-core

# Install Development Tools
RUN --mount=type=cache,sharing=locked,target=/var/cache/dnf \
    dnf -y groupinstall "Development Tools"

# Add PAS-jakelu, EPEL and RPM Fusion repositories
RUN --mount=type=cache,sharing=locked,target=/var/cache/dnf \
    rpm --import https://pas-jakelu.csc.fi/RPM-GPG-KEY-pas-support-el9 && \
    dnf config-manager --add-repo=https://pas-jakelu.csc.fi/pas-jakelu-csc-fi.repo && \
    dnf config-manager --set-enabled crb && \
    dnf install -y epel-release && \
    dnf install -y --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm

# Install tools from PAS-jakelu
RUN --mount=type=cache,sharing=locked,target=/var/cache/dnf \
    dnf install -y --nobest \
    python3-file-scraper-full \
    python3-dpres-siptools

# Install pipx
RUN pip install --root-user-action=ignore pipx

# Add appuser (with uid 1000) and change to it
RUN useradd -d /home/appuser -m -s /bin/bash -u 1000 appuser
USER appuser
ENV PYTHONPYCACHEPREFIX=/home/appuser/.cache/pycache
ENV PATH="$PATH:/home/appuser/.local/bin"

# Set a working directory for the application
WORKDIR /app

# Install pip-tools
RUN pipx install pip-tools

# Copy the sources
#
# Note: The dirs are intentionally created as root.  There should be no
# need to write to them during the build process.
COPY ./passari /app/passari
COPY ./passari-workflow /app/passari-workflow
COPY ./passari-web-ui /app/passari-web-ui
COPY ./requirements.txt /app/

# Install the local packages in editable mode
#
# The --no-warn-script-location flag is used to suppress the warning
# about the scripts being installed outside the PATH (to ~/.local/bin).
#
# The --no-build-isolation flag is used so that pip does not create the
# PKG_NAME.egg-info directories in the source directories.
RUN --mount=type=cache,sharing=locked,uid=1000,target=/home/appuser/.cache/pip \
    pip install --user --no-warn-script-location --no-build-isolation \
        -r requirements.txt

# Copy the config files
COPY ./passari.toml /etc/passari/config.toml
COPY ./passari-workflow.toml /etc/passari-workflow/config.toml
COPY ./passari-web-ui.toml /etc/passari-web-ui/config.toml

COPY --chown=appuser:appuser docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
