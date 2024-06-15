#!/bin/bash
source ./env.sh

if [ -n "$CONFIG_URL" ]; then
    curl "$CONFIG_URL" > ./config.sh
    source ./config.sh
fi

exec python3 ./src/handler.py
