<script>
  import { createEventDispatcher, onDestroy } from 'svelte';
  import { fmt1 } from './data.js';

  export let exercises = [];
  export let onAdjust;
  export let onToggle;

  const dispatch = createEventDispatcher();

  let exIdx = 0;
  let setIdx = 0;
  let resting = false;
  let restLeft = 0;
  let restTotal = 0;
  let rpe = null;
  let timer;
  let localWeight = 0;

  $: ex = exercises[exIdx];
  $: if (ex) localWeight = ex.sets[setIdx].w;
  $: totalSets = exercises.reduce((s, e) => s + e.sets.length, 0) || 1;
  $: doneBefore = exercises.slice(0, exIdx).reduce((s, e) => s + e.sets.length, 0) + setIdx;
  $: progressPct = Math.round((100 * doneBefore) / totalSets);
  $: isLast = exIdx === exercises.length - 1 && setIdx === ex?.sets.length - 1;

  function step(delta) {
    localWeight = Math.max(0, Math.round((localWeight + delta) * 2) / 2);
    onAdjust(exIdx, setIdx, delta);
  }

  function completeSet() {
    onToggle(exIdx, setIdx);
    if (isLast) {
      dispatch('finish');
      return;
    }
    restTotal = ex.rest;
    restLeft = ex.rest;
    resting = true;
    clearInterval(timer);
    timer = setInterval(() => {
      restLeft -= 1;
      if (restLeft <= 0) advance();
    }, 1000);
  }

  function advance() {
    clearInterval(timer);
    resting = false;
    rpe = null;
    if (setIdx < ex.sets.length - 1) {
      setIdx += 1;
    } else {
      exIdx += 1;
      setIdx = 0;
    }
  }

  function skipRest() {
    advance();
  }

  onDestroy(() => clearInterval(timer));

  const C = 2 * Math.PI * 110;
</script>

<div class="overlay open">
  <div class="ov-top">
    <button class="iconbtn" on:click={() => dispatch('close')}>✕</button>
    <div class="ov-progress"><i style="width:{progressPct}%"></i></div>
    <button class="iconbtn" on:click={() => dispatch('close')}>⏸</button>
  </div>

  {#if ex}
    <div class="ov-ex">
      <div class="which">Übung {exIdx + 1} / {exercises.length} · Satz {setIdx + 1} / {ex.sets.length}</div>
      <h1>{ex.name}</h1>
    </div>

    <div class="weight-adjust">
      <button class="stepbtn" on:click={() => step(-2.5)}>−</button>
      <div class="wv">{fmt1(localWeight)} <span>kg</span></div>
      <button class="stepbtn" on:click={() => step(2.5)}>+</button>
    </div>
    <p class="muted" style="text-align:center;font-size:13px">Ziel: {ex.sets[setIdx].r} Wiederholungen</p>

    <div class="ov-sets">
      {#each ex.sets as s, i}
        <div class="ov-set-dot" class:cur={i === setIdx} class:ok={ex.done.includes(i)}>{i + 1}</div>
      {/each}
    </div>

    <div class="rpe">
      {#each Array(6) as _, i}
        <button class:sel={rpe === i + 5} on:click={() => (rpe = i + 5)}>{i + 5}</button>
      {/each}
    </div>

    <div class="ov-bottom">
      <button class="cta" on:click={completeSet}>{isLast ? 'Workout beenden' : 'Satz abschließen'}</button>
    </div>
  {/if}
</div>

{#if resting}
  <div class="rest">
    <div class="big">
      <svg width="240" height="240" viewBox="0 0 240 240">
        <circle cx="120" cy="120" r="110" stroke="#1f1f26" stroke-width="10" fill="none"/>
        <circle cx="120" cy="120" r="110" stroke="var(--accent)" stroke-width="10" fill="none" stroke-linecap="round"
          stroke-dasharray={C} stroke-dashoffset={C * (1 - restLeft / restTotal)}
          style="transform:rotate(-90deg);transform-origin:120px 120px;transition:stroke-dashoffset 1s linear" />
      </svg>
      <div class="tv"><div class="t">{restLeft}</div><div class="l">Sekunden Pause</div></div>
    </div>
    <button class="cta ghost" style="width:auto;padding:12px 30px" on:click={skipRest}>Überspringen →</button>
  </div>
{/if}
