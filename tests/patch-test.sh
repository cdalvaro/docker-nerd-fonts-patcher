#!/usr/bin/env bash

# shellcheck disable=SC2312

set -e

# https://stackoverflow.com/a/4774063/3398062
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
COMMON_FILE="${SCRIPT_PATH}/lib/common.sh"

# shellcheck source=tests/lib/common.sh
source "${COMMON_FILE}"
[[ "$(lowercase "${DEBUG:-false}")" == true ]] && set -vx

log_info "🧪 Running patch tests ..."

### GIVEN
FIRACODE_VERSION="6.2"
FIRACODE_SHA256="0949915ba8eb24d89fd93d10a7ff623f42830d7c5ffc3ecbf960e4ecad3e3e79"
FIRACODE_FILE_NAME="FiraCode.zip"
FIRACODE_URL="https://github.com/tonsky/FiraCode/releases/download/${FIRACODE_VERSION}/Fira_Code_v${FIRACODE_VERSION}.zip"

NERDFONTS_VERSION="$(cat VERSION)"
FIRACODE_NERD_FONT_SHA256="f4289834fc3b276789f0fb17a2693e8c481b5548ac97590677510f0ec5419059"
FIRACODE_NERD_FONT_FILE_NAME="FiraCodeNerdFont.zip"
FIRACODE_NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERDFONTS_VERSION}/FiraCode.zip"

WORK_DIR="${SCRIPT_PATH}/assets"
rm -rf "${WORK_DIR}" && mkdir -p "${WORK_DIR}"
pushd "${WORK_DIR}"

INPUT_DIR="$(pwd)/in"
OUTPUT_DIR="$(pwd)/out"

### THEN
log_info "==> Downloading original Fira Code ${FIRACODE_VERSION} font ..."
download "${FIRACODE_URL}" "${FIRACODE_FILE_NAME}"
check_sha256 "${FIRACODE_FILE_NAME}" "${FIRACODE_SHA256}" || error "SHA256 checksum mismatch for ${FIRACODE_URL}"

mkdir -p "${INPUT_DIR}/" "${OUTPUT_DIR}/"
unzip -q "${FIRACODE_FILE_NAME}" 'ttf/*' -d "${INPUT_DIR}/"
mv "${INPUT_DIR}"/ttf/* "${INPUT_DIR}/"
rmdir "${INPUT_DIR}/ttf"

log_info "==> Patching original Fira Code font ..."
patch_fonts "${INPUT_DIR}" "${OUTPUT_DIR}" --complete

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
  diff custom_patched_font.ttx nerdfonts_patched_font.ttx
done < <(find "${OUTPUT_DIR}" -type f -iname '*.ttf' -exec basename {} \; 2>/dev/null)

popd
