# Ironpeak Fitness

Eine Windows-Desktop-App (Vite + Svelte + Electron) für Trainingspläne,
Kraft-Fortschritt (Bench/Deadlift/Squat) und Muskelgruppen-Balance. Alle Daten
bleiben **komplett lokal auf deinem PC** (`localStorage` im App-Fenster) —
keine Cloud, kein Server, keine Internetverbindung nötig. Ein frischer
Download startet mit einer leeren Planliste — du legst deinen eigenen Plan
an, importierst dein eigenes Log oder lädst den mitgelieferten Beispielplan,
um die App direkt mit echten Daten auszuprobieren.

## Herunterladen & Verwenden

1. Auf der **[Releases-Seite](../../releases)** dieses Repos die neueste
   `Ironpeak-Fitness-*-portable.exe` herunterladen.
2. Datei doppelklicken — fertig, keine Installation nötig.
3. Windows SmartScreen warnt beim ersten Start ggf. vor der unbekannten
   `.exe` (die App ist nicht kommerziell signiert). Auf **"Weitere
   Informationen"** und dann **"Trotzdem ausführen"** klicken.

Jede neue Version wird automatisch von GitHub Actions gebaut, sobald ein
Versions-Tag (`vX.Y.Z`) gepusht wird — siehe `.github/workflows/release.yml`.

## Entwicklung

Node.js (Version 18+) wird benötigt.

```bash
npm install
npm run dev          # Browser-Entwicklungsserver (Vite)
npm run electron:dev # App im Electron-Fenster, mit Hot-Reload
npm run electron:build # Windows-.exe bauen (landet in release/)
```

Der Entwicklungsserver zeigt dir eine lokale Adresse (z. B. `http://localhost:5173`) —
im Handy-Browser im selben WLAN kannst du stattdessen die "Network"-Adresse öffnen,
die beim Start mit angezeigt wird.

## Trainingsplan anlegen & nutzen

Auf der Trainingsplan-Seite (bzw. beim ersten Start direkt im Hauptbildschirm)
gibt es drei Optionen, um einen Plan zu bekommen:

- **+ Neuer Plan** — eigenen Plan Tag für Tag von Hand zusammenstellen.
- **📄 Log importieren** — eigenes handgeschriebenes Trainingslog als `.txt`
  hochladen oder Text einfügen.
- **⭐ Beispielplan laden** — lädt ein mitgeliefertes, echtes Trainingslog
  (`src/lib/exampleLog.js`), um die App direkt auszuprobieren; lässt sich
  danach ganz normal als eigener Plan weiterführen.

Bei Plänen "nach Wochentag" kannst du oben über die Tag-Auswahl (Mo–So)
jederzeit selbst wählen, welchen Tag du dir ansiehst — nicht nur den
heutigen. Auf eine Übung tippen öffnet die Detailansicht: das zuletzt
verwendete Gewicht lässt sich dort nach links/rechts ziehen, um es zu ändern,
danach trägst du die Wiederholungen pro Satz ein. "Speichern" sichert den
Eintrag im Verlauf und springt automatisch zur nächsten Übung des Tages.
Dort lässt sich eine Übung auch **umbenennen** (Stift-Icon, Verlauf bleibt
erhalten) oder nachträglich **Verlauf-Text einfügen** ("+ Verlauf einfügen"),
der genauso gelesen wird wie beim Log-Import.

Übungen, die an **jedem Trainingstag** gemacht werden (im Log vor "1.
Wochentag" notiert), erscheinen automatisch zusätzlich zu den Tages-Übungen
— an Ruhetagen nicht.

**Wie die App ein Log liest** (`src/lib/logParser.js`):
- Ein Block `"1PR(27.04.2026)"` gefolgt von `"Deadlift 150kg"`-Zeilen wird als
  Personal Records mit Datum erkannt und befüllt automatisch Bench/Deadlift/
  Squat im Kraft-Tab.
- Eine neue Zeile mit "1. Wochentag", "2. Wochentag" usw. beginnt einen neuen Tag.
  Tag 1–6 werden auf Montag–Samstag gelegt, Sonntag bleibt automatisch Ruhetag.
- Jede Zeile, die **nicht** mit einer Zahl beginnt, gilt als neuer Übungsname
  — z. B. "Deadlift 2x3 nt muskelversagen". Ein "NxM" oder "NxM-M"-Muster darin
  (z. B. "2x6-10") wird als Satz-/Wiederholungsschema übernommen. Ein
  Klammer-Zusatz (z. B. "(Stufe 14)" oder "(Rücken und Beine gerade)") wird als
  eigene Notiz unter dem Namen angezeigt statt einfach im Namen zu verschwinden.
- Jede Zeile, die mit einer Zahl beginnt (z. B. "135kg x5 2.1 1.1 …"), gilt als
  Satz-Zeile der zuletzt genannten Übung. Die App merkt sich davon das
  **höchste geloggte Gewicht** als Startgewicht sowie die komplette
  Satz-für-Satz-Historie ("8.6" = Satz 1: 8, Satz 2: 6 Wiederholungen; nur
  Punkte ohne Zahl, z. B. "....." , heißt "erledigt, ohne Wiederholungszahl").
- Vor dem Speichern zeigt die App eine Vorschau (Tage, tägliche Übungen,
  erkannte PRs, Übungen, Gewichte) sowie Hinweise, falls etwas nicht eindeutig
  war — erst nach Bestätigung wird der Plan wirklich gespeichert.

Das ist ein Best-Effort-Parser für frei getipptes Handwritten-Log-Format, kein
strenges Dateiformat. Bei sehr unregelmäßig geschriebenen Zeilen (Name und
Gewicht in einer Zeile vermischt, Tippfehler wie "2-6-10" statt "2x6-10",
Klammer-Einschübe mitten im Log) kann einzelnes daneben liegen — die Vorschau
vor dem Speichern ist genau dafür da, das kurz zu prüfen und bei Bedarf danach
in der App zu korrigieren.

Existieren mehrere gespeicherte Pläne, fragt die App bei jedem Start zuerst,
welcher davon heute genutzt werden soll.

```
electron/
  main.cjs             Electron-Hauptprozess (öffnet das App-Fenster)
  preload.cjs
src/
  main.js              Einstiegspunkt
  App.svelte           Bildschirm-Umschaltung + Tabbar
  app.css              Design-System (Farben, Karten, Buttons, …)
  lib/
    stores.js          Alle App-Daten (Svelte Stores)
    persisted.js        localStorage-Anbindung für Stores
    data.js             Trainingsplan-Hilfsfunktionen
    exampleLog.js         Mitgeliefertes Beispiel-Trainingslog
    logParser.js         Parser für importierte Log-Texte
    toast.js
    Training.svelte     Plan-/Wochentag-Auswahl, Übungen, Workout starten
    PlanEditor.svelte   Neuen Trainingsplan von Hand anlegen
    ImportLog.svelte    Eigenes Log importieren
    WorkoutOverlay.svelte  Geführtes Workout mit Pausen-Timer & RPE
    ExerciseDetail.svelte  Übungs-Detail: Verlauf & Session-Eingabe
    Strength.svelte     Bench/Deadlift/Squat: PR + Fortschritt
    Progress.svelte     Start→Jetzt-Vergleich & Muskelgruppen-Radar
    RadarChart.svelte
    Toast.svelte
    TabBar.svelte
```
