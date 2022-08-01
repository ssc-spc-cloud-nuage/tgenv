#!/usr/bin/env bash

set -uo pipefail;

function tgenv-version-name() {
  if [[ -z "${TGENV_TERRAGRUNT_VERSION:-""}" ]]; then
    log 'debug' 'We are not hardcoded by a TGENV_TERRAGRUNT_VERSION environment variable';

    TGENV_VERSION_FILE="$(tgenv-version-file)" \
      && log 'debug' "TGENV_VERSION_FILE retrieved from tgenv-version-file: ${TGENV_VERSION_FILE}" \
      || log 'error' 'Failed to retrieve TGENV_VERSION_FILE from tgenv-version-file';

    TGENV_VERSION="$(cat "${TGENV_VERSION_FILE}" || true)" \
      && log 'debug' "TGENV_VERSION specified in TGENV_VERSION_FILE: ${TGENV_VERSION}";

    TGENV_VERSION_SOURCE="${TGENV_VERSION_FILE}";

  else
    TGENV_VERSION="${TGENV_TERRAGRUNT_VERSION}" \
      && log 'debug' "TGENV_VERSION specified in TGENV_TERRAGRUNT_VERSION environment variable: ${TGENV_VERSION}";

    TGENV_VERSION_SOURCE='TGENV_TERRAGRUNT_VERSION';
  fi;

  local auto_install="${TGENV_AUTO_INSTALL:-true}";

  if [[ "${TGENV_VERSION}" == "min-required" ]]; then
    log 'debug' 'TGENV_VERSION uses min-required keyword, looking for a required_version in the code';

    local potential_min_required="$(tgenv-min-required)";
    if [[ -n "${potential_min_required}" ]]; then
      log 'debug' "'min-required' converted to '${potential_min_required}'";
      TGENV_VERSION="${potential_min_required}" \
      TGENV_VERSION_SOURCE='terragrunt{required_version}';
    else
      log 'error' 'Specifically asked for min-required via terragrunt{required_version}, but none found';
    fi;
  fi;

  if [[ "${TGENV_VERSION}" =~ ^latest.*$ ]]; then
    log 'debug' "TGENV_VERSION uses 'latest' keyword: ${TGENV_VERSION}";

    if [[ "${TGENV_VERSION}" =~ ^latest\:.*$ ]]; then
      regex="${TGENV_VERSION##*\:}";
      log 'debug' "'latest' keyword uses regex: ${regex}";
    else
      regex="^[0-9]\+\.[0-9]\+\.[0-9]\+$";
      log 'debug' "Version uses latest keyword alone. Forcing regex to match stable versions only: ${regex}";
    fi;

    declare local_version='';
    if [[ -d "${TGENV_CONFIG_DIR}/versions" ]]; then
      local_version="$(\find "${TGENV_CONFIG_DIR}/versions/" -type d -exec basename {} \; \
        | tail -n +2 \
        | sort -t'.' -k 1nr,1 -k 2nr,2 -k 3nr,3 \
        | grep -e "${regex}" \
        | head -n 1)";

      log 'debug' "Resolved ${TGENV_VERSION} to locally installed version: ${local_version}";
    elif [[ "${auto_install}" != "true" ]]; then
      log 'error' 'No versions of terragrunt installed and TGENV_AUTO_INSTALL is not true. Please install a version of terragrunt before it can be selected as latest';
    fi;

    if [[ "${auto_install}" == "true" ]]; then
      log 'debug' "Using latest keyword and auto_install means the current version is whatever is latest in the remote. Trying to find the remote version using the regex: ${regex}";
      remote_version="$(tgenv-list-remote | grep -e "${regex}" | head -n 1)";
      if [[ -n "${remote_version}" ]]; then
          if [[ "${local_version}" != "${remote_version}" ]]; then
            log 'debug' "The installed version '${local_version}' does not much the remote version '${remote_version}'";
            TGENV_VERSION="${remote_version}";
          else
            TGENV_VERSION="${local_version}";
          fi;
      else
        log 'error' "No versions matching '${requested}' found in remote";
      fi;
    else
      if [[ -n "${local_version}" ]]; then
        TGENV_VERSION="${local_version}";
      else
        log 'error' "No installed versions of terragrunt matched '${TGENV_VERSION}'";
      fi;
    fi;
  else
    log 'debug' 'TGENV_VERSION does not use "latest" keyword';

    # Accept a v-prefixed version, but strip the v.
    if [[ "${TGENV_VERSION}" =~ ^v.*$ ]]; then
      log 'debug' "Version Requested is prefixed with a v. Stripping the v.";
      TGENV_VERSION="${TGENV_VERSION#v*}";
    fi;
  fi;

  if [[ -z "${TGENV_VERSION}" ]]; then
    log 'error' "Version could not be resolved (set by ${TGENV_VERSION_SOURCE} or tgenv use <version>)";
  fi;

  if [[ "${TGENV_VERSION}" == min-required ]]; then
    TGENV_VERSION="$(tgenv-min-required)";
  fi;

  if [[ ! -d "${TGENV_CONFIG_DIR}/versions/${TGENV_VERSION}" ]]; then
    log 'debug' "version '${TGENV_VERSION}' is not installed (set by ${TGENV_VERSION_SOURCE})";
  fi;

  echo "${TGENV_VERSION}";
};
export -f tgenv-version-name;

