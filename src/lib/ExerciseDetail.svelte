<script>
  import { onMount, createEventDispatcher } from 'svelte';
  import { fmt1 } from './data.js';

  export let exercises = [];
  export let startIdx = 0;
  export let onSave; // (exIdx, weight, reps[]) => void

  const dispatch = createEventDispatcher();

  let idx = startIdx;
  let weightInput = 0;
  let repsInputs = [];

  function loadExercise(i) {
    idx = i;
    const e = exercises[i];
    weightInput = e.sets[e.sets.length - 1]?.w ?? e.startW ?? 0;
    repsInputs = e.sets.map(() => '');
  }
  onMount(() => loadExercise(startIdx));

  $: ex = exercises[idx];

  function step(delta) {
    weightInput = Math.max(0, Math.round((weightInput + delta) * 2) / 2);
  }
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
    <div style="font-family:'Sora';font-weight:700;font-size:15px">{ex.name}</div>
    <span style="width:40px"></span>
  </div>

  <div class="pe-scroll">
    <div class="card" style="text-align:center">
      <div class="eyebrow">Aktuell</div>
      <div style="font-family:'Sora';font-weight:800;font-size:32px;margin:4px 0 18px">
        {fmt1(weightInput)}<span style="font-size:16px;font-weight:600"> kg</span>
      </div>

      <div class="eyebrow" style="text-align:left">Gewicht heute</div>
      <div class="weight-adjust" style="margin:8px 0 4px">
        <button class="stepbtn" on:click={() => step(-2.5)}>−</button>
        <div class="wv">{fmt1(weightInput)} <span>kg</span></div>
        <button class="stepbtn" on:click={() => step(2.5)}>+</button>
      </div>

      <div class="eyebrow" style="text-align:left;margin-top:14px">Wiederholungen pro Satz</div>
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
            <span class="plain-r">{h.reps.map(formatRep).join('.')}</span>
          </div>
        {/each}
      </div>
      <p class="radar-hint" style="text-align:left;margin-top:8px">X = weniger Gewicht verwendet · M = mehr Gewicht verwendet</p>
    {/if}
  </div>
</div>
{/if}
