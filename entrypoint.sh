#!/bin/bash

set -e

INPUT_DIR="/input"
OUTPUT_DIR="/output"

# Auxiliary functions
RESET='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'

function log_info() {
  echo -e "${GREEN}Info${RESET}: $*"
}

function log_warn() {
  echo -e "${YELLOW}Warning${RESET}: $*"
}

function log_error() {
  (>&2 echo -e "${RED}Error${RESET}: $*")
}

if [[ -z "${REPOSITORY_DIR}" ]]; then
  log_error "REPOSITORY_DIR environment variable should be set but it is not. Please report this issue at: https://github.com/cdalvaro/docker-nerd-fonts-patcher/issues"
  exit 1
fi

# Validate arguments
options=()
while [[ $# -gt 0 ]]; do
  param="$1"; shift
  case "${param}" in
    -h|--help)
    exec fontforge -script font-patcher --help ;;
    -v|--version)
    exec fontforge -script font-patcher --version ;;
    -out|--outputdir)
    log_warn "Output directory cannot be modified. Default is: ${CYAN}${OUTPUT_DIR}/${RESET}"
    shift ;;
    *)
    options+=("${param}") ;;
  esac
done

# Check whether output directory exists
if [[ ! -d ${OUTPUT_DIR} ]]; then
  log_error "Directory ${CYAN}${OUTPUT_DIR}/${RESET} does not exists. You must create an output volume like this: ${CYAN}--volume \$(pwd)/out:${OUTPUT_DIR}${RESET}"
  exit 1
fi

# Get fonts available in the input directory
fonts=()
while IFS='' read -r line; do
  fonts+=("${line}")
done < <(find "${INPUT_DIR}/" -type f -iregex '.*\.\(otf\|ttf\|woff\|eot\|ttc\)$' 2>/dev/null || true)

# Check whether there are fonts to patch
if [[ ${#fonts[@]} -eq 0 ]]; then
  log_error "There are no fonts with extensions: ${CYAN}.otf${RESET}, ${CYAN}.ttf${RESET}, ${CYAN}.woff${RESET}, ${CYAN}.eot${RESET} or ${CYAN}.ttc${RESET} inside ${CYAN}${INPUT_DIR}/${RESET} directory"
  exit 1
fi

touch "${OUTPUT_DIR}/font-patcher-log.txt"
rm -f "${REPOSITORY_DIR}/font-patcher-log.txt"
ln -s "${OUTPUT_DIR}/font-patcher-log.txt" "${REPOSITORY_DIR}/font-patcher-log.txt"

# Patch fonts
for font in "${fonts[@]}"; do
  log_info "Patching font ${CYAN}${font}${RESET} ..."
  fontforge -script font-patcher -out "${OUTPUT_DIR}/" "${options[@]}" "${font}"
done

if [[ -n "${PUID}" ]]; then
  OWNERSHIP="${PUID}"
  [[ -n "${PGID}" ]] && OWNERSHIP="${OWNERSHIP}:${PGID}"

  log_info "Changing ownership of ${CYAN}${OUTPUT_DIR}/${RESET} to ${CYAN}${OWNERSHIP}${RESET} ..."
  chown -R "${OWNERSHIP}" "${OUTPUT_DIR}"
fi

exit 0
