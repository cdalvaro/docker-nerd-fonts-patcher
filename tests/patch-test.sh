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
WORK_DIR="${SCRIPT_PATH}/assets"
rm -rf "${WORK_DIR}" && mkdir -p "${WORK_DIR}"

INPUT_DIR="${WORK_DIR}/in"
OUTPUT_DIR="${WORK_DIR}/out"
mkdir -p "${INPUT_DIR}/" "${OUTPUT_DIR}/"

# Test font-patcher version
log_info "Checking font-patcher version..."
FONTPATCHER_VERSION="$(font_patcher --version | grep 'Nerd Fonts Patcher')"
if echo -n "${FONTPATCHER_VERSION}" | grep -q "${NERDFONTS_VERSION}"; then
  log_info "font-patcher version is: ${FONTPATCHER_VERSION}"
else
  log_error "font-patcher version is: ${FONTPATCHER_VERSION}. Expected: '${NERDFONTS_VERSION}'"
  exit 1
fi

### GIVEN
FIRACODE_VERSION="6.2"
FIRACODE_SHA256="0949915ba8eb24d89fd93d10a7ff623f42830d7c5ffc3ecbf960e4ecad3e3e79"
FIRACODE_FILE_NAME="FiraCode.zip"
FIRACODE_URL="https://github.com/tonsky/FiraCode/releases/download/${FIRACODE_VERSION}/Fira_Code_v${FIRACODE_VERSION}.zip"

FIRACODE_NERD_FONT_SHA256="e70d4a8be94ed056ae0deed2c24c3389f87ccc1ecb08b4c3db9d39ce08840a54"
FIRACODE_NERD_FONT_FILE_NAME="FiraCodeNerdFont.zip"
FIRACODE_NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERDFONTS_VERSION}/FiraCode.zip"

pushd "${WORK_DIR}"

### THEN
log_info "==> Downloading original Fira Code ${FIRACODE_VERSION} font ..."
download "${FIRACODE_URL}" "${FIRACODE_FILE_NAME}"
check_sha256 "${FIRACODE_FILE_NAME}" "${FIRACODE_SHA256}" || error "SHA256 checksum mismatch for ${FIRACODE_URL}"

unzip -q "${FIRACODE_FILE_NAME}" 'ttf/*' -d "${INPUT_DIR}/"
mv "${INPUT_DIR}"/ttf/* "${INPUT_DIR}/"
rmdir "${INPUT_DIR}/ttf"

log_info "==> Patching original Fira Code font ..."
patch_fonts "${INPUT_DIR}" "${OUTPUT_DIR}" --quiet --no-progressbars --complete

log_info "==> Downloading patched Fira Code font ..."
download "${FIRACODE_NERD_FONT_URL}" "${FIRACODE_NERD_FONT_FILE_NAME}"
check_sha256 "${FIRACODE_NERD_FONT_FILE_NAME}" "${FIRACODE_NERD_FONT_SHA256}" || error "SHA256 checksum mismatch for ${FIRACODE_NERD_FONT_URL}"

log_info "==> Comparing own patched fonts with nerd font patched fonts ..."
mkdir -p patched/
unzip -q "${FIRACODE_NERD_FONT_FILE_NAME}" -d patched/

while IFS='' read -r FONT; do
  ttx --recalc-timestamp -o custom_patched_font.ttx "${OUTPUT_DIR}/${FONT}"
  sed -E -i 's/.*<(checkSumAdjustment|modified|FFTimeStamp|sourceModified).*//g' custom_patched_font.ttx
  ttx --recalc-timestamp -o nerdfonts_patched_font.ttx "$(pwd)/patched/${FONT}"
  sed -E -i 's/.*<(checkSumAdjustment|modified|FFTimeStamp|sourceModified).*//g' nerdfonts_patched_font.ttx
  diff -u nerdfonts_patched_font.ttx custom_patched_font.ttx
done < <(find "${OUTPUT_DIR}" -type f -iname '*.ttf' -exec basename {} \; 2>/dev/null)

popd
