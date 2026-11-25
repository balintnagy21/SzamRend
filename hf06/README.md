## HF06 — Hibatűrés: `set -euo pipefail`, `trap`, retry

1.Mit csinál a `-e`, `-u` és `pipefail` külön-külön?

- **`set -e` (`errexit`):** Azonnal leállítja a script futását, ha bármelyik parancs nem 0-s kilépési kóddal (hibával) tér vissza (kivéve, ha feltételben, pl. `if` vagy `||` részeként szerepel).
- **`set -u` (`nounset`):** Hibát dob és leállítja a scriptet, ha egy olyan változóra hivatkozunk, amelyik még nem lett definiálva (elgépelések ellen véd).
- **`set -o pipefail`:** Alapértelmezetten egy csővezeték (`cmd1 | cmd2`) csak az utolsó parancs exit kódját adja vissza. A `pipefail` bekapcsolásával az egész csővezeték hibásnak számít, ha benne bármelyik parancs elbukik.

2.Hogyan oldottam meg a `set -e` csapdát?

A `curl` parancsot egy **`if` feltételbe** tettem (`if curl ...; then`). A Bash szabályai szerint a `set -e` nem állítja le a scriptet, ha egy parancs közvetlenül egy `if` feltételében hibázik — így el tudom kapni a sikertelen letöltést, naplózni a hibát, és elindítani a következő újrapróbálkozást.

3.Egy futás logja (`futas.log`)

```text
[2026-11-25 20:05:57] Letoltes inditasa. Ideiglenes konyvtar: /tmp/tmp.pUk5g2FG29
[2026-11-25 20:05:57] Probalkozas (1/3):https://api.frankfurter.dev/v1/latest
[2026-11-25 20:05:58] SIKER: https://api.frankfurter.dev/v1/latest ->hf06/eredmeny/fajl_1.json
[2026-11-25 20:05:58] Probalkozas (1/3):https://api.open-meteo.com/v1/forecast?latitude=47.5&longitude=19.05&current=temperature_2m
[2026-11-25 20:05:59] SIKER: https://api.open-meteo.com/v1/forecast?latitude=47.5&longitude=19.05&current=temperature_2m ->hf06/eredmeny/fajl_2.json
[2026-11-25 20:05:59] Probalkozas (1/3):https://date.nager.at/api/v3/PublicHolidays/2026/HU
[2026-11-25 20:06:00] SIKER: https://date.nager.at/api/v3/PublicHolidays/2026/HU ->hf06/eredmeny/fajl_3.json
[2026-11-25 20:06:00] Probalkozas (1/3):https://httpbin.org/status/500
curl: (22) The requested URL returned error: 500
[2026-11-25 20:06:01] HIBA a(z) 1. probalkozasnal: https://httpbin.org/status/500
[2026-11-25 20:06:01] Varakozas 1s...
[2026-11-25 20:06:02] Probalkozas (2/3):https://httpbin.org/status/500
curl: (22) The requested URL returned error: 500
[2026-11-25 20:06:03] HIBA a(z) 2. probalkozasnal: https://httpbin.org/status/500
[2026-11-25 20:06:03] Varakozas 2s...
[2026-11-25 20:06:05] Probalkozas (3/3):https://httpbin.org/status/500
curl: (22) The requested URL returned error: 500
[2026-11-25 20:06:06] HIBA a(z) 3. probalkozasnal: https://httpbin.org/status/500
[2026-11-25 20:06:06] Probalkozas (1/3):https://httpbin.org/delay/10
curl: (28) Operation timed out after 6011 milliseconds with 0 bytes received
[2026-11-25 20:06:12] HIBA a(z) 1. probalkozasnal: https://httpbin.org/delay/10
[2026-11-25 20:06:12] Varakozas 1s...
[2026-11-25 20:06:13] Probalkozas (2/3):https://httpbin.org/delay/10
curl: (28) Operation timed out after 6010 milliseconds with 0 bytes received
[2026-11-25 20:06:19] HIBA a(z) 2. probalkozasnal: https://httpbin.org/delay/10
[2026-11-25 20:06:19] Varakozas 2s...
[2026-11-25 20:06:22] Probalkozas (3/3):https://httpbin.org/delay/10
curl: (28) Operation timed out after 6013 milliseconds with 0 bytes received
[2026-11-25 20:06:28] HIBA a(z) 3. probalkozasnal: https://httpbin.org/delay/10
[2026-11-25 20:06:28] Probalkozas (1/3):https://ez.a.domain.biztosan.nem.letezik/valami.json
curl: (6) Could not resolve host: ez.a.domain.biztosan.nem.letezik
[2026-11-25 20:06:28] HIBA a(z) 1. probalkozasnal: https://ez.a.domain.biztosan.nem.letezik/valami.json
[2026-11-25 20:06:28] Varakozas 1s...
[2026-11-25 20:06:29] Probalkozas (2/3):https://ez.a.domain.biztosan.nem.letezik/valami.json
curl: (6) Could not resolve host: ez.a.domain.biztosan.nem.letezik
[2026-11-25 20:06:29] HIBA a(z) 2. probalkozasnal: https://ez.a.domain.biztosan.nem.letezik/valami.json
[2026-11-25 20:06:29] Varakozas 2s...
[2026-11-25 20:06:32] Probalkozas (3/3):https://ez.a.domain.biztosan.nem.letezik/valami.json
curl: (6) Could not resolve host: ez.a.domain.biztosan.nem.letezik
[2026-11-25 20:06:32] HIBA a(z) 3. probalkozasnal: https://ez.a.domain.biztosan.nem.letezik/valami.json
[2026-11-25 20:06:32] Befejezve. Sikeres: 3, Sikertelen:3
