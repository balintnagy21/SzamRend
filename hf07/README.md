# HF07 — Ütemezés és mentés (cron + retenció)

## 1. Ütemezés (crontab -l)

Minden nap hajnali 3:00-kor lefutó mentés abszolút útvonalakkal:

```cron
0 3 * * * /home/felhasznalo/SzamRend/hf07/mentes.sh /home/felhasznalo/SzamRend/hf07/teszt_forras /home/felhasznalo/SzamRend/hf07/mentesek
```

## 2. Mentési log (mentes.log)

```text
[2026-11-25 21:00:03] Mentes inditasa: /c/Users/Admin/Desktop/SzamRend/hf07/teszt_forras -> /c/Users/Admin/Desktop/SzamRend/hf07/mentesek (Retencio: 7 db)
[2026-11-25 21:00:03] Mentes kesz: mentes-2026-11-25-2100.tar.gz (Meret: 1.0K, Fajlok: 1 db)
```

## 3. Sérült archívum visszatöltésének elutasítása

```text
./hf07/visszatoltes.sh: line 58: [: too many arguments
Ellenorzoosszeg vizsgalata (mentes-2026-11-25-2100.tar.gz)... SIKERTELEN!
HIBA: Az archivum serult (SHA256 elteres)! Visszatoltes megszakitva.
```
