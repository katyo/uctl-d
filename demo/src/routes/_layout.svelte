<script lang="ts">
    import {fade} from 'svelte/transition';
    import {stores} from '@sapper/app';
    import GlobalStyle from '../components/GlobalStyle.svelte';
    import Nav from '../components/Nav.svelte';

    const {page} = stores();

    $: main_classes = $page.path.search('/demos/') == 0 ? "lg:max-w-3xl md:ml-32 md:pl-16" : "md:ml-64 md:pl-16 md:max-w-md lg:max-w-3xl";
</script>

<GlobalStyle/>

<Nav/>

<main
    class="relative p-8 mx-auto mb-10 mt-24 md:px-3 ${main_classes}"
    transition:fade={{ duration: 300 }}>
	<slot></slot>
</main>
