#!/bin/bash
set -e

if [ "$SHOULD_DOWNLOAD" != "1" ]; then
    exit 0
fi

./snapshot_download.py --repo_id="$DL_REPO_ID" --revision="$DL_REVISION" \
    --local_dir="$DL_LOCAL_DIR" --allow_patterns="$DL_ALLOW_PATTERNS"
