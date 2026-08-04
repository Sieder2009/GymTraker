# Ironpeak Fitness — Svelte App

Eine "echte" App (Vite + Svelte) statt einer einzelnen HTML-Datei. Alle Daten
(Trainingspläne, Gewichtsverlauf) werden automatisch in `localStorage`
gespeichert — schließt du die App und öffnest sie später wieder, ist alles
noch da. Ein frischer Download startet mit einer leeren Planliste; du kannst
entweder einen eigenen Plan anlegen, dein eigenes Log importieren oder den
mitgelieferten Beispielplan laden, um die App direkt auszuprobieren.

## Lokal starten

Node.js (Version 18+) wird benötigt.

```bash
npm install
npm run dev
```

Der Entwicklungsserver zeigt dir eine lokale Adresse (z. B. `http://localhost:5173`) —
im Handy-Browser im selben WLAN kannst du stattdessen die "Network"-Adresse öffnen,
die beim Start mit angezeigt wird.

## Für den Produktivbetrieb bauen

```bash
npm run build
```

Das Ergebnis landet im Ordner `dist/` — diesen kannst du auf jedem einfachen
Webhost (Netlify, Vercel, GitHub Pages, eigener Server) hochladen.

## "Zur Startseite hinzufügen" (wie eine echte App nutzen)

1. Die gebaute/gehostete Seite auf dem Handy im Browser öffnen.
2. Safari (iOS): Teilen → "Zum Home-Bildschirm".
   Chrome (Android): Menü → "App installieren" / "Zum Startbildschirm hinzufügen".
3. Die App startet danach vollflächig, ganz ohne Browser-Leiste.

## Trainingsplan anlegen

Auf der Trainingsplan-Seite (bzw. beim ersten Start direkt im Hauptbildschirm)
gibt es drei Optionen:

- **+ Neuer Plan** — eigenen Plan Tag für Tag von Hand zusammenstellen.
- **📄 Log importieren** — eigenes handgeschriebenes Trainingslog als `.txt`
  hochladen oder Text einfügen.
- **⭐ Beispielplan laden** — lädt ein mitgeliefertes, echtes Trainingslog
  (`src/lib/exampleLog.js`) über denselben Import-Mechanismus, um die App
  sofort mit echten Daten auszuprobieren.

**Wie die App ein Log liest** (`src/lib/logParser.js`):
- Eine neue Zeile mit "1. Wochentag", "2. Wochentag" usw. beginnt einen neuen Tag.
  Tag 1–6 werden auf Montag–Samstag gelegt, Sonntag bleibt automatisch Ruhetag.
- Jede Zeile, die **nicht** mit einer Zahl beginnt, gilt als neuer Übungsname
  — z. B. "Deadlift 2x3 nt muskelversagen". Ein "NxM" oder "NxM-M"-Muster darin
  (z. B. "2x6-10") wird als Satz-/Wiederholungsschema übernommen.
- Jede Zeile, die mit einer Zahl beginnt (z. B. "135kg x5 2.1 1.1 …"), gilt als
  Satz-Zeile der zuletzt genannten Übung. Die App merkt sich davon nur das
  **höchste geloggte Gewicht** als Startgewicht der Übung.
- Vor dem Speichern zeigt die App eine Vorschau (Tage, Übungen, erkannte
  Gewichte) sowie Hinweise, falls etwas nicht eindeutig war — erst nach
  Bestätigung wird der Plan wirklich gespeichert.

Das ist ein Best-Effort-Parser für frei getipptes Handwritten-Log-Format, kein
strenges Dateiformat. Bei sehr unregelmäßig geschriebenen Zeilen (Name und
Gewicht in einer Zeile vermischt, Tippfehler wie "2-6-10" statt "2x6-10",
Klammer-Einschübe mitten im Log) kann einzelnes daneben liegen — die Vorschau
vor dem Speichern ist genau dafür da, das kurz zu prüfen und bei Bedarf danach
in der App zu korrigieren.

```
src/
  main.js              Einstiegspunkt
  App.svelte           Bildschirm-Umschaltung + Tabbar
  app.css              Design-System (Farben, Karten, Buttons, …)
  lib/
    stores.js          Alle App-Daten (Svelte Stores)
    persisted.js        localStorage-Anbindung für Stores
    data.js             Trainingsplan-Hilfsfunktionen
    exampleLog.js        Mitgeliefertes Beispiel-Trainingslog
    logParser.js         Parser für importierte Log-Texte
    toast.js
    Training.svelte     Plan-Auswahl, Tages-Strip, Übungen, Workout starten
    PlanEditor.svelte   Neuen Trainingsplan von Hand anlegen
    ImportLog.svelte    Log-Import (eigenes Log oder Beispielplan)
    WorkoutOverlay.svelte  Geführtes Workout mit Pausen-Timer & RPE
    Weight.svelte       Gewichtsverlauf
    Progress.svelte     Start→Jetzt-Vergleich & Muskelgruppen-Radar
    RadarChart.svelte
    Toast.svelte
    TabBar.svelte
```
