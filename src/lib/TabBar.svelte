<script>
  import { activeScreen } from './stores.js';

  const tabs = [
    { id: 'training', label: 'Trainingsplan', path: 'M6 7v10M18 7v10M2 10v4M22 10v4M6 12h12' },
    { id: 'weight', label: 'Gewicht', path: 'M4 9v6M20 9v6M7 6v12M17 6v12M7 12h10' },
    { id: 'progress', label: 'Fortschritt', path: 'M5 21V11M12 21V4M19 21v-7' },
  ];
</script>

<nav class="tabbar">
  {#each tabs as t}
    <button class="tab" class:active={$activeScreen === t.id} on:click={() => activeScreen.set(t.id)}>
      <svg viewBox="0 0 24 24">
        <path d={t.path} />
      </svg>
      {t.label}
    </button>
  {/each}
</nav>
