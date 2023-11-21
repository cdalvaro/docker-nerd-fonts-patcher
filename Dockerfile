FROM ubuntu:jammy-20231004

ARG BUILD_DATE
ARG VCS_REF

# https://github.com/ryanoasis/nerd-fonts/releases
ENV NERDFONTS_VERSION="v3.1.0" \
    NERDFONTS_SHA256="8fa631a6201375bda1cc7b16c35af75a806df83903bc173d5e086c14ec1880e9"
ENV IMAGE_VERSION="${NERDFONTS_VERSION}"

ENV BUILD_DIR="/build" \
    REPOSITORY_DIR="/nerd-fonts/repo"
RUN mkdir -p "${REPOSITORY_DIR}"

# Install nerd fonts
COPY assets/build/ ${BUILD_DIR}
WORKDIR ${BUILD_DIR}
RUN bash ${BUILD_DIR}/install.sh

LABEL org.opencontainers.image.title="Dockerized Nerd Fonts Patcher"
LABEL org.opencontainers.image.description="Nerd Fonts ${NERDFONTS_VERSION} containerized"
LABEL org.opencontainers.image.documentation="https://github.com/cdalvaro/docker-nerd-fonts-patcher/blob/${IMAGE_VERSION}/README.md"
LABEL org.opencontainers.image.url="https://github.com/cdalvaro/docker-nerd-fonts-patcher"
LABEL org.opencontainers.image.source="https://github.com/cdalvaro/docker-nerd-fonts-patcher"
LABEL org.opencontainers.image.authors="Carlos Álvaro <github@cdalvaro.io>"
LABEL org.opencontainers.image.vendor="cdalvaro"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.base.name="ubuntu:jammy-20231004"
LABEL org.opencontainers.image.licenses="MIT"

# Entrypoint
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

WORKDIR ${REPOSITORY_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
