<script lang="ts">
    import {AppBar, Tabs, Spacer, ProgressLinear, Button, Tooltip} from 'smelte';
    import {stores} from '@sapper/app';
    import dark from 'smelte/src/dark';
    import {showNav} from '../stores';

    const { preloading, page } = stores();
    const darkMode = dark();

    $: path = $page.path;

    interface Item {
        to: string;
        text: string;
    }

    const menu: Item[] = [
        { to: '/', text: 'Home' },
        { to: '/demos', text: 'Demos' },
        { to: 'https://katyo.github.io/uctl-d', text: 'Documentation' },
    ];
</script>

{#if $preloading}
  <ProgressLinear app />
{/if}

<AppBar>
    <a href="." class="px-2 md:px-8 flex items-center">
        <img src="/microchip.svg" alt="logo" width="44" />
        <h6 class="pl-3 text-white tracking-widest font-thin text-lg">UCTL-D</h6>
    </a>
    <Spacer />
    <Tabs navigation items={menu} bind:selected={path} />
    <Tooltip>
        <span slot="activator">
            <Button
                bind:value={$darkMode}
                icon="wb_sunny"
                small
                flat
                remove="p-1 h-4 w-4"
                iconClass="text-white"
                text />
        </span>
        {$darkMode ? 'Light' : 'Dark'}
    </Tooltip>
    <div class="md:hidden">
        <Button
            icon="menu"
            small
            flat
            remove="p-1 h-4 w-4"
            iconClass="text-white"
            text
            on:click={() => showNav.set(!$showNav)} />
    </div>
    <a href="https://github.com/katyo/uctl-d" class="px-4">
        <img src="/github.png" alt="Github" width="24" height="24" />
    </a>
</AppBar>
