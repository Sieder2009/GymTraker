<script>
  export let labels = [];
  export let values = []; // 0-100, same length as labels

  const SIZE = 260;
  const CX = SIZE / 2, CY = SIZE / 2, R = 92;
  const rings = [0.25, 0.5, 0.75, 1];

  $: n = labels.length;
  $: angle = (i) => -Math.PI / 2 + (i * 2 * Math.PI) / n;
  $: pt = (i, frac) => [CX + Math.cos(angle(i)) * R * frac, CY + Math.sin(angle(i)) * R * frac];

  $: gridPolys = rings.map(f => labels.map((_, i) => pt(i, f).join(',')).join(' '));
  $: axisLines = labels.map((_, i) => pt(i, 1));
  $: valuePoly = labels.map((_, i) => pt(i, Math.max(0.04, (values[i] || 0) / 100)).join(',')).join(' ');
  $: labelPos = labels.map((_, i) => pt(i, 1.28));
</script>

<svg width={SIZE} height={SIZE} viewBox="0 0 {SIZE} {SIZE}">
  {#each gridPolys as poly}
    <polygon points={poly} fill="none" stroke="var(--line)" stroke-width="1" />
  {/each}
  {#each axisLines as [x, y]}
    <line x1={CX} y1={CY} x2={x} y2={y} stroke="var(--line)" stroke-width="1" />
  {/each}

  <polygon points={valuePoly} fill="var(--accent)" fill-opacity="0.22" stroke="var(--accent)" stroke-width="2" stroke-linejoin="round" />
  {#each labels as _, i}
    {@const [x, y] = pt(i, Math.max(0.04, (values[i] || 0) / 100))}
    <circle cx={x} cy={y} r="3" fill="var(--accent)" />
  {/each}

  {#each labels as l, i}
    {@const [x, y] = labelPos[i]}
    <text {x} {y} text-anchor="middle" dominant-baseline="middle" class="radar-label">{l}</text>
  {/each}
</svg>

<style>
  .radar-label{ font-family:'Sora', sans-serif; font-size:11px; font-weight:700; fill:var(--mut); }
</style>
