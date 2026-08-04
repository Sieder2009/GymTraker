<script>
  import { programs, trainState } from './stores.js';
  import { fmt1, RADAR_CATEGORIES, muscleCategory } from './data.js';
  import RadarChart from './RadarChart.svelte';

  $: plan = $programs.find(p => p.id === $trainState.activePlanId) || $programs[0];

  $: allEx = plan ? plan.days.flatMap(d => d.exercises || []) : [];

  $: rows = allEx
    .filter(ex => ex.sets && ex.sets.length && ex.sets.some(s => s.w > 0))
    .map(ex => {
      const now = ex.sets.reduce((m, s) => Math.max(m, s.w), 0);
      const start = ex.startW ?? now;
      return { name: ex.name, start, now, delta: Math.round((now - start) * 10) / 10 };
    });

  $: catSums = RADAR_CATEGORIES.map(cat =>
    allEx.reduce((sum, ex) => {
      if (muscleCategory(ex.muscle) !== cat) return sum;
      const now = ex.sets.reduce((m, s) => Math.max(m, s.w), 0);
      return sum + now;
    }, 0)
  );
  $: maxCat = Math.max(1, ...catSums);
  $: radarValues = catSums.map(v => Math.round((v / maxCat) * 100));
</script>

<div class="apphead">
  <div>
    <h1>Fortschritt</h1>
    <div class="sub">{plan ? plan.name : ''}</div>
  </div>
</div>

<div class="radar-card">
  <h2>Muskelgruppen-Balance</h2>
  <div class="radar-wrap">
    <RadarChart labels={RADAR_CATEGORIES} values={radarValues} />
  </div>
  <p class="radar-hint">Relative Kraft je Muskelgruppe, bezogen auf deine stärkste Kategorie im aktuellen Plan.</p>
</div>

<h2 class="section-title">Start → Jetzt</h2>
{#if rows.length}
  <div class="plain-ex" style="padding-top:4px">
    {#each rows as r, i}
      <div class="plain-set" style={i === rows.length - 1 ? 'border-bottom:none' : ''}>
        <span class="progress-name">{r.name}</span>
        <span class="progress-vals">
          {fmt1(r.start)}<span class="arrow">→</span>{fmt1(r.now)} kg
        </span>
        {#if r.delta !== 0}
          <span class="d" class:up={r.delta > 0} class:down={r.delta < 0}>
            {r.delta > 0 ? '+' : ''}{fmt1(r.delta)}
          </span>
        {/if}
      </div>
    {/each}
  </div>
{:else}
  <p class="plain-rest">Noch keine Übungen mit Gewicht erfasst.</p>
{/if}
