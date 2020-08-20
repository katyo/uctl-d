/**
 * ## FIR filter
 *
 * Finite Impulse Response filter.
 *
 * The parameters of filter can be found using different analytical methods and it's non-trivial.
 *
 * See_Also:
 *   [Finite impulse response](https://en.wikipedia.org/wiki/Finite_impulse_response).
 */
module uctl.filt.fir;

import std.traits: Unqual, isInstanceOf;
import std.math: PI, sin;

import uctl.fix: fix, asfix, isNumer, isFixed;
import uctl.util.win: Window;
import uctl.util.dl: PFDL;

version(unittest) {
  import std.array: staticArray;
  import std.algorithm: map;
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/**
 * FIR filter parameters
 *
 * The impulse response values.
 *
 * Params:
 *   N = filter order
 *   B = filter weights type
 */
struct Param(uint N_, B_) if (isNumer!B_ && N_ > 0) {
  alias B = Unqual!B_;

  enum uint N = N_;

  enum uint L = N + 1;

  static if (isFixed!B) {
    alias I = fix!L;
    alias S = typeof(fix!(-1, 1)() / (fix!PI() * I()));
  } else {
    alias I = B;
    alias S = B;
  }

  private B[L] weight;

  /// Get weight value by index
  const pure nothrow @nogc @safe
  B opIndex(uint i) {
    return weight[i];
  }

  /// Set weight value by index
  pure nothrow @nogc @safe
  void opIndexAssign(B v, uint i) {
    weight[i] = v;
  }
}

/**
 * Create impulse response using window function
 *
 * See_Also:
 *   [uctl.util.win]
 *   [Window function](https://en.wikipedia.org/wiki/Window_function) wikipedia article.
 */
template param_from_window(uint L, W = float, SIN = sin) if (isNumer!W && L > 1) {
  enum uint N = L - 1;

  static if (isFixed!W) {
    enum auto pi = asfix!PI;
    alias B = fix!(-1, 1);
  } else {
    enum auto pi = PI;
    alias B = W;
  }

  alias R = Param!(N, B);

  alias P = typeof(W() * R.S());
  alias A = typeof(P() * R.I());

  alias param_from_window = (ref const Window!(N, W) window, R.S sampling) {
    P[N + 1] pulse_behavior = [ 0: sampling * window[0] ];
    A accum_weight = pulse_behavior[0];

    foreach (uint i; 1..L) {
      R.I index = i;
      R.S ideal_pulse_behavior = SIN(sampling * index) / (pi * index);
      pulse_behavior[i] = ideal_pulse_behavior * window[i];
      accum_weight += pulse_behavior[i];
    }

    R param;

    foreach (uint i; 0..L) {
      param[i] = pulse_behavior[i] / accum_weight;
    }

    return param;
  };
}

/**
   Calculate sampling for [param_from_window].
 */
auto calculate_sampling(F, P, C)(F sample_rate, P pass_freq, C cutoff_freq) if (isNumer!(F, P, C)) {
  static if (isFixed!F) {
    enum auto pi = asfix!PI;
  } else {
    enum auto pi = PI;
  }
  return (pass_freq + cutoff_freq) * pi / sample_rate;
}

/**
 * Create impulse response using predefined weights
 */
template param_from_weights(uint L, W) {
  enum uint N = L - 1;

  alias R = Param!(N, W);

  R param_from_weights(const W[L] weights) {
    R param;

    foreach (uint i; 0..L) {
      param[i] = weights[i];
    }

    return param;
  }
}

/**
 * FIR filter state
 *
 * Params:
 *   N = filter order
 *   T = input values type
 */
struct State(alias P_, T_) if (isInstanceOf!(Param, P_) && isNumer!(P_.B, T_)) {
  alias P = P_;

  alias T = T_;

  private PFDL!(P.L, T) dl;

  alias dl this;

  /// Initialize state using initial value
  const pure nothrow @nogc @safe
  this(const T initial) {
    dl = initial;
  }

  /**
   * Apply filter or evaluate filtering step
   */
  auto apply(ref const P param, const T value) {
    alias R = typeof(P.B() * T() * P.I());

    R res = param[0] * value;

    foreach (uint i; 0 .. P.N) {
      res += param[i + 1] * dl[i];
    }

    dl.push(value);

    return res;
  }
}

/// Test FIR filter (floating-point)
nothrow @nogc unittest {
  static immutable auto param = param_from_weights([0.456, -0.137, 0.702, -1.421].staticArray!float);
  static State!(typeof(param), float) state = 0;

  assert_eq(state.apply(param, 0.0), 0.0);
  assert_eq(state.apply(param, 1.0), 0.456, 1e-8);
  assert_eq(state.apply(param, 0.0), -0.137, 1e-8);
  assert_eq(state.apply(param, 0.0), 0.702, 1e-7);
  assert_eq(state.apply(param, 0.0), -1.421, 1e-8);
  assert_eq(state.apply(param, 0.0), 0.0);

  assert_eq(state.apply(param, 0.123), 0.056088, 1e-8);
  assert_eq(state.apply(param, 11.234), 5.105853, 1e-7);
  assert_eq(state.apply(param, 5.001), 0.827744, 1e-6);
  assert_eq(state.apply(param, -3.120), 5.603628, 1e-6);
  assert_eq(state.apply(param, -8.998), -16.128460, 1e-7);
}

/// Test FIR filter (fixed-point)
nothrow @nogc unittest {
  alias W = fix!(-1, 2);
  alias X = fix!(-10, 15);
  alias Y = fix!(-80, 120);

  static immutable auto param = param_from_weights([0.456, -0.137, 0.702, -1.421].map!(w => cast(W) w).staticArray!4);
  static State!(typeof(param), X) state = cast(X) 0;

  assert_eq(state.apply(param, cast(X) 0.0), cast(Y) 0.0);
  assert_eq(state.apply(param, cast(X) 1.0), cast(Y) 0.456);
  assert_eq(state.apply(param, cast(X) 0.0), cast(Y) -0.137);
  assert_eq(state.apply(param, cast(X) 0.0), cast(Y) 0.702, cast(Y) 1e-7);
  assert_eq(state.apply(param, cast(X) 0.0), cast(Y) -1.421);
  assert_eq(state.apply(param, cast(X) 0.0), cast(Y) 0.0);

  assert_eq(state.apply(param, cast(X) 0.123), cast(Y) 0.056088);
  assert_eq(state.apply(param, cast(X) 11.234), cast(Y) 5.105853, cast(Y) 1e-7);
  assert_eq(state.apply(param, cast(X) 5.001), cast(Y) 0.827744, cast(Y) 1e-7);
  assert_eq(state.apply(param, cast(X) -3.120), cast(Y) 5.603628, cast(Y) 1e-7);
  assert_eq(state.apply(param, cast(X) -8.998), cast(Y) -16.128460, cast(Y) 1e-7);
}
