<script>
  import { activeScreen } from './lib/stores.js';
  import TabBar from './lib/TabBar.svelte';
  import Toast from './lib/Toast.svelte';
  import Training from './lib/Training.svelte';
  import Weight from './lib/Weight.svelte';
  import Progress from './lib/Progress.svelte';
</script>

<div class="app-shell">
  <div class="screens">
    <section class="screen" class:active={$activeScreen === 'training'}>
      <Training />
    </section>
    <section class="screen" class:active={$activeScreen === 'weight'}>
      <Weight />
    </section>
    <section class="screen" class:active={$activeScreen === 'progress'}>
      <Progress />
    </section>
  </div>

  <TabBar />
  <Toast />
</div>
