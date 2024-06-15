#!/bin/bash
source ./env.sh

CONFIG_URL=""
SKIP_DOWNLOAD=0
if [ -n "$CONFIG_URL" ]; then
    curl "$CONFIG_URL" > ./config.sh
    source ./config.sh
fi

echo -e "$EXL2_CONFIG" > ./exl2-config.yml
exec python3 ./src/handler.py
