<script>
  import { toastMsg, toastShown } from './toast.js';
</script>

<div class="toast" class:shown={$toastShown} style="transform:translateX(-50%) translateY({$toastShown ? '-20px' : '0'})">
  {$toastMsg}
</div>

<style>
  .toast{ opacity:0; transition:opacity .3s ease, transform .3s ease; }
  .toast.shown{ opacity:1; }
</style>
