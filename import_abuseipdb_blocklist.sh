#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

fetch_blocklist() {
	response=$(curl -s -H "Key: $API_KEY" -H "Accept: application/json" "https://api.abuseipdb.com/api/v2/blacklist?confidenceMinimum=$CONFIDENCE_MINIMUM")
	echo "$response" | jq -r '.data // []' > "$DECISIONS_FILE"
}

map_to_crowdsec_decisions() {
	jq -r --arg duration "$BAN_DURATION" 'map({
		duration: $duration,
		reason: "abuseipdb blocklist",
		scope: "ip",
		type: "ban",
		value: .ipAddress
	})' "$DECISIONS_FILE" > "$DECISIONS_FILE.tmp"
	mv "$DECISIONS_FILE.tmp" "$DECISIONS_FILE"
}

main() {
	load_config

	if [[ -z "$API_KEY" || "$API_KEY" == "YOUR_API_KEY" ]]; then
		echo "Error: API key missing in config.json" >&2
		exit 1
	fi

	fetch_blocklist
	map_to_crowdsec_decisions
	import_decisions
}

main
