#!/usr/bin/env bash

set -uo pipefail;

function tgenv-exec() {
  for _arg in ${@:1}; do
    if [[ "${_arg}" == -chdir=* ]]; then
      log 'debug' "Found -chdir arg. Setting TGENV_DIR to: ${_arg#-chdir=}";
      export TGENV_DIR="${PWD}/${_arg#-chdir=}";
    fi;
  done;

  log 'debug' 'Getting version from tgenv-version-name';
  TGENV_VERSION="$(tgenv-version-name)" \
    && log 'debug' "TGENV_VERSION is ${TGENV_VERSION}" \
    || {
      # Errors will be logged from tgenv-version name,
      # we don't need to trouble STDERR with repeat information here
      log 'debug' 'Failed to get version from tgenv-version-name';
      return 1;
    };
  export TGENV_VERSION;

  if [ ! -d "${TGENV_CONFIG_DIR}/versions/${TGENV_VERSION}" ]; then
  if [ "${TGENV_AUTO_INSTALL:-true}" == "true" ]; then
    if [ -z "${TGENV_TERRAGRUNT_VERSION:-""}" ]; then
      TGENV_VERSION_SOURCE="$(tgenv-version-file)";
    else
      TGENV_VERSION_SOURCE='TGENV_TERRAGRUNT_VERSION';
    fi;
      log 'info' "version '${TGENV_VERSION}' is not installed (set by ${TGENV_VERSION_SOURCE}). Installing now as TGENV_AUTO_INSTALL==true";
      tgenv-install;
    else
      log 'error' "version '${TGENV_VERSION}' was requested, but not installed and TGENV_AUTO_INSTALL is not 'true'";
    fi;
  fi;

  TF_BIN_PATH="${TGENV_CONFIG_DIR}/versions/${TGENV_VERSION}/terragrunt";
  export PATH="${TF_BIN_PATH}:${PATH}";
  log 'debug' "TF_BIN_PATH added to PATH: ${TF_BIN_PATH}";
  log 'debug' "Executing: ${TF_BIN_PATH} $@";

  exec "${TF_BIN_PATH}" "$@" \
  || log 'error' "Failed to execute: ${TF_BIN_PATH} $*";

  return 0;
};
export -f tgenv-exec;
