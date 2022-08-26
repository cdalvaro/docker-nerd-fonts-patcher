FROM ubuntu:jammy-20220801

ARG BUILD_DATE
ARG VCS_REF

# https://github.com/ryanoasis/nerd-fonts/releases
ENV NERDFONTS_VERSION="v2.2.0"
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

LABEL \
    maintainer="github@cdalvaro.io" \
    org.label-schema.vendor=cdalvaro \
    org.label-schema.name="Nerd Fonts Patcher" \
    org.label-schema.version=${IMAGE_VERSION} \
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

# Shared resources
VOLUME [ "${INPUT_DIR}", "${OUTPUT_DIR}" ]

WORKDIR ${REPOSITORY_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
