#!/usr/bin/env bash

# shellcheck disable=SC2312

#---  ENV VARIABLE  ---------------------------------------------------------------------------------------------------
#          NAME:  IMAGE_NAME
#   DESCRIPTION:  The name and tag of the Docker image. Default: 'cdalvaro/docker-nerd-fonts-patcher:latest'.
#----------------------------------------------------------------------------------------------------------------------
export IMAGE_NAME=${IMAGE_NAME:-'cdalvaro/docker-nerd-fonts-patcher:latest'}

#---  ENV VARIABLE  ---------------------------------------------------------------------------------------------------
#          NAME:  PLATFORM
#   DESCRIPTION:  The platform to run the tests on. Default: the current platform.
#----------------------------------------------------------------------------------------------------------------------
export PLATFORM=${PLATFORM:-$(docker version --format='{{.Server.Os}}/{{.Server.Arch}}')}

#---  ENV VARIABLE  ---------------------------------------------------------------------------------------------------
#          NAME:  INPUT_DIR
#   DESCRIPTION:  The path to the input directory. Default: 'in'.
#----------------------------------------------------------------------------------------------------------------------
export INPUT_DIR="${INPUT_DIR:-"$(pwd)/in"}"

#---  ENV VARIABLE  ---------------------------------------------------------------------------------------------------
#          NAME:  OUTPUT_DIR
#   DESCRIPTION:  The path to the output directory. Default: 'out'.
#----------------------------------------------------------------------------------------------------------------------
export OUTPUT_DIR="${OUTPUT_DIR:-"$(pwd)/out"}"

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  lowercase
#   DESCRIPTION:  Lowercase a string.
#----------------------------------------------------------------------------------------------------------------------
function lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  log_debug
#   DESCRIPTION:  Echo debug information to stdout.
#----------------------------------------------------------------------------------------------------------------------
function log_debug() {
  ECHO_DEBUG=$(lowercase "${ECHO_DEBUG:-${DEBUG:-false}}")

  if [[ "${ECHO_DEBUG}" == true ]]; then
    echo "🧪 [DEBUG] - $*"
  fi
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  log_info
#   DESCRIPTION:  Echo information to stdout.
#----------------------------------------------------------------------------------------------------------------------
function log_info() {
  echo "ℹ️ [INFO] - $*"
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  log_warn
#   DESCRIPTION:  Echo warning information to stdout.
#----------------------------------------------------------------------------------------------------------------------
function log_warn() {
  (echo >&2 "⚠️ [WARN] - $*")
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  log_error
#   DESCRIPTION:  Echo errors to stderr.
#----------------------------------------------------------------------------------------------------------------------
function log_error() {
  (echo >&2 "❌ [ERROR] - $*")
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  is_arm32
#   DESCRIPTION:  Check whether the platform is ARM 32-bits or not.
#----------------------------------------------------------------------------------------------------------------------
function is_arm32() {
  uname -m | grep -qE 'armv7l'
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  is_arm32
#   DESCRIPTION:  Check whether the platform is ARM 64-bits or not.
#----------------------------------------------------------------------------------------------------------------------
function is_arm64() {
  uname -m | grep -qE 'arm64|aarch64'
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  is_arm32
#   DESCRIPTION:  Check whether the platform is ARM or not.
#----------------------------------------------------------------------------------------------------------------------
function is_arm() {
  is_arm32 || is_arm64
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  ok
#   DESCRIPTION:  Print a successfull message.
#----------------------------------------------------------------------------------------------------------------------
function ok()
{
  echo "✅ $*"
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  error
#   DESCRIPTION:  Print an error message, show the salt-master log and exit with code 1.
#----------------------------------------------------------------------------------------------------------------------
function error()
{
  echo "🔥 $*"
  return 1
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  download
#   DESCRIPTION:  Download the content from the given URL and save it into the specified file.
#----------------------------------------------------------------------------------------------------------------------
function download() {
  local URL="$1"; shift
  local FILE_NAME="$1"; shift

  local WGET_ARGS=(--quiet)
  is_arm32 && WGET_ARGS+=(--no-check-certificate)

  log_info "Downloading ${FILE_NAME} from ${URL} ..."
  wget "${WGET_ARGS[@]}" "$@" -O "${FILE_NAME}" "${URL}"
  if [[ -f "${FILE_NAME}" ]]; then
    log_debug "Success!"
  else
    log_error "Failed to download ${URL}"
    return 1
  fi
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  check_sha256
#   DESCRIPTION:  Compute the SHA256 hash for the given file and check if it matches the expected one.
#----------------------------------------------------------------------------------------------------------------------
function check_sha256() {
  local FILE="${1}"
  local SHA256="${2}"

  log_info "Checking ${FILE} SHA256 hash ..."
  if echo "${SHA256}  ${FILE}" | shasum -a 256 -c --status -; then
    log_debug "SHA256 hash for ${FILE} matches! (${SHA256})"
  else
    local HASH
    HASH=$(shasum -a 256 "${FILE}" | awk '{print $1}')
    log_error "SHA256 checksum mismatch for ${FILE}"
    log_error "Expected: ${SHA256}"
    log_error "     Got: ${HASH}"
    return 1
  fi
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  check_equal
#   DESCRIPTION:  Check if the given value is equal to the expected value.
#----------------------------------------------------------------------------------------------------------------------
function check_equal()
{
  local current="$1"
  local expected="$2"
  local message="$3"

  output=$(cat <<EOF
${message}
  Expected: ${expected}
   Current: ${current}
EOF
)

  if [[ "${current}" == "${expected}" ]]; then
    ok "${output}"
  else
    error "${output}"
  fi
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  check_regex
#   DESCRIPTION:  Check if the given value matches the expected regex.
#----------------------------------------------------------------------------------------------------------------------
function check_regex()
{
  local current="$1"
  local regex="$2"
  local message="$3"

  output=$(cat <<EOF
${message}
    Regex: ${regex}
  Current: ${current}
EOF
)

  if echo -n "${current}" | grep -qE "${regex}"; then
    ok "${output}"
  else
    error "${output}"
  fi
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  font_patcher
#   DESCRIPTION:  Run font-patcher with given options.
#----------------------------------------------------------------------------------------------------------------------
function font_patcher()
{
  docker run --rm --platform "${PLATFORM}" \
    --volume "${INPUT_DIR}/":/input \
    --volume "${OUTPUT_DIR}/":/output \
    --env PUID="$(id -u)" --env PGID="$(id -g)" \
    --env SOURCE_DATE_EPOCH \
    -- "${IMAGE_NAME}" "$@"
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  font_build_time
#   DESCRIPTION:  Print the build time of the given font ('head.modified') as a Unix timestamp.
#----------------------------------------------------------------------------------------------------------------------
function font_build_time()
{
  local FONT_PATH="${1}"

  # 'head' stores seconds since 1904-01-01; epoch_diff converts them to Unix time
  python3 -c '
import sys
from fontTools.misc.timeTools import epoch_diff
from fontTools.ttLib import TTFont
print(TTFont(sys.argv[1])["head"].modified + epoch_diff)
' "${FONT_PATH}"
}
