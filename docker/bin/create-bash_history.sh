#!/usr/bin/env bash
set -euo pipefail

NODE_BASH_HISTORY_FILE="docker/development/node/bash/.bash_history"

if [ ! -f "${NODE_BASH_HISTORY_FILE}" ]; then
    touch "${NODE_BASH_HISTORY_FILE}"
    echo "Created ${NODE_BASH_HISTORY_FILE}"
fi

