FROM ubuntu:bionic-20190807

ARG BUILD_DATE
ARG VCS_REF

ENV DEBIAN_FRONTEND=noninteractive

ENV FONTFORGE_VERSION=20190801 \
    LIBSPIRO_VERSION=20190731 \
    LIBUNINAMESLIST_VERSION=20190701 \
    NERDFONTS_VERSION=v2.0.0

ENV BUILD_DIR=/build \
    NERDFONTS_DIR=/nerd-fonts

ENV INPUT_DIR=${NERDFONTS_DIR}/in \
    OUTPUT_DIR=${NERDFONTS_DIR}/out \
    REPOSITORY_DIR=${NERDFONTS_DIR}/repo

# Install packages
RUN apt-get update \
 && apt-get install --yes --quiet --no-install-recommends \
    git ca-certificates packaging-dev pkg-config python3-dev \
    libpango1.0-dev libglib2.0-dev libxml2-dev giflib-tools \
    libjpeg-dev libtiff-dev libspiro-dev build-essential \
    automake flex bison unifont \
 && apt-get clean --yes \
 && rm -rf /var/lib/apt/lists/*

# Install fontforge
COPY assets/build/ ${BUILD_DIR}
RUN chmod +x ${BUILD_DIR}/install.sh \
 && ${BUILD_DIR}/install.sh

# Download nerd-fonts
RUN git clone --branch "${NERDFONTS_VERSION}" --depth 1 \
    https://github.com/ryanoasis/nerd-fonts.git ${REPOSITORY_DIR} \
 && rm -rf ${REPOSITORY_DIR}/patched-fonts
WORKDIR ${REPOSITORY_DIR}

LABEL \
    maintainer="github@cdalvaro.io" \
    org.label-schema.vendor=cdalvaro \
    org.label-schema.name="Nerd Fonts Patcher" \
    org.label-schema.version=${NERDFONTS_VERSION} \
    org.label-schema.description="Dockerized Nerd Fonts Patcher" \
    org.label-schema.url="https://github.com/cdalvaro/docker-nerd-fonts-patcher" \
    org.label-schema.vcs-url="https://github.com/cdalvaro/docker-nerd-fonts-patcher.git" \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.docker.schema-version="1.0" \
    com.cdalvaro.saltstack-master.license=MIT

# Entrypoint
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

ENTRYPOINT ["/sbin/entrypoint.sh"]
