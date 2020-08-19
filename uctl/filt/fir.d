/**
 * ## FIR filter
 *
 * Finite Impulse Response filter.
 *
 * See_Also:
 *   [Finite impulse response](https://en.wikipedia.org/wiki/Finite_impulse_response).
 */
module uctl.filt.fir;

import std.math: PI, sin;

import uctl.fix: isNumer;
import uctl.util.win: Window;
import uctl.util.dl: PFDL;

version(unittest) {
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
  alias B = B_;

  enum uint N = N_;

  enum uint L = N + 1;

  private B[L] weight;

  /// Get weight value by index
  const pure nothrow @nogc @safe
  ref B opIndex(uint i) {
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
template param_from_window(uint N, W = float, SIN = sin) if (isNumer!W && N > 0) {
  enum uint L = N + 1;

  static if (isFixed!W) {
    alias Nt = fix!L;
    enum auto pi = asfix!PI;
    alias It = typeof(fix!(-1.0, 1.0)() / (pi * Nt()));
    alias B = fix!(0, 1);
  } else {
    alias Nt = W;
    alias It = W;
    alias B = W;
    enum auto pi = PI;
  }

  alias P = typeof(It() * W());
  alias A = typeof(P() * Nt());

  alias R = Param!(N, B);

  alias param_from_window = (ref const Window!(N, W) window, It sampling) {
    P[N + 1] pulse_behavior = [ 0: sampling * window[0] ];
    A accum_weight = pulse_behavior[0];

    foreach (uint i; 1..L) {
      Nt index = i;
      It ideal_pulse_behavior = SIN(sampling * index) / (pi * index);
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
 * FIR filter state
 *
 * Params:
 *   N = filter order
 *   T = input values type
 */
struct State(uint N, T) {
  private PFDL!(N, T) dl;

  alias dl this;

  /**
   * Apply filter or evaluate filtering step
   */
  auto apply(B)(ref const Param!(N, B) param, const T value) if (isNumer!(B, T)) {
    static if (isFixed!T) {
      alias Nt = fix!(N+1);
    } else {
      alias Nt = T;
    }

    alias R = typeof(B() * T() * Nt());

    R res = param[0] * value;

    foreach (uint i; 0 .. N) {
      res += param[i + 1] * dl[i];
    }

    dl.push(value);

    return res;
  }
}
