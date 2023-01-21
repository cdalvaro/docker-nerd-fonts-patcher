#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

FUNCTIONS_FILE="${BUILD_DIR}/functions.sh"
# shellcheck source=assets/build/functions.sh
source "${FUNCTIONS_FILE}"

log_info "Installing required packages and build dependencies ..."
REQUIRED_PACKAGES=(
  libpng16-16 zlib1g libtiff5 libjpeg8 libxml2 libspiro1 libgif7 \
  libiconv-hook1 libfreetype6 libcairo2 libpango1.0-0 libwoff1 \
  libuninameslist1 libreadline8 libpython3.10 python3 unifont \
  python3-setuptools python3-dev python3-fonttools fonttools
)

BUILD_DEPENDENCIES=(
  libjpeg-dev libtiff5-dev libpng-dev libfreetype6-dev libgif-dev \
  libxml2-dev libpango1.0-dev libcairo2-dev libspiro-dev \
  libuninameslist-dev libreadline-dev libwoff-dev ca-certificates \
  ninja-build cmake build-essential openssl wget gettext git \
  apt-transport-https
)

apt-get update
install_pkgs "${REQUIRED_PACKAGES[@]}" "${BUILD_DEPENDENCIES[@]}"

# Install fontforge
FONTFORGE_VERSION="20230101"
FONTFORGE_SHA256="ab0c4be41be15ce46a1be1482430d8e15201846269de89df67db32c7de4343f1"
install_fontforge "${FONTFORGE_VERSION}" "${FONTFORGE_SHA256}"

# Download nerd-fonts
NERDFONTS_URL="https://github.com/ryanoasis/nerd-fonts/archive/refs/tags/${NERDFONTS_VERSION}.tar.gz"
NERDFONTS_FILE_NAME="nerd-fonts.tar.gz"
download "${NERDFONTS_URL}" "${NERDFONTS_FILE_NAME}" --progress=bar --show-progress
check_sha256 "${NERDFONTS_FILE_NAME}" "${NERDFONTS_SHA256}"
extract "${NERDFONTS_FILE_NAME}" "${REPOSITORY_DIR}" --exclude='patched-fonts'

# Purge build dependencies and cleanup apt
apt-get purge -y --auto-remove "${BUILD_DEPENDENCIES[@]}"
apt-get clean --yes
rm -rf /var/lib/apt/lists/*
rm -rf "${BUILD_DIR}"

export -n DEBIAN_FRONTEND
