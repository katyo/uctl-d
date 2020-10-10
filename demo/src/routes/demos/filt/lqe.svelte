<script lang="ts">
    import { onMount } from 'svelte';
    import {List} from 'smelte';
    import Demo from '../../../demos/filt/lqe.svelte';
    import type {Exports} from '../../../modules/filt/lqe';
    import loader from '../../../modules/filt/lqe';

    let exports: Exports;

    onMount(async () => {
        exports = await loader({});
    });
</script>

<svelte:head>
    <title>LQE filter demo</title>
</svelte:head>

<List items={[{icon: 'arrow_backward', to: '/demos', text: 'Back to demos'}]} />
<h3>LQE filter demo</h3>

Linear-Quadratic Estimation also known as Kalman filter.

{#if exports}
    {#await exports}
        <p>Loading module</p>
    {:then exports}
        <Demo {exports} />
    {/await}
{:else}
		<p>Starting app</p>
{/if}
