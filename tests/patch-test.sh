#!/usr/bin/env bash

set -e

# https://stackoverflow.com/a/4774063/3398062
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
COMMON_FILE="${SCRIPT_PATH}/lib/common.sh"

# shellcheck source=tests/lib/common.sh
source "${COMMON_FILE}"
[ "$(lowercase "${DEBUG}")" == true ] && set -vx

log_info "🧪 Running patch tests ..."

### GIVEN
FIRACODE_VERSION="6"
FIRACODE_SHA256="a4997c2f905fb20a6d814baf7b9bab7df7de574a8e87d6af509685a43291caf1"
FIRACODE_FILE_NAME="FiraCode.zip"
FIRACODE_URL="https://github.com/tonsky/FiraCode/releases/download/${FIRACODE_VERSION}/Fira_Code_v${FIRACODE_VERSION}.zip"

NERDFONTS_VERSION="$(cat VERSION)"
FIRACODE_NERD_FONT_SHA256="9d0018e5a299b582c42d6e3e80cd4f3b0a3489e14e0c8ad126869248fa11c172"
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
