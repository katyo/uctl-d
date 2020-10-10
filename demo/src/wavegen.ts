export type Basic = {
    gain?: number;
    bias?: number;
};

export type Rand = Basic & {
    kind: 'rand';
}

export type HasFrequency = {
    frequency: number;
}

export type HasPeriod = {
    period: number;
};

export type Periodic = Basic & {
    delay?: number;
} & (HasFrequency | HasPeriod);

export type Sine = Periodic & {
    kind: 'sine';
};

export type Saw = Periodic & {
    kind: 'saw';
}

export type Wave = Rand | Sine | Saw;

export type Generator = (time: number) => number;

export function generator(waves: Wave[], {gain = 1.0, bias = 0.0}: Basic = {}): Generator {
    const gens = waves.map((wave) => {
        const {kind, gain = 1.0, bias = 0.0} = wave;
        switch (kind) {
            case "rand":
                return (time: number) => bias + gain * Math.random();
            case "sine": {
                const {delay = 0.0} = wave as Sine;
                const factor = time_factor(wave as Sine);
                return (time: number) => bias + gain * Math.sin(delay + time * factor);
            }
            case "saw": {
                const {delay = 0.0} = wave as Saw;
                const factor = time_factor(wave as Saw);
                return (time: number) => bias + gain * ((delay + time * factor) % 1.0);
            }
        }
    });

    return (time: number) =>
        bias + gain * gens.map((gen) => gen(time)).reduce((a, b) => a + b, 0.0);
}

function time_factor(wave: Periodic): number {
    if (typeof (wave as HasFrequency).frequency == 'number') {
        return 2.0 * Math.PI * (wave as HasFrequency).frequency;
    }

    if (typeof (wave as HasPeriod).period == 'number') {
        return 2.0 * Math.PI / (wave as HasPeriod).period;
    }

    return 2.0 * Math.PI;
}
