#!/bin/bash

DECISIONS_FILE="$(dirname "$0")/decisions.json"

load_config() {
	CONFIG_FILE="$(dirname "$0")/config.json"

	if [[ ! -f "$CONFIG_FILE" ]]; then
		echo "Error: Config file not found." >&2
		exit 1
	fi
	API_KEY=$(jq -r '.apiKey' "$CONFIG_FILE")
	CONFIDENCE_MINIMUM=$(jq -r '.confidenceMinimum // "75"' "$CONFIG_FILE")
	BAN_DURATION=$(jq -r '.banDuration // "24h"' "$CONFIG_FILE")
	BORESTAD_BLOCKLIST_PERIOD=$(jq -r '.borestadBlocklistPeriod // "7d"' "$CONFIG_FILE")

	if [[ -z "$API_KEY" || "$API_KEY" == "null" ]]; then
		echo "Error: API key missing in config.json" >&2
		exit 1
	fi
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