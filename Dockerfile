FROM ubuntu:jammy-20230308

ARG BUILD_DATE
ARG VCS_REF

# https://github.com/ryanoasis/nerd-fonts/releases
ENV NERDFONTS_VERSION="v2.3.1" \
    NERDFONTS_SHA256="53f17da9b2c73c4bb4f81a5c8561940618e6808df91f36c8aa9890eb0caabe18"
ENV IMAGE_VERSION="${NERDFONTS_VERSION}"

ENV BUILD_DIR="/build" \
    NERDFONTS_DIR="/nerd-fonts"

ENV INPUT_DIR="${NERDFONTS_DIR}/in" \
    OUTPUT_DIR="${NERDFONTS_DIR}/out" \
    REPOSITORY_DIR="${NERDFONTS_DIR}/repo"
RUN mkdir -p "${INPUT_DIR}" "${OUTPUT_DIR}" "${REPOSITORY_DIR}"

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
LABEL org.opencontainers.image.base.name="ubuntu:jammy-20230308"
LABEL org.opencontainers.image.licenses="MIT"

# Entrypoint
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

# Shared resources
VOLUME [ "${INPUT_DIR}", "${OUTPUT_DIR}" ]

WORKDIR ${REPOSITORY_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
