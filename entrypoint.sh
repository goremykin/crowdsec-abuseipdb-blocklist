#!/bin/bash
set -euo pipefail

import_abuseipdb_blocklist=/app/import_abuseipdb_blocklist.sh
import_borestad_blocklist=/app/import_borestad_blocklist.sh
cron_file=/tmp/crontab

echo "Starting CrowdSec Blocklist Importer (supercronic)..."

API_KEY="${API_KEY:-}"

if [[ -n "${API_KEY_FILE:-}" ]] && [[ -f "$API_KEY_FILE" ]]; then
    API_KEY="$(<"$API_KEY_FILE")"
fi

if [[ -z "$API_KEY" ]]; then
    echo "Error: API key is required (API_KEY or API_KEY_FILE)." >&2
    exit 1
fi

if [[ -z "${CROWDSEC_CONTAINER_NAME:-}" ]]; then
    echo "Error: CROWDSEC_CONTAINER_NAME is required." >&2
    exit 1
fi

CRON_SCHEDULE="${CRON_SCHEDULE:-0 0 * * *}"

if [[ "$(awk '{print NF}' <<<"$CRON_SCHEDULE")" -ne 5 ]]; then
    echo "Error: CRON_SCHEDULE must contain 5 fields." >&2
    exit 1
fi

echo "Using CRON_SCHEDULE: $CRON_SCHEDULE"

is_true() {
    case "$1" in
        1|true|TRUE|True|yes|YES|Yes) return 0 ;;
        *) return 1 ;;
    esac
}

_enable=0

{
    echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    echo "SHELL=/bin/bash"

    if is_true "${ENABLE_ABUSEIPDB:-false}"; then
        echo "${CRON_SCHEDULE} /bin/bash ${import_abuseipdb_blocklist}"
        _enable=1
    fi

    if is_true "${ENABLE_BORESTAD:-false}"; then
        echo "${CRON_SCHEDULE} /bin/bash ${import_borestad_blocklist}"
        _enable=1
    fi
} >"$cron_file"

if [[ "$_enable" -eq 0 ]]; then
    echo "Error: At least one blocklist must be enabled." >&2
    exit 1
fi

echo "Installed crontab:"
cat "$cron_file"

echo "Starting supercronic..."
exec /usr/local/bin/supercronic "$cron_file"