<script>
  import { activeScreen, theme } from './lib/stores.js';
  import TabBar from './lib/TabBar.svelte';
  import Toast from './lib/Toast.svelte';
  import Training from './lib/Training.svelte';
  import Strength from './lib/Strength.svelte';
  import Progress from './lib/Progress.svelte';

  $: {
    document.documentElement.setAttribute('data-theme', $theme);
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', $theme === 'dark' ? '#101114' : '#f5f5f7');
  }
</script>

<div class="app-shell">
  <div class="screens">
    <section class="screen" class:active={$activeScreen === 'training'}>
      <Training />
    </section>
    <section class="screen" class:active={$activeScreen === 'strength'}>
      <Strength />
    </section>
    <section class="screen" class:active={$activeScreen === 'progress'}>
      <Progress />
    </section>
  </div>

  <TabBar />
  <Toast />
</div>
