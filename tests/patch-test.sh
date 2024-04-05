#!/usr/bin/env bash

# shellcheck disable=SC2312

set -e

# https://stackoverflow.com/a/4774063/3398062
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
COMMON_FILE="${SCRIPT_PATH}/lib/common.sh"

# shellcheck source=tests/lib/common.sh
source "${COMMON_FILE}"
[[ "$(lowercase "${DEBUG:-false}")" == true ]] && set -vx

NERDFONTS_VERSION="$(cat VERSION)"

log_info "🧪 Running patch tests ..."

# Setup
WORK_DIR="$(mktemp -d)"
pushd "${WORK_DIR}"

# Test font-patcher version
log_info "Checking font-patcher version..."
FONTPATCHER_VERSION="$(font_patcher --version | grep 'Nerd Fonts Patcher')"
check_regex "${FONTPATCHER_VERSION}" "${NERDFONTS_VERSION}"

### GIVEN
TEST_FONT_NAME="FiraCode"

TEST_FONT_SHA256="0949915ba8eb24d89fd93d10a7ff623f42830d7c5ffc3ecbf960e4ecad3e3e79"
TEST_FONT_FILE_NAME="${TEST_FONT_NAME}Original.zip"
TEST_FONT_URL="https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip"

NERDFONT_FONT_SHA256="e70d4a8be94ed056ae0deed2c24c3389f87ccc1ecb08b4c3db9d39ce08840a54"
NERDFONT_FONT_FILE_NAME="${TEST_FONT_NAME}NerdFont.zip"
NERDFONT_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERDFONTS_VERSION}/${TEST_FONT_NAME}.zip"

### THEN
log_info "==> Downloading original ${TEST_FONT_NAME} (${TEST_FONT_URL}) font ..."
download "${TEST_FONT_URL}" "${TEST_FONT_FILE_NAME}"
check_sha256 "${TEST_FONT_FILE_NAME}" "${TEST_FONT_SHA256}" || error "SHA256 checksum mismatch for ${TEST_FONT_URL}"

TEST_FONT_DIRECTORY="$(mktemp -d)"
unzip -q "${TEST_FONT_FILE_NAME}" -d "${TEST_FONT_DIRECTORY}/"
mv "${TEST_FONT_DIRECTORY}"/fonts/ttf/*.ttf "${INPUT_DIR}/"

log_info "==> Patching original ${TEST_FONT_NAME} font ..."
font_patcher --quiet --no-progressbars --complete 2>/dev/null

log_info "==> Downloading patched ${TEST_FONT_NAME} font ..."
download "${NERDFONT_FONT_URL}" "${NERDFONT_FONT_FILE_NAME}"
check_sha256 "${NERDFONT_FONT_FILE_NAME}" "${NERDFONT_FONT_SHA256}" || error "SHA256 checksum mismatch for ${NERDFONT_FONT_URL}"

log_info "==> Comparing own patched fonts with nerd font patched fonts ..."
mkdir -p patched/
unzip -q "${NERDFONT_FONT_FILE_NAME}" -d patched/

while IFS='' read -r FONT; do
  log_info "==> Comparing ${FONT} ..."

  patched_font="${OUTPUT_DIR}/${FONT}"
  [[ -f "${patched_font}" ]] || error "Font ${FONT} not found: ${patched_font}"

  get_font_info "${patched_font}" custom_patched_font.ttx
  get_font_info "patched/${FONT}" nerdfonts_patched_font.ttx

  diff -u nerdfonts_patched_font.ttx custom_patched_font.ttx || error "Font ${FONT} is not patched correctly"
  ok "Font ${FONT} is patched correctly"
done < <(find "${OUTPUT_DIR}" -type f -maxdepth 1 -iname '*.ttf' -exec basename {} \; 2>/dev/null)

popd
