#!/usr/bin/env bash
set -euo pipefail

R="\e[31m"
G="\e[32m"
Y="\e[33m"
EC="\e[0m"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd -- "${SCRIPT_DIR}/../../" &> /dev/null && pwd)

ENV_FILE="${PROJECT_ROOT}/.env"
ENV_FILE_TEMPLATE="${PROJECT_ROOT}/.env.example"

confirm() {
    read -p "$(echo -e "${Y}${1:-Are you sure?}${EC} [${R}y${EC}/${G}N${EC}] (continuing in 20s) ")" -t 20 -r -n 1 response || true
    printf "\n"
    if [[ "${response:-}" =~ ^[yY]$ ]]; then
        return 0
    fi
    return 1
}

if [ ! -f "${ENV_FILE}" ]; then
    cp "${ENV_FILE_TEMPLATE}" "${ENV_FILE}"
    echo -e "${G}✓${EC} File ${Y}${ENV_FILE##*/}${EC} created from ${Y}${ENV_FILE_TEMPLATE##*/}${EC}"
else
    SKIP_CHECK="false"
    if grep -q -E '^SKIP_ENV_OVERWRITE_CHECK=true' "${ENV_FILE}"; then
        SKIP_CHECK="true"
    fi

    if [ "${SKIP_CHECK}" = "true" ]; then
        echo -e "The ${Y}${ENV_FILE##*/}${EC} file already exists. Overwrite check is disabled (SKIP_ENV_OVERWRITE_CHECK=true)."
    else
        if ! cmp -s "${ENV_FILE}" "${ENV_FILE_TEMPLATE}"; then
          if confirm "The contents of '${ENV_FILE##*/}' differ from '${ENV_FILE_TEMPLATE##*/}'. Overwrite '${ENV_FILE##*/}'?"; then
            cp "${ENV_FILE_TEMPLATE}" "${ENV_FILE}"
            echo -e "${G}✓${EC} The ${Y}${ENV_FILE##*/}${EC} file has been updated."
          else
            echo -e "The ${Y}${ENV_FILE##*/}${EC} file was not overwritten by user choice."
          fi
        else
          echo -e "The ${Y}${ENV_FILE##*/}${EC} file already exists and is identical to ${Y}${ENV_FILE_TEMPLATE##*/}${EC}. No action required."
        fi
    fi
fi
