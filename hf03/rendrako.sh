#!/usr/bin/env bash

set -uo pipefail

if [ "$#" -lt 1 ] || [ ! -d "$1" ]; then
    printf 'HIBA: Adj meg egy letezo konyvtarat!\n' >&2
    exit 1
fi

DIR="${1%/}"
RENDEZD=0
if [ "${2:-}" = "--rendezd" ]; then
    RENDEZD=1
fi

# 1. RÉSZ — JELENTÉS
FILE_COUNT=$(find "$DIR" -path "$DIR/_rendezett" -prune -o -type f -print | wc -l)
DIR_COUNT=$(find "$DIR" -path "$DIR/_rendezett" -prune -o -type d -print | wc -l)
OLD_COUNT=$(find "$DIR" -path "$DIR/_rendezett" -prune -o -type f -mtime +30 -print | wc -l)

printf '=== JELENTÉS: %s ===\n' "$DIR"
printf 'Fájlok száma: %s | Könyvtárak száma: %s\n' "$FILE_COUNT" "$DIR_COUNT"
printf '30 napnál régebbi fájlok: %s\n\n' "$OLD_COUNT"

printf -- '--- 5 legnagyobb fájl ---\n'
find "$DIR" -path "$DIR/_rendezett" -prune -o -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n 5

printf '\n--- Üres fájlok ---\n'
find "$DIR" -path "$DIR/_rendezett" -prune -o -type f -empty -print

printf '\n--- Kiterjesztések megoszlása ---\n'
find "$DIR" -path "$DIR/_rendezett" -prune -o -type f -print0 | while IFS= read -r -d '' f; do
    base=$(basename "$f")
    if [[ "$base" == *.* && "$base" != .* ]]; then
        printf '%s\n' "${base##*.}"
    else
        printf '(nincs)\n'
    fi
done | sort | uniq -c | sort -rn

printf '\n--- Mindenki által írható fájlok (-o+w) ---\n'
find "$DIR" -path "$DIR/_rendezett" -prune -o -type f -perm -o+w -print

# 2. RÉSZ — RENDRAKÁS (csak --rendezd kapcsolóval)
if [ "$RENDEZD" -eq 1 ]; then
    printf '\n=== RENDRAKÁS INDÍTÁSA ===\n'
    printf 'Műveletek: fájlok másolása a(z) %s/_rendezett/ alá és o-w jog elvétele.\n\n' "$DIR"

    mkdir -p "$DIR/_rendezett"

    find "$DIR" -path "$DIR/_rendezett" -prune -o -type f -print0 | while IFS= read -r -d '' f; do
        if [ -n "$(find "$f" -prune -perm -o+w 2>/dev/null)" ]; then
            chmod o-w "$f"
            printf 'Jog elvéve (o-w): %s\n' "$f"
        fi

        base=$(basename "$f")
        if [[ "$base" == *.* && "$base" != .* ]]; then
            ext="${base##*.}"
        else
            ext="_egyeb"
        fi

        mkdir -p "$DIR/_rendezett/$ext"
        cp -n "$f" "$DIR/_rendezett/$ext/"
    done

    printf '\nRendrakás kész!\n'
fi

exit 0