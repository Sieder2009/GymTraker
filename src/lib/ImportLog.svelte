<script>
  import { programs, trainState } from './stores.js';
  import { parseLog, toWeekdayPlan } from './logParser.js';
  import { todayIndexForProgram } from './data.js';
  import { toast } from './toast.js';

  export let open = false;

  let rawText = '';
  let parsed = null; // { days, warnings }
  let planName = 'Importierter Plan';
  let fileInput;

  $: if (!open) {
    parsed = null;
    rawText = '';
  }

  function onFile(e) {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => { rawText = reader.result; };
    reader.readAsText(file, 'utf-8');
  }

  function analyze() {
    if (!rawText.trim()) { toast('Bitte zuerst Text einfügen oder eine Datei wählen 📄'); return; }
    parsed = parseLog(rawText);
  }

  function savePlan() {
    if (!parsed || !parsed.days.length) return;
    const name = planName.trim() || 'Importierter Plan';
    const days = toWeekdayPlan(parsed.days);
    const id = 'imported_' + Date.now();
    const newPlan = {
      id, name, mode: 'weekday',
      completed: 0, currentDayIdx: 0,
      startDate: new Date().toISOString().slice(0, 10),
      days,
    };
    programs.update(all => [...all, newPlan]);
    trainState.set({ activePlanId: id, viewedDayIdx: todayIndexForProgram(newPlan) });
    toast('Log importiert ✅');
    open = false;
    rawText = '';
    parsed = null;
  }
</script>

{#if open}
<div class="overlay open">
  <div class="ov-top">
    <button class="iconbtn" on:click={() => (open = false)}>✕</button>
    <div style="font-family:'Sora';font-weight:700;font-size:15px">Log importieren</div>
    <span style="width:40px"></span>
  </div>

  <div class="pe-scroll">
    {#if !parsed}
      <div class="card">
        <div class="eyebrow">Log-Datei (.txt) oder Text</div>
        <button class="cta ghost" style="margin-top:8px" on:click={() => fileInput.click()}>📄 Datei auswählen</button>
        <input type="file" accept=".txt" bind:this={fileInput} on:change={onFile} style="display:none">
        <textarea class="pe-input import-textarea" rows="8" placeholder="…oder Log-Text hier einfügen" bind:value={rawText}></textarea>
        <p class="radar-hint" style="text-align:left;margin-top:10px">
          Erwartetes Format: Tage als "1. Wochentag", "2. Wochentag" usw. Darunter Übungsnamen
          (optional mit "2x6-10"-Schema) und darunter Zeilen, die mit dem Gewicht beginnen
          (z. B. "135kg x5 …"). Tag 1–6 werden auf Montag–Samstag gelegt, Sonntag bleibt Ruhetag.
        </p>
      </div>
      <button class="cta" on:click={analyze}>Analysieren</button>
    {:else if parsed.days.length}
      <div class="card">
        <div class="eyebrow">Name des Plans</div>
        <input class="pe-input" bind:value={planName}>
      </div>

      {#if parsed.warnings.length}
        <div class="card" style="border-color:var(--yellow)">
          <div class="eyebrow" style="color:var(--yellow)">Hinweise ({parsed.warnings.length})</div>
          {#each parsed.warnings as w}
            <p class="radar-hint" style="text-align:left;margin-top:6px">{w}</p>
          {/each}
        </div>
      {/if}

      <div class="eyebrow" style="margin:6px 4px 8px">Vorschau</div>
      {#each parsed.days as d}
        <div class="plain-ex">
          <div class="plain-ex-name">Tag {d.num} · {d.exercises.length} Übungen</div>
          {#each d.exercises as ex}
            <div class="plain-set">
              <span class="progress-name">{ex.name}</span>
              <span class="plain-w">{ex.weight > 0 ? ex.weight + ' kg' : 'BW'}</span>
              <span class="plain-r">{ex.sets}×{ex.reps}</span>
            </div>
          {/each}
        </div>
      {/each}

      <button class="cta ghost" on:click={() => (parsed = null)}>← Zurück</button>
      <button class="cta" on:click={savePlan}>Plan speichern</button>
    {:else}
      <div class="card">
        {#each parsed.warnings as w}
          <p class="radar-hint" style="text-align:left">{w}</p>
        {/each}
      </div>
      <button class="cta ghost" on:click={() => (parsed = null)}>← Zurück</button>
    {/if}
  </div>
</div>
{/if}

<style>
  .import-textarea{ width:100%; resize:vertical; font-family:'Sora',monospace; font-size:12.5px; line-height:1.5; }
</style>
