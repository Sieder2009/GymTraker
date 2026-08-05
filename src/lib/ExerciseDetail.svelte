<script>
  import { onMount, createEventDispatcher } from 'svelte';
  import { fmt1 } from './data.js';
  import { parseExerciseBlock } from './logParser.js';
  import { toast } from './toast.js';

  export let exercises = [];
  export let startIdx = 0;
  export let onSave; // (exIdx, weight, reps[]) => void
  export let onRename = null; // (exIdx, newName) => void
  export let onImportHistory = null; // (exIdx, weight, history[]) => void

  const dispatch = createEventDispatcher();

  const MIN = 0, MAX = 300, STEP = 2.5, PX_PER_TICK = 12; // must match .tick's CSS width+margin-right

  let idx = startIdx;
  let weightInput = 0;
  let repsInputs = [];
  let rulerEl;
  let containerWidth = 320;
  let dragging = false;
  let startX = 0;
  let startValue = 0;
  let renaming = false;
  let renameValue = '';
  let historyPasteOpen = false;
  let historyPasteText = '';

  function loadExercise(i) {
    idx = i;
    const e = exercises[i];
    weightInput = e.sets[e.sets.length - 1]?.w ?? e.startW ?? 0;
    repsInputs = e.sets.map(() => '');
    renaming = false;
    historyPasteOpen = false;
    historyPasteText = '';
  }
  onMount(() => {
    loadExercise(startIdx);
    containerWidth = rulerEl?.clientWidth || 320;
  });

  function startRename() { renameValue = ex.name; renaming = true; }
  function confirmRename() {
    const name = renameValue.trim();
    if (name && onRename) onRename(idx, name);
    renaming = false;
  }

  function applyHistoryPaste() {
    if (!historyPasteText.trim()) return;
    const { weight, history } = parseExerciseBlock(historyPasteText);
    if (!history.length) { toast('Keine Sätze im eingefügten Text erkannt'); return; }
    if (onImportHistory) onImportHistory(idx, weight, history);
    if (weight > 0) weightInput = weight;
    historyPasteText = '';
    historyPasteOpen = false;
    toast('Verlauf übernommen ✅');
  }

  $: ex = exercises[idx];

  $: ticks = Array.from({ length: Math.round((MAX - MIN) / STEP) + 1 }, (_, i) => {
    const v = MIN + i * STEP;
    return { v, major: v % 20 === 0 };
  });
  $: trackX = containerWidth / 2 - ((weightInput - MIN) / STEP) * PX_PER_TICK;

  function onPointerDown(e) {
    dragging = true;
    startX = e.clientX;
    startValue = weightInput;
    rulerEl.setPointerCapture(e.pointerId);
  }
  function onPointerMove(e) {
    if (!dragging) return;
    const dx = e.clientX - startX; // drag right -> increase, drag left -> decrease
    const v = startValue + (dx / PX_PER_TICK) * STEP;
    weightInput = Math.min(MAX, Math.max(MIN, Math.round(v / STEP) * STEP));
  }
  function onPointerUp() { dragging = false; }

  function addSetRow() { repsInputs = [...repsInputs, '']; }
  function removeSetRow(i) { repsInputs = repsInputs.filter((_, j) => j !== i); }

  function save() {
    const reps = repsInputs.map((r) => (r === '' ? 0 : +r));
    onSave(idx, weightInput, reps);
    if (idx < exercises.length - 1) {
      loadExercise(idx + 1);
    } else {
      dispatch('close');
    }
  }

  function formatRep(r) {
    return typeof r === 'number' ? r : r.toUpperCase();
  }
</script>

{#if ex}
<div class="overlay open">
  <div class="ov-top">
    <button class="iconbtn" on:click={() => dispatch('close')}>✕</button>
    {#if renaming}
      <input class="pe-input small" style="max-width:200px" bind:value={renameValue} on:keydown={(e) => e.key === 'Enter' && confirmRename()}>
    {:else}
      <div style="font-family:'Sora';font-weight:700;font-size:15px">{ex.name}</div>
    {/if}
    {#if renaming}
      <button class="iconbtn" on:click={confirmRename}>✓</button>
    {:else}
      <button class="iconbtn" on:click={startRename}>✏️</button>
    {/if}
  </div>
  {#if ex.note}
    <p class="note-line">{ex.note}</p>
  {/if}

  <div class="pe-scroll">
    <div class="card" style="text-align:center">
      <div class="eyebrow">Gewicht heute</div>
      <div class="bigval">{fmt1(weightInput)}<span> kg</span></div>

      <div
        class="ruler"
        bind:this={rulerEl}
        on:pointerdown={onPointerDown}
        on:pointermove={onPointerMove}
        on:pointerup={onPointerUp}
        on:pointercancel={onPointerUp}
      >
        <div class="track" style="transform:translateX({trackX}px)">
          {#each ticks as t}
            <div class="tick" class:major={t.major}>
              {#if t.major}<span class="tl">{t.v}</span>{/if}
            </div>
          {/each}
        </div>
        <div class="needle"></div>
        <div class="fadeL"></div>
        <div class="fadeR"></div>
      </div>
      <p class="radar-hint" style="margin-top:6px">Zum Ändern nach links oder rechts ziehen</p>

      <div class="eyebrow" style="text-align:left;margin-top:20px">Wiederholungen pro Satz</div>
      {#each repsInputs as r, i (i)}
        <div class="plain-set">
          <span class="plain-idx">{i + 1}</span>
          <input class="pe-input small" type="number" min="0" value={r} on:input={(e) => (repsInputs[i] = e.currentTarget.value)} placeholder="Wdh.">
          <button class="pe-remove" on:click={() => removeSetRow(i)}>✕</button>
        </div>
      {/each}
      <button class="cta ghost" style="margin-top:10px" on:click={addSetRow}>+ Satz</button>
    </div>

    <button class="cta" style="margin-top:14px" on:click={save}>
      Speichern{#if idx < exercises.length - 1} → nächste Übung{/if}
    </button>

    {#if ex.history?.length}
      <div class="eyebrow" style="margin:20px 4px 8px">Verlauf</div>
      <div class="plain-ex">
        {#each ex.history as h}
          <div class="plain-set">
            <span class="progress-name">{h.weight > 0 ? fmt1(h.weight) + ' kg' : 'BW'}</span>
            <span class="plain-r">{h.reps.map(formatRep).join(' · ')}</span>
          </div>
        {/each}
      </div>
      <p class="radar-hint" style="text-align:left;margin-top:8px">X = weniger Gewicht verwendet · M = mehr Gewicht verwendet · ✓ = erledigt, ohne Wiederholungszahl</p>
    {/if}

    {#if onImportHistory}
      {#if !historyPasteOpen}
        <button class="cta ghost" style="margin-top:14px" on:click={() => (historyPasteOpen = true)}>+ Verlauf einfügen</button>
      {:else}
        <div class="card" style="margin-top:14px">
          <div class="eyebrow">Verlauf einfügen</div>
          <p class="radar-hint" style="text-align:left;margin-top:4px">Log-Text für diese Übung einfügen (z. B. "70kg x3 8.7.6 9.7.7") — wird genauso gelesen wie beim Log-Import.</p>
          <textarea class="pe-input import-textarea" rows="5" style="margin-top:8px" bind:value={historyPasteText}></textarea>
          <div style="display:flex;gap:8px;margin-top:8px">
            <button class="cta ghost" style="margin-top:0" on:click={() => { historyPasteOpen = false; historyPasteText = ''; }}>Abbrechen</button>
            <button class="cta" style="margin-top:0" on:click={applyHistoryPaste}>Übernehmen</button>
          </div>
        </div>
      {/if}
    {/if}
  </div>
</div>
{/if}
