#!/usr/bin/env bash

set -uo pipefail;

function find_local_version_file() {
  log 'debug' "Looking for a version file in ${1}";

  local root="${1}";

  while ! [[ "${root}" =~ ^//[^/]*$ ]]; do

    if [ -e "${root}/.terragrunt-version" ]; then
      log 'debug' "Found at ${root}/.terragrunt-version";
      echo "${root}/.terragrunt-version";
      return 0;
    else
      log 'debug' "Not found at ${root}/.terragrunt-version";
    fi;

    [ -n "${root}" ] || break;
    root="${root%/*}";

  done;

  log 'debug' "No version file found in ${1}";
  return 1;
};
export -f find_local_version_file;

function tgenv-version-file() {
  if ! find_local_version_file "${TGENV_DIR:-${PWD}}"; then
    if ! find_local_version_file "${HOME:-/}"; then
      log 'debug' "No version file found in search paths. Defaulting to TGENV_CONFIG_DIR: ${TGENV_CONFIG_DIR}/version";
      echo "${TGENV_CONFIG_DIR}/version";
    fi;
  fi;
};
export -f tgenv-version-file;
