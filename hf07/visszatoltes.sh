#!/usr/bin/env bash

# HASZNÁLAT:
#   ./visszatoltes.sh <MENTES_KONYVTAR> --lista
#   ./visszatoltes.sh <MENTES_KONYVTAR> <MENTES_NEV | --legutobbi> <CEL_KONYVTAR> [--proba]

set -euo pipefail

if [ "$#" -lt 2 ]; then
    printf 'Hasznalat:\n' >&2
    printf '  %s <MENTES_DIR> --lista\n' "$0" >&2
    printf '  %s <MENTES_DIR> <MENTES_NEV|--legutobbi> <CEL_DIR> [--proba]\n' "$0" >&2
    exit 1
fi

BACKUP_DIR=$(cd "$1" 2>/dev/null && pwd) || { printf 'HIBA: A mentesi konyvtar nem letezik!\n' >&2; exit 1; }
ACTION="$2"

if [ "$ACTION" = "--lista" ]; then
    printf 'Elerheto mentesek (%s):\n' "$BACKUP_DIR"
    printf '%-30s %-10s %s\n' "Archivum" "Meret" "Keszult (meta)"
    printf '%-30s %-10s %s\n' "------------------------------" "----------" "-------------------"
    for f in $(find "$BACKUP_DIR" -maxdepth 1 -name 'mentes-*.tar.gz' -printf '%f\n' | sort); do
        base="${f%.tar.gz}"
        size=$(du -h "$BACKUP_DIR/$f" | awk '{print $1}')
        created=$(grep '^Keszult:' "$BACKUP_DIR/${base}.meta" 2>/dev/null | cut -d' ' -f2- || printf 'ismeretlen')
        printf '%-30s %-10s %s\n' "$f" "$size" "$created"
    done
    exit 0
fi

if [ "$#" -lt 3 ]; then
    printf 'HIBA: Add meg a celkonyvtarat is!\n' >&2
    exit 1
fi

TARGET_DIR="$3"
DRY_RUN=0
if [ "${4:-}" = "--proba" ]; then
    DRY_RUN=1
fi

if [ "$ACTION" = "--legutobbi" ]; then
    LATEST=$(find "$BACKUP_DIR" -maxdepth 1 -name 'mentes-*.tar.gz' -printf '%f\n' | tr -d '\r' | sort | tail -n 1)
    if [[ -z "$LATEST" ]]; then
        printf 'HIBA: Nincs egyetlen mentes sem a konyvtarban!\n' >&2
        exit 1
    fi
    ARCHIVE_NAME="$LATEST"
else
    ARCHIVE_NAME="${ACTION%.tar.gz}.tar.gz"
fi

BASE_NAME="${ARCHIVE_NAME%.tar.gz}"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"
SHA_PATH="$BACKUP_DIR/${BASE_NAME}.sha256"

if [ ! -f "$ARCHIVE_PATH" ] || [ ! -f "$SHA_PATH" ]; then
    printf 'HIBA: Hianyzo archivum vagy .sha256 fajl: %s\n' "$ARCHIVE_NAME" >&2
    exit 1
fi

printf 'Ellenorzoosszeg vizsgalata (%s)... ' "$ARCHIVE_NAME"
if ! (cd "$BACKUP_DIR" && sha256sum -c "${BASE_NAME}.sha256" >/dev/null 2>&1); then
    printf 'SIKERTELEN!\nHIBA: Az archivum serult (SHA256 elteres)! Visszatoltes megszakitva.\n' >&2
    exit 2
fi
printf 'OK\n'

if [ "$DRY_RUN" -eq 1 ]; then
    printf '[PROBA MOD] A kovetkezo fajlok kerulnenek kicsomagolasra ide: %s\n' "$TARGET_DIR"
    tar -tzf "$ARCHIVE_PATH"
    exit 0
fi

if [ -d "$TARGET_DIR" ] && [ -n "$(ls -A "$TARGET_DIR")" ]; then
    printf 'FIGYELEM: A celkonyvtar (%s) nem ures! Felulirhatja a meglevo fajlokat.\n' "$TARGET_DIR"
    printf 'Folytatod a visszatoltest? (i/n): '
    read -r VALASZ
    if [ "$VALASZ" != "i" ] && [ "$VALASZ" != "I" ]; then
        printf 'Visszatoltes megszakitva.\n'
        exit 0
    fi
fi

mkdir -p "$TARGET_DIR"
tar -xzf "$ARCHIVE_PATH" -C "$TARGET_DIR"
printf 'Sikeres visszatoltes ide: %s\n' "$TARGET_DIR"
exit 0
