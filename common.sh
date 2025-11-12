#!/bin/bash

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
	CONTAINER_NAME=$(jq -r '.crowdsecContainerName // ""' "$CONFIG_FILE")
	DECISIONS_FILE="$(dirname "$0")/decisions.json"

	if [[ -z "$API_KEY" || "$API_KEY" == "null" ]]; then
		echo "Error: API key missing in config.json" >&2
		exit 1
	fi
}

import_decisions() {
	handle_error() {
		echo "Error: $1" >&2
		exit 1
	}

	import_local_decisions() {
		if ! command -v cscli >/dev/null 2>&1; then
			handle_error "cscli command not found."
		fi

		if cscli decisions import -i "$DECISIONS_FILE"; then
			echo "Decisions imported successfully."
		else
			handle_error "Failed to import decisions."
		fi
	}

	import_docker_decisions() {
		local container_path="/tmp/decisions.json"

		docker cp "$DECISIONS_FILE" "$CONTAINER_NAME:$container_path" \
			|| handle_error "Failed to copy decisions file to Docker container '$CONTAINER_NAME'."

		if docker exec "$CONTAINER_NAME" cscli decisions import -i "$container_path"; then
			echo "Decisions imported successfully into Docker container."
		else
			handle_error "Failed to import decisions into Docker container '$CONTAINER_NAME'."
		fi
	}

	if [ -z "${CONTAINER_NAME:-}" ]; then
			import_local_decisions
		else
			import_docker_decisions
		fi

	rm -f "$DECISIONS_FILE"
}
