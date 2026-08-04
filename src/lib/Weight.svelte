<script>
  import { onMount } from 'svelte';
  import { weightData, GOAL_WEIGHT } from './stores.js';
  import { toast } from './toast.js';

  const MIN = 60.0, MAX = 120.0, PX_PER_UNIT = 40; // 40px per 1.0 kg (10px per 0.1kg tick)

  $: last = $weightData[$weightData.length - 1];
  $: prev = $weightData[$weightData.length - 2];
  $: delta = prev ? Math.round((last.v - prev.v) * 10) / 10 : 0;

  let value = 83.0;
  let containerWidth = 320;
  let rulerEl;
  let dragging = false;
  let startX = 0;
  let startValue = 0;

  onMount(() => {
    value = last?.v ?? 83.0;
    containerWidth = rulerEl?.clientWidth || 320;
    const ro = new ResizeObserver(() => (containerWidth = rulerEl.clientWidth));
    ro.observe(rulerEl);
    return () => ro.disconnect();
  });

  $: ticks = Array.from({ length: Math.round((MAX - MIN) * 10) + 1 }, (_, i) => {
    const v = Math.round((MIN + i * 0.1) * 10) / 10;
    return { v, major: Math.round(v * 10) % 10 === 0 };
  });
  $: trackX = containerWidth / 2 - (value - MIN) * PX_PER_UNIT;

  function onPointerDown(e) {
    dragging = true;
    startX = e.clientX;
    startValue = value;
    rulerEl.setPointerCapture(e.pointerId);
  }
  function onPointerMove(e) {
    if (!dragging) return;
    const dx = e.clientX - startX;
    let v = startValue - dx / PX_PER_UNIT;
    value = Math.min(MAX, Math.max(MIN, Math.round(v * 10) / 10));
  }
  function onPointerUp() { dragging = false; }

  function saveWeight() {
    const today = new Date();
    const label = `${today.getDate()}.${today.getMonth() + 1}`;
    weightData.update(list => [...list, { l: label, v: value }]);
    toast('Gewicht gespeichert ✅');
  }

  $: chartPoints = $weightData.slice(-8);
  $: chartVals = chartPoints.map(p => p.v);
  $: chartMin = (chartVals.length ? Math.min(GOAL_WEIGHT, ...chartVals) : GOAL_WEIGHT) - 0.6;
  $: chartMax = (chartVals.length ? Math.max(...chartVals) : GOAL_WEIGHT) + 0.6;
  $: chartPath = chartPoints.map((p, i) => {
    const x = chartPoints.length > 1 ? (i / (chartPoints.length - 1)) * 100 : 50;
    const y = 100 - ((p.v - chartMin) / (chartMax - chartMin)) * 100;
    return `${x},${y}`;
  }).join(' ');
  $: goalY = 100 - ((GOAL_WEIGHT - chartMin) / (chartMax - chartMin)) * 100;
</script>

<div class="apphead">
  <div><h1>Gewicht</h1><div class="sub">Ziel: {GOAL_WEIGHT.toFixed(1)} kg</div></div>
</div>

<div class="card bigweight">
  <div class="v">{value.toFixed(1)}<span> kg</span></div>
  {#if prev}
    <div class="delta" class:up={delta > 0}>{delta > 0 ? '▲' : delta < 0 ? '▼' : '–'} {Math.abs(delta).toFixed(1)} kg seit letztem Eintrag</div>
  {/if}

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
          {#if t.major}<span class="tl">{t.v.toFixed(0)}</span>{/if}
        </div>
      {/each}
    </div>
    <div class="needle"></div>
    <div class="fadeL"></div>
    <div class="fadeR"></div>
  </div>

  <button class="cta" style="margin-top:16px" on:click={saveWeight}>Gewicht speichern</button>
</div>

<div class="card chartcard">
  <h2>Verlauf</h2>
  {#if chartPoints.length}
    <svg class="chart" viewBox="0 0 100 100" preserveAspectRatio="none">
      <line x1="0" y1={goalY} x2="100" y2={goalY} stroke="var(--teal)" stroke-width="0.6" stroke-dasharray="2,2" />
      <polyline points={chartPath} fill="none" stroke="var(--accent)" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
      {#each chartPoints as p, i}
        {@const x = chartPoints.length > 1 ? (i / (chartPoints.length - 1)) * 100 : 50}
        {@const y = 100 - ((p.v - chartMin) / (chartMax - chartMin)) * 100}
        <circle cx={x} cy={y} r="1.6" fill="var(--accent)" />
      {/each}
    </svg>
    <div class="legend">
      <span><i style="background:var(--accent)"></i>Gewicht</span>
      <span><i style="background:var(--teal)"></i>Ziel {GOAL_WEIGHT.toFixed(1)} kg</span>
    </div>
  {:else}
    <p class="plain-rest">Noch keine Einträge — speichere dein erstes Gewicht oben.</p>
  {/if}
</div>
