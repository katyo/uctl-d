<script lang="ts">
    import {Switch, Slider, DataTable} from 'smelte';
    import type {Data} from '../../components/Plot.svelte';
    import Plot from '../../components/Plot.svelte';
    import {spectrum} from '../../utils';
    import {generator} from '../../wavegen';
    import type {Exports} from '../../modules/filt/ema';

    export let exports: Exports;

    const time_window_min = 0.01;
    const time_window_max = 10.0;
    const time_window_step = 0.01;

    const tend = 3.0;

    const dt = exports.get_timing();
    const Fs = 1.0 / dt;
    const spectrum_step = 1.0 / tend;
    const data_length = Math.floor(tend / dt);

    let time_window = 1.0;
    let fixed_point = false;

    let spectrum_start = 0;
    let spectrum_end = 50;
    let spectrum_dbm = false;

    let show_table = false;

    const gen_data = generator([
        {gain: 0.15, kind: 'rand'},
        {gain: 0.20, kind: 'sine', frequency: 2.0},
        {gain: 0.15, kind: 'sine', frequency: 3.5},
        {gain: 0.4, kind: 'sine', frequency: 0.16, delay: 0.1},
    ], {bias: 1.0});

    const get_spectrum = (data: Data) =>
          spectrum(data.points.map(p => p[1]), Fs);

    interface Column {
        label: string;
        value: (index: number) => string;
    }

    const labels = ['Time, S', 'Input', 'Output'];
    const indices = new Array(data_length);
    const datas: Data[] = [
        { points: new Array(data_length), label: labels[1] },
        { points: new Array(data_length), label: labels[2] },
    ];
    const spectrums: Data[] = [
        { points: [], label: labels[1] },
        { points: [], label: labels[2] },
    ];
    const columns: Column[] = [
        {label: labels[0], value: i => datas[0].points[i][0].toFixed(6) },
        {label: labels[1], value: i => datas[0].points[i][1].toFixed(6) },
        {label: labels[2], value: i => datas[1].points[i][1].toFixed(6) },
    ];

    for (let i = 0; i < data_length; i++) {
				let t = i * dt;
				let v = gen_data(t);
        indices[i] = i;
        datas[0].points[i] = [t, v];
        datas[1].points[i] = [t, 0];
		}
    spectrums[0].points = get_spectrum(datas[0]);

    $: {
        const fname = (name: string) => `${fixed_point ? 'x' : 'f'}_${name}`;

        const set_window: (time: number) => void = exports[fname('set_window')];
        const reset: (value: number) => void = exports[fname('reset')];
        const apply: (value: number) => number = exports[fname('apply')];

        set_window(time_window);
		    reset(datas[0].points[0][1]);
        for (let i = 0; i < data_length; i++) {
            datas[1].points[i][1] = apply(datas[0].points[i][1]);
        }
        spectrums[1].points = get_spectrum(datas[1]);
    }
</script>

<div class="flex flex-wrap">
    <div class="w-full md:w-1/2 lg:w-3/4 xl:w-5/6">
        <div class="flex mt-4 mb-6">
            <div class="flex-1 px-3">
                <Slider bind:value={time_window} min={time_window_min} max={time_window_max} step={time_window_step} label="Time window, {time_window} S" />
            </div>
            <div class="flex-1 px-3">
                <Switch bind:value={fixed_point} label="Fixed-point (-10000..10000)" />
            </div>
        </div>
        <h5>Signal before and after filter</h5>
        <Plot {datas}/>
        <h5>Signal spectrum</h5>
        <Plot datas={spectrums} x1={spectrum_start} x2={spectrum_end} ydb={spectrum_dbm} />
        <div class="flex mt-2 mb-6">
            <div class="flex-1 px-3">
                <Slider bind:value={spectrum_start} min={spectrums[0].points[0][0]} max={spectrum_end - spectrum_step} step={spectrum_step} label="Spectrum start {spectrum_start.toFixed(3)}" />
            </div>
            <div class="flex-1 px-3">
                <Slider bind:value={spectrum_end} min={spectrum_start + spectrum_step} max={spectrums[0].points[spectrums[0].points.length - 1][0]} step={spectrum_step} label="Spectrum end {spectrum_end.toFixed(3)}" />
            </div>
            <div class="flex-1 px-3">
                <Switch bind:value={spectrum_dbm} label="Spectrum in db" />
            </div>
        </div>
    </div>
    <div class="w-full md:w-1/2 lg:w-1/4 xl:w-1/6">
        <Switch bind:value={show_table} label="Show data table" />
        {#if show_table}
            <DataTable data={indices} {columns} />
        {/if}
    </div>
</div>
