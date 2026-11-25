#!/usr/bin/env bash

# HASZNÁLAT: ./letolto.sh <URL_LISTA> [CÉLKÖNYVTÁR] [LOGFÁJL]

set -euo pipefail

if [ "$#" -lt 1 ] || [ ! -f "$1" ]; then
    printf 'HIBA: Adj meg egy letezo URL-listat!\n' >&2
    exit 1
fi

URL_LIST="$1"
DEST_DIR="${2:-./letoltesek}"
LOG_FILE="${3:-./letoltes.log}"

mkdir -p "$DEST_DIR"
: > "$LOG_FILE"

TMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

log_msg() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

download_with_retry() {
    local url="$1"
    local out_name="$2"
    local tmp_file="$TMP_DIR/$out_name"
    local dest_file="$DEST_DIR/$out_name"
    local attempt=1
    local max_attempts=3
    local delay=1

    while [ "$attempt" -le "$max_attempts" ]; do
        log_msg "Probalkozas ($attempt/$max_attempts):$url"
        
        # A set -e csapda kikerulese: if feltetelben a nem-0 exit kod nem allitja le a scriptet
        if curl -fsS --connect-timeout 5 --max-time 6 "$url" -o "$tmp_file" 2>>"$LOG_FILE"; then
            if [ -s "$tmp_file" ]; then
                mv "$tmp_file" "$dest_file"
                log_msg "SIKER: $url ->$dest_file"
                return 0
            fi
        fi

        rm -f "$tmp_file"
        log_msg "HIBA a(z) $attempt. probalkozasnal: $url"

        if [ "$attempt" -lt "$max_attempts" ]; then
            log_msg "Varakozas ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))
        fi
        attempt=$((attempt + 1))
    done

    return 1
}

main() {
    local ok_count=0
    local fail_count=0
    local idx=0
    local failed_urls=()

    log_msg "Letoltes inditasa. Ideiglenes konyvtar: $TMP_DIR"

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        [ -z "$line" ] && continue
        [[ "$line" == \#* ]] && continue

        idx=$((idx + 1))
        local fname="fajl_${idx}.json"

        printf 'Feldolgozas (%d): %s ... ' "$idx" "$line"
        if download_with_retry "$line" "$fname"; then
            printf 'OK\n'
            ok_count=$((ok_count + 1))
        else
            printf 'SIKERTELEN\n'
            fail_count=$((fail_count + 1))
            failed_urls+=("$line")
        fi
    done < "$URL_LIST"

    printf '\n=== ÖSSZEFOGLALÓ ===\n'
    printf 'Sikeres: %d | Sikertelen: %d\n' "$ok_count" "$fail_count"
    log_msg "Befejezve. Sikeres: $ok_count, Sikertelen:$fail_count"

    if [ "$fail_count" -gt 0 ]; then
        printf 'Sikertelen URL-ek (halozati / HTTP / timeout hiba):\n'
        printf '  - %s\n' "${failed_urls[@]}"
        exit 1
    fi

    exit 0
}

main