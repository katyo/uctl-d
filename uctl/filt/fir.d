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
import uctl.num: fix, asfix, isNumer, isFixed, typeOf;
import uctl.math: isSinOrCos, sin, pi;
import uctl.unit: Val, rawTypeOf, hasUnits, Angle, hrev, qrev, rad, Frequency, Hz, as, to;
import uctl.util.vec: isVec, vecSize, VecType, sliceof;
import uctl.util.win: isWindow;
import uctl.util.dl: PFDL;

version(unittest) {
  import std.array: staticArray;
  import std.algorithm: map;
  import uctl.test: assert_eq, unittests;
  import uctl.util.win: dirichlet, bartlett;
  import uctl.unit: rev;

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

  /// Filter order
  enum uint N = N_;

  /// Window length
  enum uint L = N + 1;

  static if (isFixed!B) {
    alias I = fix!L;
    alias S = typeof(B() / (pi!(rad, B).raw * I()));
  } else {
    alias I = B;
    alias S = B;
  }

  private B[L] weight;

  alias weight this;
}

/**
 * Create impulse response using window function
 *
 * See_Also:
 *   [uctl.util.win]
 *   [Window function](https://en.wikipedia.org/wiki/Window_function) wikipedia article.
 */
template mk(alias P, alias F, alias S = sin) if (__traits(isSame, Param, P) && isWindow!F) {
  template mk(uint L, W) if (isNumer!W && L > 1) {
    alias mk = mk!(P, F, S, L, W);
  }
}

/**
   Create impulse response using window function

   Sampling calculates like so:

   $(MATH s = \frac{F_p + F_c}{2} \frac{1}{F_s} 2 \pi),

   where
   $(LIST
   * $(MATH F_p) - pass frequency, $(I Hz)
   * $(MATH F_c) - cutoff frequency, $(I Hz)
   * $(MATH F_s) - sampling rate, $(I Hz)
   )

   Or:

   $(MATH s = \frac{F_p + F_c}{2} dt 2 \pi),

   where
   $(LIST
   * $(MATH F_p) - pass frequency, $(I Hz)
   * $(MATH F_c) - cutoff frequency, $(I Hz)
   * $(MATH dt) - sampling pariod, $(I sec)
   )

   See_Also:
   [uctl.util.win]
   [Window function](https://en.wikipedia.org/wiki/Window_function) wikipedia article.
 */
pure nothrow @nogc @safe
auto mk(alias P, alias F, alias S, uint L, W, real dt, PF, CF)(const PF pass_freq, const CF cutoff_freq)
if (__traits(isSame, Param, P) && isWindow!F && isSinOrCos!(S, Val!(W, qrev)) && isNumer!W &&
    L > 1 && hasUnits!(PF, Frequency) && hasUnits!(CF, Frequency) && isNumer!(W, rawTypeOf!PF, rawTypeOf!CF)) {
  auto sampling = (pass_freq + cutoff_freq).raw * dt;
  return mk!(P, F, S, L, W)(sampling.as!hrev);
}

/// Test params using window function
nothrow @nogc unittest {
  enum dt = 0.001;

  immutable p1 = mk!(Param, dirichlet, sin!5, 5, float, dt)(100.0.as!Hz, 200.0.as!Hz);

  assert_eq(p1[0], 0.704693198);
  assert_eq(p1[1], 0.192574844);
  assert_eq(p1[2], 0.113196723);
  assert_eq(p1[3], 0.024502262);
  assert_eq(p1[4], -0.034966972);

  immutable p2 = mk!(Param, bartlett, sin!5, 5, float, dt)(100.0.as!Hz, 200.0.as!Hz);

  assert_eq(p2[0], 0.0);
  assert_eq(p2[1], 0.444739610);
  assert_eq(p2[2], 0.522841573);
  assert_eq(p2[3], 0.113172896);
  assert_eq(p2[4], -0.080754042);
}

/**
 * Create impulse response using window function
 *
 * See_Also:
 *   [uctl.util.win]
 *   [Window function](https://en.wikipedia.org/wiki/Window_function) wikipedia article.
 */
pure nothrow @nogc @safe
auto mk(alias P, alias F, alias S, uint L, W, T)(const T sampling)
if (__traits(isSame, Param, P) && isWindow!F && isSinOrCos!(S, Val!(W, qrev)) && isNumer!W &&
    L > 1 && hasUnits!(T, Angle) && isNumer!(W, rawTypeOf!T)) {
  enum uint N = L - 1;

  static if (isFixed!W) {
    alias B = fix!(-1, 1);
  } else {
    alias B = W;
  }

  alias R = Param!(N, B);

  alias P = typeof(W() * R.S());
  alias A = typeof(P() * R.I());

  immutable window = F!(L, W);
  P[N + 1] pulse_behavior;

  pulse_behavior[0] = sampling.to!rad.raw * window[0];

  A accum_weight = pulse_behavior[0];
  auto qrev_sampling = sampling.to!qrev;

  foreach (uint i; 1..L) {
    R.I index = i;
    const R.S ideal_pulse_behavior = S(qrev_sampling * index) / (pi!(rad, B).raw * index);
    pulse_behavior[i] = ideal_pulse_behavior * window[i];
    accum_weight += pulse_behavior[i];
  }

  R param;

  foreach (uint i; 0..L) {
    param[i] = pulse_behavior[i] / accum_weight;
  }

  return param;
}

/// Test params using window function
nothrow @nogc unittest {
  enum s = 0.15.as!rev;

  immutable p1 = mk!(Param, dirichlet, sin!5, 5, float)(s);

  assert_eq(p1[0], 0.704693198);
  assert_eq(p1[1], 0.192574844);
  assert_eq(p1[2], 0.113196723);
  assert_eq(p1[3], 0.024502262);
  assert_eq(p1[4], -0.034966972);

  immutable p2 = mk!(Param, bartlett, sin!5, 5, float)(s);

  assert_eq(p2[0], 0.0);
  assert_eq(p2[1], 0.444739610);
  assert_eq(p2[2], 0.522841573);
  assert_eq(p2[3], 0.113172896);
  assert_eq(p2[4], -0.080754042);
}

/**
 * Create impulse response using predefined weights
 */
pure nothrow @nogc @safe
auto mk(alias P, V)(const V weights) if (__traits(isSame, Param, P) && isVec!V &&
                                         isNumer!(VecType!V) && vecSize!V > 1) {
  enum auto L = vecSize!V;
  enum auto N = L - 1;
  alias W = VecType!V;

  alias R = Param!(N, W);

  R param;

  foreach (uint i; 0..L) {
    param[i] = weights.sliceof[i];
  }

  return param;
}

/**
 * FIR filter state
 *
 * Params:
 *   N = filter order
 *   T = input values type
 */
struct State(alias P_, T_) if (isInstanceOf!(Param, typeOf!P_) && isNumer!(P_.B, T_)) {
  alias P = typeOf!P_;
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
  auto opCall(ref const P param, const T value) {
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
  static immutable auto param = mk!Param([0.456, -0.137, 0.702, -1.421].staticArray!float);
  static State!(typeof(param), float) state = 0;

  assert_eq(state(param, 0.0), 0.0);
  assert_eq(state(param, 1.0), 0.456, 1e-8);
  assert_eq(state(param, 0.0), -0.137, 1e-8);
  assert_eq(state(param, 0.0), 0.702, 1e-7);
  assert_eq(state(param, 0.0), -1.421, 1e-8);
  assert_eq(state(param, 0.0), 0.0);

  assert_eq(state(param, 0.123), 0.056088, 1e-8);
  assert_eq(state(param, 11.234), 5.105853, 1e-7);
  assert_eq(state(param, 5.001), 0.827744, 1e-6);
  assert_eq(state(param, -3.120), 5.603628, 1e-6);
  assert_eq(state(param, -8.998), -16.128460, 1e-7);
}

/// Test FIR filter (fixed-point)
nothrow @nogc unittest {
  alias W = fix!(-1, 2);
  alias X = fix!(-10, 15);
  alias Y = fix!(-80, 120);

  static immutable auto param = mk!Param([0.456, -0.137, 0.702, -1.421].map!(w => cast(W) w).staticArray!4);
  static State!(typeof(param), X) state = cast(X) 0;

  assert_eq(state(param, cast(X) 0.0), cast(Y) 0.0);
  assert_eq(state(param, cast(X) 1.0), cast(Y) 0.456);
  assert_eq(state(param, cast(X) 0.0), cast(Y) -0.137);
  assert_eq(state(param, cast(X) 0.0), cast(Y) 0.702, cast(Y) 1e-7);
  assert_eq(state(param, cast(X) 0.0), cast(Y) -1.421);
  assert_eq(state(param, cast(X) 0.0), cast(Y) 0.0);

  assert_eq(state(param, cast(X) 0.123), cast(Y) 0.056088);
  assert_eq(state(param, cast(X) 11.234), cast(Y) 5.105853, cast(Y) 1e-7);
  assert_eq(state(param, cast(X) 5.001), cast(Y) 0.827744, cast(Y) 1e-7);
  assert_eq(state(param, cast(X) -3.120), cast(Y) 5.603628, cast(Y) 1e-7);
  assert_eq(state(param, cast(X) -8.998), cast(Y) -16.128460, cast(Y) 1e-7);
}
