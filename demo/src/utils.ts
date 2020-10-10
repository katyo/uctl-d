import {fftReal} from 'dsp-collection/signal/Fft';

export type Point = [number, number];

export function spectrum(signal: number[], sample_rate: number): Point[] {
    const scale = 1.0 / signal.length;
    const step = sample_rate * scale;

    const rlength = Math.floor(signal.length / 2);
    const rscale = scale * 2.0 / Math.sqrt(2.0);

    const { im, re } = fftReal(new Float64Array(signal));
    const result: Point[] = new Array(rlength);

    for (let i of [0, rlength - 1]) {
        const re_ = re[i] * scale;
        const im_ = im[i] * scale;
        const m = Math.sqrt(re_ * re_ + im_ * im_);
        //const m2 = re_ * re_ + im_ * im_;
        result[i] = [i * step, m];
    }

    for (let i = 1; i < rlength - 1; i++) {
        const re_ = re[i] * rscale;
        const im_ = im[i] * rscale;
        const m = Math.sqrt(re_ * re_ + im_ * im_);
        //const m = re_ * re_ + im_ * im_;
        result[i] = [i * step, m];
    }

    return result;
}

export function to_db(value: number): number {
    return 20.0 * Math.log10(value);
}

export function from_db(value: number): number {
    return Math.pow(10.0, value * 0.05);
}
