#!/usr/bin/env bash

# shellcheck disable=SC2312

set -e

# https://stackoverflow.com/a/4774063/3398062
SCRIPT_PATH="$(
  cd -- "$(dirname "$0")" >/dev/null 2>&1
  pwd -P
)"
COMMON_FILE="${SCRIPT_PATH}/lib/common.sh"
COMPARE_FONTS="${SCRIPT_PATH}/lib/compare_fonts.py"

# shellcheck source=tests/lib/common.sh
source "${COMMON_FILE}"
[[ "$(lowercase "${DEBUG:-false}")" == true ]] && set -vx

NERDFONTS_VERSION="$(cat VERSION)"

log_info "🧪 Running patch tests ..."

# Setup: everything happens inside a temporary directory, so the repository's
# in/ and out/ directories are never touched.
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT
pushd "${WORK_DIR}"

export INPUT_DIR="${WORK_DIR}/in"
export OUTPUT_DIR="${WORK_DIR}/out"
mkdir -p "${INPUT_DIR}" "${OUTPUT_DIR}"

# Test font-patcher version
log_info "Checking font-patcher version..."
FONTPATCHER_VERSION="$(font_patcher --version | grep 'Nerd Fonts Patcher')"
check_regex "${FONTPATCHER_VERSION}" "${NERDFONTS_VERSION}"

### GIVEN
TEST_FONT_NAME="FiraCode"

TEST_FONT_FILE_NAME="${TEST_FONT_NAME}Original.zip"
TEST_FONT_URL="https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip"

NERDFONT_FONT_FILE_NAME="${TEST_FONT_NAME}NerdFont.zip"
NERDFONT_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERDFONTS_VERSION}/${TEST_FONT_NAME}.zip"

# Same options as upstream's bin/scripts/gotta-patch-em-all-font-patcher!.sh:
#  - common options: -q -c --no-progressbars
#  - the font's own config.cfg (for FiraCode it only adds: --makegroups 2)
#  - one run per variant: Nerd Font (no extra option), Mono (--mono)
#    and Propo (--variable-width-glyphs)
# The config.cfg is read from the image, so the test follows upstream if the
# options for this font change in a new release.
FONT_CONFIG_FILE="/nerd-fonts/repo/src/unpatched-fonts/${TEST_FONT_NAME}/config.cfg"
COMMON_OPTIONS=(--quiet --no-progressbars --complete --configfile "${FONT_CONFIG_FILE}")
VARIANT_OPTIONS=("" "--mono" "--variable-width-glyphs")

### WHEN
log_info "==> Downloading original ${TEST_FONT_NAME} (${TEST_FONT_URL}) font ..."
download "${TEST_FONT_URL}" "${TEST_FONT_FILE_NAME}"
unzip -q "${TEST_FONT_FILE_NAME}" 'ttf/*.ttf' -d original/
mv original/ttf/*.ttf "${INPUT_DIR}/"

log_info "==> Downloading patched ${TEST_FONT_NAME} font ..."
download "${NERDFONT_FONT_URL}" "${NERDFONT_FONT_FILE_NAME}"
mkdir -p reference/
unzip -q "${NERDFONT_FONT_FILE_NAME}" '*.ttf' -d reference/

# Use the build time of the reference fonts, so our fonts can be identical byte
# by byte. FontForge honors SOURCE_DATE_EPOCH (https://reproducible-builds.org).
# The comparison would still pass without it: the build time is ignored there.
SOURCE_DATE_EPOCH="$(font_build_time "$(find reference/ -name '*.ttf' | head -n 1)")"
export SOURCE_DATE_EPOCH
log_info "Using SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH} from the reference fonts"

for variant in "${VARIANT_OPTIONS[@]}"; do
  log_info "==> Patching original ${TEST_FONT_NAME} font (variant options: '${variant}') ..."
  # FontForge prints thousands of harmless notices, so the output goes to a log.
  # Only font-patcher's own warnings are shown, or the end of the log on failure.
  PATCH_LOG="patch${variant:+-${variant#--}}.log"
  # shellcheck disable=SC2086 # An empty variant must expand to no argument at all
  if ! font_patcher "${COMMON_OPTIONS[@]}" ${variant} >"${PATCH_LOG}" 2>&1; then
    tail -n 50 "${PATCH_LOG}"
    error "font-patcher failed (variant options: '${variant}')"
  fi
  grep -E '^(WARNING|ERROR|CRITICAL):' "${PATCH_LOG}" | sort | uniq -c | while read -r line; do
    log_warn "font-patcher: ${line}"
  done
done

### THEN
log_info "==> Comparing own patched fonts with nerd font patched fonts ..."
python3 "${COMPARE_FONTS}" reference/ "${OUTPUT_DIR}/" || error "Patched fonts differ from the official ones"
ok "All ${TEST_FONT_NAME} fonts are patched correctly"

popd
