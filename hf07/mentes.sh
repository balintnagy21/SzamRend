#!/usr/bin/env bash

# HASZNÁLAT: ./mentes.sh <FORRÁS_KÖNYVTÁR> <CÉL_KÖNYVTÁR> [RETENCIÓ_DB]

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
set -euo pipefail

if [ "$#" -lt 2 ]; then
    printf 'HIBA: Hasznalat: %s <FORRAS_KONYVTAR> <CEL_KONYVTAR> [RETENCIO_DB]\n' "$0" >&2
    exit 1
fi

SRC_DIR=$(cd "$1" 2>/dev/null && pwd) || { printf 'HIBA: A forraskonyvtar nem letezik: %s\n' "$1" >&2; exit 1; }
mkdir -p "$2"
DEST_DIR=$(cd "$2" && pwd)
KEEP_COUNT="${3:-7}"

LOG_FILE="$DEST_DIR/mentes.log"
LOCK_FILE="$DEST_DIR/.mentes.lock"

log_msg() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

if [ -f "$LOCK_FILE" ]; then
    OLD_PID=$(cat "$LOCK_FILE" 2>/dev/null || true)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        printf 'HIBA: Mar fut egy mentesi folyamat (PID: %s)!\n' "$OLD_PID" >&2
        log_msg "FIGYELEM: Parhuzamos inditas megallitva (mar fut PID: $OLD_PID)."
        exit 1
    fi
fi

printf '%d\n' "$$" > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

log_msg "Mentes inditasa: $SRC_DIR -> $DEST_DIR (Retencio: $KEEP_COUNT db)"

TIMESTAMP=$(date '+%Y-%m-%d-%H%M')
BASE_NAME="mentes-${TIMESTAMP}"
ARCHIVE="$DEST_DIR/${BASE_NAME}.tar.gz"
SHA_FILE="$DEST_DIR/${BASE_NAME}.sha256"
META_FILE="$DEST_DIR/${BASE_NAME}.meta"

tar -czf "$ARCHIVE" -C "$SRC_DIR" .

(cd "$DEST_DIR" && sha256sum "${BASE_NAME}.tar.gz" > "$SHA_FILE")

SIZE_HUMAN=$(du -h "$ARCHIVE" | awk '{print $1}')
FILE_COUNT=$(tar -tzf "$ARCHIVE" | grep -v '/$' | wc -l)

cat << EOF > "$META_FILE"
Keszult: $(date '+%Y-%m-%d %H:%M:%S')
Forras: $SRC_DIR
Meret: $SIZE_HUMAN
Fajlok szama: $FILE_COUNT
EOF

log_msg "Mentes kesz: ${BASE_NAME}.tar.gz (Meret: $SIZE_HUMAN, Fajlok: $FILE_COUNT db)"

mapfile -t ARCHIVES < <(find "$DEST_DIR" -maxdepth 1 -name 'mentes-*.tar.gz' -printf '%f\n' | sort)
TOTAL_ARCHIVES="${#ARCHIVES[@]}"

if [ "$TOTAL_ARCHIVES" -gt "$KEEP_COUNT" ]; then
    DEL_COUNT=$((TOTAL_ARCHIVES - KEEP_COUNT))
    for ((i = 0; i < DEL_COUNT; i++)); do
        OLD_BASE="${ARCHIVES[$i]%.tar.gz}"
        rm -f "$DEST_DIR/${OLD_BASE}.tar.gz" "$DEST_DIR/${OLD_BASE}.sha256" "$DEST_DIR/${OLD_BASE}.meta"
        log_msg "Retencio - torolve: ${OLD_BASE}.tar.gz"
    done
fi

exit 0
