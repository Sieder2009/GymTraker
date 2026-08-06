<script>
  import { programs, trainState } from './stores.js';
  import { fmt1 } from './data.js';
  import RadarChart from './RadarChart.svelte';
  import ThemeToggle from './ThemeToggle.svelte';

  $: plan = $programs.find(p => p.id === $trainState.activePlanId) || $programs[0];

  $: allEx = plan ? plan.days.flatMap(d => d.exercises || []) : [];

  // matches only the main lift itself (incl. grip/stance variants like
  // "Bankdrücken (eng)"), not accessory lifts like "Hack Squat" or
  // "Bulgarian Split Squats" that merely contain the word
  const BIG_THREE = /^(bench\s*press|bankdrücken|deadlift|kreuzheben|squats?)\b/i;
  const LIFT_CATEGORIES = [
    { label: 'Deadlift', re: /^(deadlift|kreuzheben)\b/i },
    { label: 'Bench Press', re: /^(bench\s*press|bankdrücken)\b/i },
    { label: 'Squat', re: /^squats?\b/i },
  ];

  $: rows = allEx
    .filter(ex => ex.sets && ex.sets.length && ex.sets.some(s => s.w > 0) && BIG_THREE.test(ex.name))
    .map(ex => {
      const now = ex.sets.reduce((m, s) => Math.max(m, s.w), 0);
      const start = ex.startW ?? now;
      return { name: ex.name, start, now, delta: Math.round((now - start) * 10) / 10 };
    });

  $: catSums = LIFT_CATEGORIES.map(cat =>
    allEx.reduce((best, ex) => {
      if (!cat.re.test(ex.name)) return best;
      const now = ex.sets.reduce((m, s) => Math.max(m, s.w), 0);
      return Math.max(best, now);
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
  <ThemeToggle />
</div>

<div class="radar-card">
  <h2>Kraft-Balance</h2>
  <div class="radar-wrap">
    <RadarChart labels={LIFT_CATEGORIES.map((c) => c.label)} values={radarValues} />
  </div>
  <p class="radar-hint">Deadlift, Bench Press und Squat, bezogen auf deine stärkste der drei Übungen im aktuellen Plan.</p>
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
