FROM ubuntu:resolute-20261024.1

ARG BUILD_DATE
ARG VCS_REF

# https://github.com/ryanoasis/nerd-fonts/releases
ENV NERDFONTS_VERSION="v3.5.1" \
  NERDFONTS_SHA256="81627f9e1d79c5028e2ac28a011b46dc335e146c6ce9d0c368f28c5c3601955a"
ENV IMAGE_VERSION="${NERDFONTS_VERSION}"

ENV BUILD_DIR="/build" \
  WORKDIR="/nerd-fonts"

ENV FONTPATCHER_DIR="${WORKDIR}/repo"
RUN mkdir -p "${FONTPATCHER_DIR}"

# Install nerd fonts
COPY assets/build/ ${BUILD_DIR}
WORKDIR ${BUILD_DIR}
RUN bash ${BUILD_DIR}/install.sh && rm -rf ${BUILD_DIR}

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
LABEL org.opencontainers.image.base.name="ubuntu:resolute-20261024.1"
LABEL org.opencontainers.image.licenses="MIT"

# Entrypoint
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

WORKDIR ${WORKDIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
