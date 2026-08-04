<script>
  import { onMount } from 'svelte';
  import { programs, trainState } from './stores.js';
  import { todayIndexForProgram, fmt1, WEEKDAYS_SHORT } from './data.js';
  import { toast } from './toast.js';
  import PlanEditor from './PlanEditor.svelte';
  import ImportLog from './ImportLog.svelte';
  import WorkoutOverlay from './WorkoutOverlay.svelte';
  import ExerciseDetail from './ExerciseDetail.svelte';

  let showAllPlans = false;
  let planPromptOpen = false;
  let peOpen = false;
  let ilOpen = false;
  let woOpen = false;
  let edOpen = false;
  let edStartIdx = 0;

  onMount(() => {
    if ($programs.length > 1) planPromptOpen = true;
  });

  $: plan = $programs.find(p => p.id === $trainState.activePlanId) || $programs[0];
  $: todayIdx = plan ? todayIndexForProgram(plan) : 0;
  $: dayIdx = plan ? (plan.mode === 'weekday' ? $trainState.viewedDayIdx : (plan.currentDayIdx || 0)) : 0;
  $: day = plan ? plan.days[dayIdx] : null;
  $: exercises = day && !day.rest ? day.exercises : [];

  function selectPlan(id) {
    const p = $programs.find(p => p.id === id);
    trainState.set({ activePlanId: id, viewedDayIdx: todayIndexForProgram(p) });
    showAllPlans = false;
    planPromptOpen = false;
  }
  function selectPlanKey(id, e) {
    if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); selectPlan(id); }
  }

  function selectDay(i) {
    trainState.update(s => ({ ...s, viewedDayIdx: i }));
  }

  function openNewPlan() { showAllPlans = false; peOpen = true; }
  function openImport() { showAllPlans = false; ilOpen = true; }

  function adjustWeight(exIdx, setIdx, delta) {
    programs.update(all => {
      const p = all.find(p => p.id === $trainState.activePlanId);
      const ex = p.days[dayIdx].exercises[exIdx];
      ex.sets[setIdx].w = Math.max(0, Math.round((ex.sets[setIdx].w + delta) * 2) / 2);
      return all;
    });
  }

  function toggleSet(exIdx, setIdx) {
    programs.update(all => {
      const p = all.find(p => p.id === $trainState.activePlanId);
      const ex = p.days[dayIdx].exercises[exIdx];
      if (!ex.done.includes(setIdx)) ex.done = [...ex.done, setIdx];
      return all;
    });
  }

  function openExerciseDetail(exIdx) { edStartIdx = exIdx; edOpen = true; }

  function saveExerciseLog(exIdx, weight, reps) {
    programs.update(all => {
      const p = all.find(p => p.id === $trainState.activePlanId);
      const ex = p.days[dayIdx].exercises[exIdx];
      ex.history = [...(ex.history || []), { weight, reps }];
      ex.sets = ex.sets.map(s => ({ ...s, w: weight }));
      return all;
    });
  }

  function finishWorkout() {
    programs.update(all => {
      const p = all.find(p => p.id === $trainState.activePlanId);
      p.completed = (p.completed || 0) + 1;
      return all;
    });
    woOpen = false;
    toast('Workout abgeschlossen 💪');
  }
</script>

<div class="apphead">
  <div>
    <h1>{plan ? plan.name : 'Training'}</h1>
    <div class="sub">
      {#if plan}{day.rest ? 'Ruhetag' : day.label} · {plan.completed || 0} Workouts{/if}
    </div>
  </div>
  <button class="allbtn" on:click={() => (showAllPlans = true)}>Alle Pläne</button>
</div>

{#if plan && plan.mode === 'weekday'}
  <div class="dayrow">
    {#each WEEKDAYS_SHORT as d, i}
      <button class="daypill" class:today={i === todayIdx} class:sel={i === dayIdx} on:click={() => selectDay(i)}>{d}</button>
    {/each}
  </div>
{/if}

{#if !plan}
  <div class="card" style="text-align:center;padding:32px 20px">
    <p class="plain-rest" style="margin-bottom:16px">Noch kein Trainingsplan angelegt.</p>
    <button class="cta" on:click={openNewPlan}>+ Neuer Plan</button>
    <button class="cta ghost" style="margin-top:10px" on:click={openImport}>📄 Log importieren</button>
  </div>
{:else if day.rest}
  <p class="plain-rest">Heute ist Ruhetag.<br>Kein Training eingetragen.</p>
{:else}
  {#if exercises.length}
    <button class="cta" style="margin-bottom:14px" on:click={() => (woOpen = true)}>
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 7v10M18 7v10M2 10v4M22 10v4M6 12h12"/></svg>
      Workout starten
    </button>
  {/if}
  {#each exercises as ex, exIdx}
    <div class="plain-ex">
      <div
        class="plain-ex-name"
        role="button"
        tabindex="0"
        on:click={() => openExerciseDetail(exIdx)}
        on:keydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openExerciseDetail(exIdx); } }}
      >{ex.name}</div>
      <div class="plain-setlist">
        {#each ex.sets as s, setIdx}
          <div class="plain-set">
            <span class="plain-idx">{setIdx + 1}</span>
            <button class="plain-step" on:click={() => adjustWeight(exIdx, setIdx, -2.5)}>−</button>
            <span class="plain-w">{s.w > 0 ? fmt1(s.w) + ' kg' : 'BW'}</span>
            <button class="plain-step" on:click={() => adjustWeight(exIdx, setIdx, 2.5)}>+</button>
            <span class="plain-r">× {s.r}</span>
          </div>
        {/each}
      </div>
    </div>
  {/each}
{/if}

{#if planPromptOpen}
  <div class="overlay open">
    <div class="ov-top">
      <span style="width:40px"></span>
      <div style="font-family:'Sora';font-weight:700;font-size:15px">Trainingsplan wählen</div>
      <button class="iconbtn" on:click={() => (planPromptOpen = false)}>✕</button>
    </div>
    <div class="pe-scroll">
      <p class="radar-hint" style="text-align:left;margin-bottom:12px">Welchen Trainingsplan möchtest du heute nutzen?</p>
      {#each $programs as p}
        <div
          class="plan-row-item"
          class:sel={p.id === $trainState.activePlanId}
          role="button"
          tabindex="0"
          on:click={() => selectPlan(p.id)}
          on:keydown={(e) => selectPlanKey(p.id, e)}
        >
          <span>{p.name}</span>
          {#if p.id === $trainState.activePlanId}<span>✓</span>{/if}
        </div>
      {/each}
    </div>
  </div>
{/if}

{#if showAllPlans}
  <div class="overlay open">
    <div class="ov-top">
      <button class="iconbtn" on:click={() => (showAllPlans = false)}>✕</button>
      <div style="font-family:'Sora';font-weight:700;font-size:15px">Alle Trainingspläne</div>
      <span style="width:40px"></span>
    </div>
    <div class="pe-scroll">
      {#each $programs as p}
        <div
          class="plan-row-item"
          class:sel={p.id === $trainState.activePlanId}
          role="button"
          tabindex="0"
          on:click={() => selectPlan(p.id)}
          on:keydown={(e) => selectPlanKey(p.id, e)}
        >
          <span>{p.name}</span>
          {#if p.id === $trainState.activePlanId}<span>✓</span>{/if}
        </div>
      {/each}
      <button class="cta ghost" style="margin-top:14px" on:click={openNewPlan}>+ Neuer Plan</button>
      <button class="cta ghost" style="margin-top:10px" on:click={openImport}>📄 Log importieren</button>
    </div>
  </div>
{/if}

{#if woOpen && plan}
  <WorkoutOverlay
    exercises={exercises}
    onAdjust={adjustWeight}
    onToggle={toggleSet}
    on:finish={finishWorkout}
    on:close={() => (woOpen = false)}
  />
{/if}

{#if edOpen && plan}
  <ExerciseDetail
    exercises={exercises}
    startIdx={edStartIdx}
    onSave={saveExerciseLog}
    on:close={() => (edOpen = false)}
  />
{/if}

<PlanEditor bind:open={peOpen} />
<ImportLog bind:open={ilOpen} />
