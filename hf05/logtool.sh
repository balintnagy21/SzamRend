#!/usr/bin/env bash

set -euo pipefail

readonly EX_OK=0
readonly EX_USAGE=2
readonly EX_NOFILE=3

LOG_FILE=""
TOP_N=10
STATUS_FILTER=""
OUTPUT_FILE=""
QUIET=0

usage() {
    cat << 'EOF'
Használat: ./logtool.sh -f FÁJL [OPCIÓK]

Kapcsolók:
  -h, --help          kiírja a használatot és kilép 0-val
  -f, --file FÁJL     a feldolgozandó log (kötelező)
  -t, --top N         hány elemet mutasson a toplistákban (alapértelmezés: 10)
  -s, --status KÓD    csak az adott státuszkódú sorokat nézze
  -o, --output FÁJL   a riportot fájlba írja
  -q, --quiet         csak a végső összefoglaló sort írja ki

Példák:
  ./logtool.sh --help                      # sugo, exit 0
  ./logtool.sh                             # hianyzo -f: hiba + sugo, exit 2
  ./logtool.sh -f nincs.log                # nem letezo fajl: hiba, exit 3
  ./logtool.sh -f access.log -t 3          # 3 elemu toplistak
  ./logtool.sh -f access.log -s 404        # csak a 404-esek
  ./logtool.sh -f access.log -o riport.txt # fajlba
  ./logtool.sh -f access.log -q            # egy sor
  ./logtool.sh -f access.log --izelevele   # ismeretlen kapcsolo: hiba, exit 2
EOF
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help) usage; exit "$EX_OK" ;;
            -f|--file|-t|--top|-s|--status|-o|--output)
                [ "$#" -lt 2 ] && { printf 'HIBA: Hiányzó érték a(z) %s kapcsolóhoz!\n\n' "$1" >&2; usage >&2; exit "$EX_USAGE"; }
                case "$1" in
                    -f|--file) LOG_FILE="$2" ;;
                    -t|--top) TOP_N="$2" ;;
                    -s|--status) STATUS_FILTER="$2" ;;
                    -o|--output) OUTPUT_FILE="$2" ;;
                esac
                shift 2
                ;;
            -q|--quiet) QUIET=1; shift ;;
            *) printf 'HIBA: Ismeretlen kapcsoló: %s\n\n' "$1" >&2; usage >&2; exit "$EX_USAGE" ;;
        esac
    done
}

ellenoriz_bemenet() {
    if [ -z "$LOG_FILE" ]; then
        printf 'HIBA: A -f / --file kapcsoló megadása kötelező!\n\n' >&2
        usage >&2
        exit "$EX_USAGE"
    fi
    if [ ! -f "$LOG_FILE" ]; then
        printf 'HIBA: A fájl nem található: %s\n' "$LOG_FILE" >&2
        exit "$EX_NOFILE"
    fi
    if ! [[ "$TOP_N" =~ ^[1-9][0-9]*$ ]]; then
        printf 'HIBA: A -t értékének pozitív egész számnak kell lennie!\n' >&2
        exit "$EX_USAGE"
    fi
}

top_ip() {
    local file="$1" top="$2" st="$3"
    printf 'Top %s IP:\n' "$top"
    awk -v st="$st" -v top="$top" '
        st == "" || $9 == st { ip[$1]++ }
        END {
            for (i = 1; i <= top && i <= length(ip); i++) {
                max_c = -1; max_k = ""
                for (k in ip) if (!(k in u) && ip[k] > max_c) { max_c = ip[k]; max_k = k }
                u[max_k] = 1
                printf "  %-18s %d\n", max_k, max_c
            }
        }' "$file"
}

statusz_megoszlas() {
    local file="$1" st="$2"
    printf '\nStátuszkód-megoszlás:\n'
    awk -v st="$st" '
        st == "" || $9 == st { cnt[$9]++; tot++ }
        END {
            n = asorti(cnt, s)
            for (i = 1; i <= n; i++) printf "  %-6s %-8d %.1f%%\n", s[i], cnt[s[i]], (cnt[s[i]]/tot)*100
        }' "$file"
}

osszefoglalo() {
    local file="$1" st="$2"
    awk -v st="$st" '
        st == "" || $9 == st { tot++; ip[$1]++; sum += $NF }
        END {
            if (tot == 0) { print "Nincs a szűrésnek megfelelő sor."; exit }
            for (k in ip) if (ip[k] > mc) { mc = ip[k]; mip = k }
            printf "Összes kérés: %d | Egyedi IP: %d | Átlag idő: %.3f mp | Top IP: %s (%.1f%%)\n",
                tot, length(ip), sum/tot, mip, (mc/tot)*100
        }' "$file"
}

main() {
    parse_args "$@"
    ellenoriz_bemenet
    {
        if [ "$QUIET" -eq 0 ]; then
            top_ip "$LOG_FILE" "$TOP_N" "$STATUS_FILTER"
            statusz_megoszlas "$LOG_FILE" "$STATUS_FILTER"
            printf '\nÖsszefoglaló:\n  '
        fi
        osszefoglalo "$LOG_FILE" "$STATUS_FILTER"
    } > "${OUTPUT_FILE:-/dev/stdout}"
}

main "$@"