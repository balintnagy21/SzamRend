#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 1 ] || [ ! -f "$1" ]; then
    printf 'HIBA: Adj meg egy letezo logfajlt!\n' >&2
    exit 1
fi

awk '
{
    total++
    ip[$1]++
    st[$9]++
    if ($9 >= 400) err[$7]++

    if (match($4, /:[0-9]{2}:/)) {
        hr[substr($4, RSTART + 1, 2)]++
    }

    sum_all += $NF
    if ($9 == 200) { sum_200 += $NF; cnt_200++ }
    if ($9 == 500) { sum_500 += $NF; cnt_500++ }
}
END {
    if (total == 0) exit 0

    printf "Osszes keres: %d | Egyedi IP: %d\n\n", total, length(ip)

    printf "Top 10 IP:\n"
    for (i = 1; i <= 10 && i <= length(ip); i++) {
        max_c = -1; max_k = ""
        for (k in ip) {
            if (!(k in used) && ip[k] > max_c) { max_c = ip[k]; max_k = k }
        }
        used[max_k] = 1
        if (i == 1) { top_ip = max_k; top_cnt = max_c }
        printf "%-18s %d\n", max_k, max_c
    }

    printf "\nStatuszkodok:\n"
    n = asorti(st, s_st)
    for (i = 1; i <= n; i++) {
        k = s_st[i]
        printf "%-6s %-8d %.1f%%\n", k, st[k], (st[k] / total) * 100
    }

    printf "\nHibas keresek (4xx/5xx):\n"
    n = asorti(err, s_err)
    for (i = 1; i <= n; i++) {
        k = s_err[i]
        printf "%-20s %d\n", k, err[k]
    }

    printf "\nOrankenti bontas:\n"
    n = asorti(hr, s_hr)
    peak_c = -1
    for (i = 1; i <= n; i++) {
        k = s_hr[i]
        if (hr[k] > peak_c) { peak_c = hr[k]; peak_h = k }
        printf "%s:00  %d\n", k, hr[k]
    }
    printf "Csucs: %s:00 (%d keres)\n", peak_h, peak_c

    printf "\nAtlagos valaszidok:\n"
    printf "Osszes: %.3f mp\n", sum_all / total
    printf "200-as: %.3f mp\n", (cnt_200 ? sum_200 / cnt_200 : 0)
    printf "500-as: %.3f mp\n", (cnt_500 ? sum_500 / cnt_500 : 0)

    printf "\nA legaktivabb IP a %s, ami az osszes keres %.1f%%-at adta.\n", top_ip, (top_cnt / total) * 100
}
' "$1"