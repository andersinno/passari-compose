FROM almalinux:9

ENV LANG=C.UTF-8
ENV PYTHONUNBUFFERED=1

# Update system packages and install base utilities
RUN dnf -y update && \
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
    postgresql-devel \
    libpq-devel \
    wget \
    dnf-plugins-core && \
    dnf clean all

# Add PAS-jakelu, EPEL and RPM Fusion repositories
RUN rpm --import https://pas-jakelu.csc.fi/RPM-GPG-KEY-pas-support-el9 && \
    dnf config-manager --add-repo=https://pas-jakelu.csc.fi/pas-jakelu-csc-fi.repo && \
    dnf config-manager --set-enabled crb && \
    dnf install -y epel-release && \
    dnf install -y --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm && \
    dnf clean all

# Download the ffmpeg packages manually until the packages in RPM fusion have been updated.
# The ffmpeg in RPM fusion is looking for libdav1d.so.6. However, the new version of dav1d in EPEL has libdav1d.so.7.
# Refs. https://forums.zoneminder.com/viewtopic.php?p=136216
RUN wget https://koji.rpmfusion.org/kojifiles/packages/ffmpeg/5.1.6/2.el9/x86_64/libavdevice-5.1.6-2.el9.x86_64.rpm && \
    wget https://koji.rpmfusion.org/kojifiles/packages/ffmpeg/5.1.6/2.el9/x86_64/ffmpeg-libs-5.1.6-2.el9.x86_64.rpm && \
    wget https://koji.rpmfusion.org/kojifiles/packages/ffmpeg/5.1.6/2.el9/x86_64/ffmpeg-5.1.6-2.el9.x86_64.rpm && \
    dnf -y install \
    ./libavdevice-5.1.6-2.el9.x86_64.rpm \
    ./ffmpeg-libs-5.1.6-2.el9.x86_64.rpm \
    ./ffmpeg-5.1.6-2.el9.x86_64.rpm && \
    # Clean up to reduce image size
    rm -f libavdevice-5.1.6-2.el9.x86_64.rpm ffmpeg-libs-5.1.6-2.el9.x86_64.rpm ffmpeg-5.1.6-2.el9.x86_64.rpm

# Install tools from PAS-jakelu and Development Tools
RUN dnf install -y \
    python3-file-scraper-full \
    python3-dpres-siptools && \
    dnf -y groupinstall "Development Tools" && \
    dnf clean all

# Install Python 3.12
RUN dnf install -y python3.12 python3.12-pip python3.12-psycopg2 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 20 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10 && \
    update-alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.12 20

# Verify Python installation
RUN python --version | grep ' 3.12' && pip --version | grep ' 3.12'

# Set a working directory for the application
WORKDIR /app

# setuptools-scm cannot fetch the version metadata without .git
COPY ./.git /app/.git
COPY ./passari /app/passari
COPY ./passari-workflow /app/passari-workflow
COPY ./passari-web-ui /app/passari-web-ui

# Install Python dependencies for the components
RUN pip install ./passari ./passari-workflow ./passari-web-ui

# Copy the config files
COPY ./passari.toml /etc/passari/config.toml
COPY ./passari-workflow.toml /etc/passari-workflow/config.toml
COPY ./passari-web-ui.toml /etc/passari-web-ui/config.toml

# Default command to keep the container running
CMD ["tail", "-f", "/dev/null"]
