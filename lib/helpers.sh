#!/usr/bin/env bash

set -uo pipefail;

if [ -z "${TGENV_ROOT:-""}" ]; then
  # http://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac
  readlink_f() {
    local target_file="${1}";
    local file_name;

    while [ "${target_file}" != "" ]; do
      cd "${target_file%/*}" || early_death "Failed to 'cd \$(${target_file%/*})' while trying to determine TGENV_ROOT";
      file_name="${target_file##*/}" || early_death "Failed to '\"${target_file##*/}\"' while trying to determine TGENV_ROOT";
      target_file="$(readlink "${file_name}")";
    done;

    echo "$(pwd -P)/${file_name}";
  };
  TGENV_SHIM=$(readlink_f "${0}")
  TGENV_ROOT="${TGENV_SHIM%/*/*}";
  [ -n "${TGENV_ROOT}" ] || early_death "Failed to determine TGENV_ROOT";
else
  TGENV_ROOT="${TGENV_ROOT%/}";
fi;
export TGENV_ROOT;

if [ -z "${TGENV_CONFIG_DIR:-""}" ]; then
  TGENV_CONFIG_DIR="$TGENV_ROOT";
else
  TGENV_CONFIG_DIR="${TGENV_CONFIG_DIR%/}";
fi
export TGENV_CONFIG_DIR;

if [ "${TGENV_DEBUG:-0}" -gt 0 ]; then
  # Only reset DEBUG if TGENV_DEBUG is set, and DEBUG is unset or already a number
  if [[ "${DEBUG:-0}" =~ ^[0-9]+$ ]] && [ "${DEBUG:-0}" -gt "${TGENV_DEBUG:-0}" ]; then
    export DEBUG="${TGENV_DEBUG:-0}";
  fi;
  if [[ "${TGENV_DEBUG}" -gt 2 ]]; then
    export PS4='+ [${BASH_SOURCE##*/}:${LINENO}] ';
    set -x;
  fi;
fi;

function load_bashlog () {
  source "${TGENV_ROOT}/lib/bashlog.sh";
};
export -f load_bashlog;

if [ "${TGENV_DEBUG:-0}" -gt 0 ] ; then
  # our shim below cannot be used when debugging is enabled
  load_bashlog;
else
  # Shim that understands to no-op for debug messages, and defers to
  # full bashlog for everything else.
  function log () {
    if [ "$1" != 'debug' ] ; then
      # Loading full bashlog will overwrite the `log` function
      load_bashlog;
      log "$@";
    fi;
  };
  export -f log;
fi;

# Curl wrapper to switch TLS option for each OS
function curlw () {
  local TLS_OPT="--tlsv1.2";

  # Check if curl is 10.12.6 or above
  if [[ -n "$(command -v sw_vers 2>/dev/null)" && ("$(sw_vers)" =~ 10\.12\.([6-9]|[0-9]{2}) || "$(sw_vers)" =~ 10\.1[3-9]) ]]; then
    TLS_OPT="";
  fi;

  if [[ ! -z "${TGENV_NETRC_PATH:-""}" ]]; then
    NETRC_OPT="--netrc-file ${TGENV_NETRC_PATH}";
  else
    NETRC_OPT="";
  fi;

  curl ${TLS_OPT} ${NETRC_OPT} "$@";
};
export -f curlw;

function check_active_version() {
  local v="${1}";
  local maybe_chdir=;
  if [ -n "${2:-}" ]; then
      maybe_chdir="-chdir=${2}";
  fi;

  local active_version="$(${TGENV_ROOT}/bin/terragrunt ${maybe_chdir} )";

  if ! grep "v${v}" <(echo "${active_version}"); then
    log 'debug' "Expected version ${v} but found ${active_version}";
    return 1;
  fi;

  log 'debug' "Active version ${v} as expected";
  return 0;
};
export -f check_active_version;

function check_installed_version() {
  local v="${1}";
  local bin="${TGENV_CONFIG_DIR}/versions/${v}/terragrunt ";
  echo $bin
  [ -n "$(${bin} | grep v${v})" ];
};
export -f check_installed_version;

function check_default_version() {
  local v="${1}";
  local def="$(cat "${TGENV_CONFIG_DIR}/version")";
  [ "${def}" == "${v}" ];
};
export -f check_default_version;

function cleanup() {
  log 'info' 'Performing cleanup';
  local pwd="$(pwd)";
  log 'debug' "Deleting ${pwd}/version";
  rm -rf ./version;
  log 'debug' "Deleting ${pwd}/versions";
  rm -rf ./versions;
  log 'debug' "Deleting ${pwd}/.terragrunt-version";
  rm -rf ./.terragrunt-version;
  log 'debug' "Deleting ${pwd}/min_required.tf";
  rm -rf ./min_required.tf;
  log 'debug' "Deleting ${pwd}/chdir-dir";
  rm -rf ./chdir-dir;
};
export -f cleanup;

function error_and_proceed() {
  errors+=("${1}");
  log 'warn' "Test Failed: ${1}";
};
export -f error_and_proceed;

function check_dependencies() {
  if [[ $(uname) == 'Darwin' ]] && [ $(which brew) ]; then
    if ! [ $(which ggrep) ]; then
      log 'error' 'A metaphysical dichotomy has caused this unit to overload and shut down. GNU Grep is a requirement and your Mac does not have it. Consider "brew install grep"';
    fi;

    shopt -s expand_aliases;
    alias grep=ggrep;
  fi;
};
export -f check_dependencies;

source "$TGENV_ROOT/lib/tgenv-exec.sh";
source "$TGENV_ROOT/lib/tgenv-min-required.sh";
source "$TGENV_ROOT/lib/tgenv-version-file.sh";
source "$TGENV_ROOT/lib/tgenv-version-name.sh";

export TGENV_HELPERS=1;
