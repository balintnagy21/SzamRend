#!/usr/bin/env bash

# mit csinal: Egy rövid összefoglalót ír ki a rendszer állapotáról.
# hogyan kell meghívni: bashban(a jó mappában) ./rendszerinfo.sh [KIMENETI_FÁJL]
# mit ad vissza: 0: Sikeres futás
#                1: A megadott kimeneti fájl nem írható

set -uo pipefail

if [ "$#" -gt 0 ] && ! touch "$1" 2>/dev/null; then
    printf 'HIBA: Nem írható a fájl: %s\n' "$1" >&2
    exit 1
fi

HOST_NAME=$(hostname 2>/dev/null || echo "N/A")
KERNEL_VER=$(uname -r 2>/dev/null || echo "N/A")
CURRENT_USER=$(whoami 2>/dev/null || echo "N/A")
HOME_SIZE=$(ls -lh "$HOME" 2>/dev/null | head -n 1 | awk '{print $2}' || echo "N/A")
DISK_FREE=$(df -h / 2>/dev/null | awk 'NR==2 {print $4}' || echo "N/A")
PROC_COUNT=$(ps -e 2>/dev/null | wc -l || echo "N/A")

if command -v uptime >/dev/null 2>&1; then
    UPTIME_INFO=$(uptime)
elif [ -f /proc/uptime ]; then
    UPTIME_SECS=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)
    UPTIME_INFO="$((UPTIME_SECS / 3600))h $(((UPTIME_SECS % 3600) / 60))m"
else
    UPTIME_INFO="N/A"
fi

INFO_TEXT="Hosztnév:              \"$HOST_NAME\"
Kernel verzió:         \"$KERNEL_VER\"
Uptime:                \"$UPTIME_INFO\"
Bejelentkezett user:   \"$CURRENT_USER\"
Home könyvtár mérete:  \"$HOME_SIZE\"
Szabad hely (/):       \"$DISK_FREE\"
Futó folyamatok:       \"$PROC_COUNT\""

if [ "$#" -gt 0 ]; then
    printf '%s\n' "$INFO_TEXT" > "$1"
else
    printf '%s\n' "$INFO_TEXT"
fi

exit 0