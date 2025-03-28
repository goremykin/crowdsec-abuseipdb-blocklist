#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

fetch_blocklist() {
	curl -s "https://raw.githubusercontent.com/borestad/blocklist-abuseipdb/refs/heads/main/abuseipdb-s100-$BORESTAD_BLOCKLIST_PERIOD.ipv4" | grep -v '^#' | awk '{print $1}' > "$DECISIONS_FILE"
}

map_to_crowdsec_decisions() {
	jq -Rn --arg duration "$BAN_DURATION" ' 
        [inputs | select(test("^[0-9.]+$")) | 
        {duration: $duration, reason: "borestad blocklist", scope: "ip", type: "ban", value: .}]
    ' "$DECISIONS_FILE" > "$DECISIONS_FILE.tmp"
    mv "$DECISIONS_FILE.tmp" "$DECISIONS_FILE"
}

main() {
	load_config
	fetch_blocklist
	map_to_crowdsec_decisions
	import_decisions
}

main