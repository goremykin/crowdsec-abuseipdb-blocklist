#!/bin/bash

load_config() {
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ "${CONFIG_BY_ENV:-false}" != true ]]; then
        CONFIG_FILE="${SCRIPT_DIR}/config.json"
        if [[ ! -f "$CONFIG_FILE" ]]; then
            echo "Error: Config file not found: $CONFIG_FILE" >&2
            exit 1
        fi

        API_KEY="$(jq -r '.apiKey // ""' "$CONFIG_FILE")"
        CONFIDENCE_MINIMUM="$(jq -r '.confidenceMinimum // 75' "$CONFIG_FILE")"
        BAN_DURATION="$(jq -r '.banDuration // "24h"' "$CONFIG_FILE")"
        BORESTAD_BLOCKLIST_PERIOD="$(jq -r '.borestadBlocklistPeriod // "7d"' "$CONFIG_FILE")"
        CONTAINER_NAME="$(jq -r '.crowdsecContainerName // ""' "$CONFIG_FILE")"
        DECISIONS_FILE="${SCRIPT_DIR}/decisions.json"
    else
        API_KEY="${API_KEY:-}"
        CONFIDENCE_MINIMUM="${CONFIDENCE_MINIMUM:-75}"
        BAN_DURATION="${BAN_DURATION:-24h}"
        BORESTAD_BLOCKLIST_PERIOD="${BORESTAD_BLOCKLIST_PERIOD:-7d}"
        CONTAINER_NAME="${CROWDSEC_CONTAINER_NAME:-}"
        DECISIONS_FILE="/tmp/decisions.json"

        if [[ -n "${API_KEY_FILE:-}" ]] && [[ -f "$API_KEY_FILE" ]]; then
            API_KEY="$(<"$API_KEY_FILE")"
        fi
    fi

    # Validate required parameters
    if [[ -z "$API_KEY" ]]; then
        echo "Error: API key is required." >&2
        exit 1
    fi

    if [[ -z "$CONTAINER_NAME" ]]; then
        echo "Error: CrowdSec container name is required." >&2
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
