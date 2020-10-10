import wasm from './lqe.wasm';

export interface Imports {}

export interface Exports {
    get_timing(): number;

    f_set_params(f: number, h: number, q: number, r: number);
    f_reset(value: number, covar: number);
    f_apply(value: number): number;

    x_set_params(f: number, h: number, q: number, r: number);
    x_reset(value: number, covar: number);
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
