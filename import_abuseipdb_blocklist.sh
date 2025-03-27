#!/bin/bash

set -euo pipefail

CONFIG_FILE="$(dirname "$0")/config.json"
DECISIONS_FILE="$(dirname "$0")/decisions.json"
ABUSEIPDB_API_URL="https://api.abuseipdb.com/api/v2/blacklist"

load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: Config file not found." >&2
        exit 1
    fi
    API_KEY=$(jq -r '.apiKey' "$CONFIG_FILE")
    CONFIDENCE_MINIMUM=$(jq -r '.confidenceMinimum // "75"' "$CONFIG_FILE")
    BAN_DURATION=$(jq -r '.banDuration // "24h"' "$CONFIG_FILE")

    if [[ -z "$API_KEY" || "$API_KEY" == "null" ]]; then
        echo "Error: API key missing in config.json" >&2
        exit 1
    fi
}

fetch_blacklist() {
    response=$(curl -s -H "Key: $API_KEY" -H "Accept: application/json" "$ABUSEIPDB_API_URL?confidenceMinimum=$CONFIDENCE_MINIMUM")
    echo "$response" | jq -r '.data // []' > "$DECISIONS_FILE"
}

map_to_crowdsec_decisions() {
    jq -r --arg duration "$BAN_DURATION" 'map({
        duration: $duration,
        reason: "abuseipdb",
        scope: "ip",
        type: "ban",
        value: .ipAddress
    })' "$DECISIONS_FILE" > "$DECISIONS_FILE.tmp"
    mv "$DECISIONS_FILE.tmp" "$DECISIONS_FILE"
}

import_decisions() {
    if command -v cscli >/dev/null 2>&1; then
        if cscli decisions import -i "$DECISIONS_FILE"; then
            echo "Decisions imported successfully."
        else
            echo "Error importing decisions." >&2
        fi
    else
        echo "Error: cscli command not found." >&2
        exit 1
    fi
    rm -f "$DECISIONS_FILE"
}

main() {
    load_config
    fetch_blacklist
    map_to_crowdsec_decisions
    import_decisions
}

main