###############################################################################
FROM almalinux:9 AS base

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


###############################################################################
FROM base as wheels
RUN --mount=type=cache,sharing=locked,target=/var/cache/dnf \
    dnf install -y python3.12-devel swig  # For building M2Crypto
COPY requirements-siptools.txt /
RUN mkdir wheels
WORKDIR /wheels
RUN pip wheel -r ../requirements-siptools.txt

###############################################################################
FROM base as app

# Add appuser (with uid 1000) and change to it
RUN useradd -d /home/appuser -m -s /bin/bash -u 1000 appuser
USER appuser
ENV PYTHONPYCACHEPREFIX=/home/appuser/.cache/pycache
ENV PATH="$PATH:/home/appuser/.local/bin"

# Install pip-tools
RUN pipx install pip-tools

# Set a working directory for the application
WORKDIR /app

# Install siptools
COPY --from=wheels /wheels /siptools-wheels
COPY requirements-siptools.txt .
RUN --mount=type=cache,sharing=locked,uid=1000,target=/home/appuser/.cache/pip \
    pip install --user --no-index -f /siptools-wheels -r requirements-siptools.txt

# Copy the sources
#
# Note: The dirs are intentionally created as root.  There should be no
# need to write to them during the build process.
COPY passari ./passari
COPY passari-workflow ./passari-workflow
COPY passari-web-ui ./passari-web-ui
COPY requirements.txt .

# Install the local packages in editable mode
#
# The --no-build-isolation flag is used so that pip does not create the
# PKG_NAME.egg-info directories in the source directories.
RUN --mount=type=cache,sharing=locked,uid=1000,target=/home/appuser/.cache/pip \
    pip install --user --no-build-isolation -r requirements.txt

# Install development requirements
COPY requirements-dev.txt .
RUN --mount=type=cache,sharing=locked,uid=1000,target=/home/appuser/.cache/pip \
    pip install --user --no-build-isolation -r requirements-dev.txt

# Copy the config templates and a script to process them (called from
# the entrypoint), and create directories for the destination files
COPY configs ./configs
COPY update-configs .
USER root
RUN cd /etc && \
    mkdir --mode=0775 passari passari-workflow passari-web-ui && \
    chgrp appuser passari passari-workflow passari-web-ui

COPY docker-entrypoint.sh .

# Data directory for museum object workspace and archived objects
RUN \
    mkdir -p /data/objects /data/archive && \
    chown -R appuser:appuser /data && \
    ln -s /data/objects /home/appuser/MuseumObjects && \
    ln -s /data/archive /home/appuser/MuseumObjectArchive && \
    chown -h appuser:appuser /home/appuser/MuseumObjects && \
    chown -h appuser:appuser /home/appuser/MuseumObjectArchive

# Run as appuser by default
USER appuser

ENTRYPOINT ["/app/docker-entrypoint.sh"]
