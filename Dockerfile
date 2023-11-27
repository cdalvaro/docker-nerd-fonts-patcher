FROM ubuntu:jammy-20231004

ARG BUILD_DATE
ARG VCS_REF

# https://github.com/ryanoasis/nerd-fonts/releases
ENV NERDFONTS_VERSION="v3.1.1" \
    NERDFONTS_SHA256="4c4d7f2aceda05ff17789adb2c7046972f4729bc785bc85fd08d0ffde8785e5f"
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
