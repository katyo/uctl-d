<script lang="ts">
    import { onMount } from 'svelte';
    import {List} from 'smelte';
    import Demo from '../../../demos/filt/ema.svelte';
    import type {Exports} from '../../../modules/filt/ema';
    import loader from '../../../modules/filt/ema';

    let exports: Exports;

    onMount(async () => {
        exports = await loader({});
    });
</script>

<svelte:head>
    <title>EMA filter demo</title>
</svelte:head>

<List items={[{icon: 'arrow_backward', to: '/demos', text: 'Back to demos'}]} />
<h3>EMA filter demo</h3>

Exponential Moving Average filter pretty simple and efficient low-pass filter.

{#if exports}
    {#await exports}
        <p>Loading module</p>
    {:then exports}
        <Demo {exports} />
    {/await}
{:else}
		<p>Starting app</p>
{/if}
