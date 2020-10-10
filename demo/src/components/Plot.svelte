<script context="module" lang="ts">
    export const enum Style {
        Line = 1,
        Dot = 2,
    }

    export type Point = [number, number];

    export interface Data {
        points: Point[];
        style?: Style;
        label?: string;
    }
</script>

<script lang="ts">
    import { Chart, Box, Grid, Svg, SvgLine } from '@sveltejs/pancake';
    import {to_db, from_db} from '../utils';

    export let datas: Data[];

    export let x1: number | undefined = undefined;
    export let x2: number | undefined = undefined;
    export let y1: number | undefined = undefined;
    export let y2: number | undefined = undefined;

    export let xt: number | undefined = undefined;
    export let yt: number | undefined = undefined;

    export let xdb = false;
    export let ydb = false;

    const is = (v: number | undefined) => v !== undefined;
    const min = (a: number, b: number) => Math.min(a, b);
    const max = (a: number, b: number) => Math.max(a, b);
    const tolabel = (v: number) => {
        let s = `${v}`;
        if (s.length > 7) {
            s = `${v.toFixed(4)}`;
        }
        if (s.length > 7) {
            s = `${v.toExponential(1)}`;
        }
        return s;
    };

    $: xlabel = (x: number) => tolabel(xdb ? from_db(x) : x);
    $: ylabel = (y: number) => tolabel(ydb ? from_db(y) : y);

    $: xof = (p: Point) => xdb ? to_db(p[0]) : p[0];
    $: yof = (p: Point) => ydb ? to_db(p[1]) : p[1];

    $: xin = (p: Point) => (!is(x1) || xof(p) >= x1) && (!is(x2) || xof(p) <= x2);
    $: yin = (p: Point) => (!is(y1) || yof(p) >= y1) && (!is(y2) || yof(p) <= y2);

    $: pin = (p: Point) => xin(p) && yin(p);

    $: _x1 = is(x1) ? x1 : datas
    .map(({points}) => points.filter(pin).map(xof).reduce(min)).reduce(min);
    $: _x2 = is(x2) ? x2 : datas
    .map(({points}) => points.filter(pin).map(xof).reduce(max)).reduce(max);
    $: _y1 = is(y1) ? y1 : datas
    .map(({points}) => points.filter(pin).map(yof).reduce(min)).reduce(min);
    $: _y2 = is(y2) ? y2 : datas
    .map(({points}) => points.filter(pin).map(yof).reduce(max)).reduce(max);
</script>

<div class="chart">
    <Chart x1={_x1} x2={_x2} y1={_y1} y2={_y2}>
        <Box x1={_x1} x2={_x2} y1={_y1} y2={_y2}>
            <div class="axes"></div>
        </Box>

        <Grid vertical count={yt} let:value>
            <span class="x label">{xlabel(value)}</span>
        </Grid>

        <Grid horizontal count={xt} let:value>
            <span class="y label">{ylabel(value)}</span>
        </Grid>

        <Svg clip>
            {#each datas as {points}, i}
                <SvgLine data={points.filter(pin)} x={xof} y={yof} let:d>
                    <path class="data data-{i}" {d}/>
                </SvgLine>
            {/each}
        </Svg>
    </Chart>
</div>

<style>
    .chart {
        height: 300px;
        padding: 3em 2em 2em 3em;
        box-sizing: border-box;
    }

    .axes {
        width: 100%;
        height: 100%;
        border: 1px solid gray;
    }

    .y.label {
        position: absolute;
        left: -3.5em;
        width: 3em;
        text-align: right;
        bottom: -0.5em;
    }

    .x.label {
        position: absolute;
        width: 4em;
        left: -2em;
        bottom: -22px;
        font-family: sans-serif;
        text-align: center;
    }

    path.data {
        stroke-linejoin: round;
        stroke-linecap: round;
        stroke-width: 1.2px;
        fill: none;
    }

    path.data-0 {
        stroke: #ed6f68;
    }

    path.data-1 {
        stroke: #31ab97;
    }

    path.data-2 {
        stroke: #517bbe;
    }
</style>
