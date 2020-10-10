<script lang="ts">
    import {List, ListItem} from 'smelte';

    const icon = "arrow_forward";
    const menu: ListItem[] = [
        {icon, to: "/demos/filt/ema", text: "EMA filter", subheading: "Exponential Moving Average"},
        {icon, to: "/demos/filt/lqe", text: "LQE filter", subheading: "Linear Quadratic Estimation (Kalman)"},
    ];
</script>

<svelte:head>
    <title>uctl-d web demos</title>
</svelte:head>

<h2>Demos</h2>

<List items={menu} />
