#!/bin/bash
set -ex
source ./env.sh

if [ -n "$CONFIG_URL" ]; then
    curl "$CONFIG_URL" > ./startup-config.sh
    source ./startup-config.sh
fi

exec python3 ./src/handler.py
