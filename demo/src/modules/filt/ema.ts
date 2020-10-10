import wasm from './ema.wasm';

export interface Imports {}

export interface Exports {
    get_timing(): number;

    f_set_window(time: number);
    f_reset(value: number);
    f_apply(value: number): number;

    x_set_window(time: number);
    x_reset(value: number);
    x_apply(value: number): number;
}

export interface Instance {
    exports: Exports;
}

export interface Handle {
    instance: Instance;
}

export interface Loader {
    async (imports: Imports): Promise<Exports>;
}

export default async function(imports: Imports): Promise<Exports> {
    const handle: Handle = await wasm(imports);
    return handle.instance.exports;
}
