/**
 * EMA filter
 *
 * Exponential Moving Average filter.
 *
 * EMA is a simple and fast filter which does not require delay-line but only single result of previous evaluation as a state.
 *
 * Filter formula: $(MATH y = α x + (1 - α) y_{z^{-1}})
 *
 * There are different ways of definition a filter parameters, such as:
 *
 * $(NUMBERED_LIST
 *   * Using `α` factor
 *   * Through number of smoothing samples
 *   * Through smoothing time
 *   * As an 1st-order transmission behavior
 * )
 *
 * ![EMA filtering](filt_ema.svg)
 *
 * See_Also: [Exponential moving average](https://en.wikipedia.org/wiki/Moving_average#Exponential_moving_average).
 */
module uctl.filt.ema;

import std.traits: isInstanceOf, Unqual;
import uctl.num: fix, asnum, isNumer, isFixed, typeOf;
import uctl.unit: Val, as, to, hasUnits, Time, isTiming, asTiming, rawTypeOf, rawof, sec;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.num: asfix;

  mixin unittests;
}

/// Filter parameters flavor
struct Flavor(string name_) {
  /// Human readable name
  enum string name = name_;
}

/// Check for parameters flavor
template isFlavor(X...) if (X.length == 1 || X.length == 2) {
  static if (X.length == 1) {
    static if (is(X[0])) {
      enum bool isFlavor = isInstanceOf!(Flavor, X[0]);
    } else {
      enum bool isFlavor = isFlavor!(typeof(X[0]));
    }
  } else {
    enum bool isFlavor = isFlavor!(X[0]) && is(X[0] == X[1]);
  }
}

/**
 * EMA filter parameters
 *
 * Params:
 *   A = filter weights type
 */
struct Param(A_ = float, F_, alias s_ = void) if (isNumer!A_ &&
                                                  isFlavor!F_ &&
                                                  (is(s_ == void) ||
                                                   (!is(s_) && isTiming!s_))) {
  /// Parameters flavor
  alias F = F_;

  static if (!is(s_ == void)) {
    /// Sampling
    enum s = s_;
  }

  /// Self type
  alias Self = typeof(this);

  /// Alpha type
  alias A = Unqual!A_;

  /// Complementary alpha type
  alias Acmpl = typeof(asnum!(1, A_) - A_());

  /// The value of `α` parameter
  A alpha = 1.0;

  /// The value of `1-α` (complementary `α`)
  Acmpl cmpl_alpha = 0.0;

  /// Create parameters
  const pure nothrow @nogc @safe
  this(const A alpha_, const Acmpl cmpl_alpha_) {
    alpha = alpha_;
    cmpl_alpha = cmpl_alpha_;
  }

  /// Create parameters using weight value
  const pure nothrow @nogc @safe
  this(const A alpha_) {
    alpha = alpha_;
    cmpl_alpha = asnum!(1, A) - alpha_;
  }

  /// Change parameters according to flavor
  pure nothrow @nogc @safe
  void opAssign(T)(const T arg) if (((isFlavor!(F, Alpha) || isFlavor!(F, Samples)) &&
                                     isNumer!(T, A)) ||
                                    ((isFlavor!(F, Window) || isFlavor!(F, PT1)) &&
                                     hasUnits!(T, Time) && isNumer!(rawTypeOf!T, A))) {
    static if (isFlavor!(F, Alpha)) {
      auto alpha_ = arg;
    } else static if (isFlavor!(F, Samples)) {
      auto alpha_ = asnum!(2, T) / (arg + asnum!(1, T));
    } else {
      enum dt = asTiming!(s, sec, T).raw;
      auto time = arg.to!sec.raw;

      static if (isFlavor!(F, Window)) {
        auto alpha_ = (dt + dt) / (time + dt);
      } else static if (isFlavor!(F, PT1)) {
        auto alpha_ = dt / (time + dt);
      }
    }
    alpha = cast(A) alpha_;
    cmpl_alpha = cast(Acmpl) (asnum!(1, typeof(alpha_)) - alpha_);
  }
}

/// Filter parameters using `α` factor
alias Alpha = Flavor!("Alpha factor");

/**
 * Init EMA parameters using `α` factor
 *
 * Params:
 *   alpha = The value of `α` in range 0.0 .. 1.0
 *
 * Usually the alpha factor can be treated as the weight of actual value in result.
 * This meaning that when the alpha equals to 1 then no smoothing will be applied.
 * The less alpha does more smoothing and vise versa.
 *
 * Filter formula: $(MATH y = α x + (1 - α) y_{z^{-1}})
 */
pure nothrow @nogc @safe
auto mk(F, A)(const A alpha) if (isFlavor!(F, Alpha) && isNumer!A) {
  return Param!(A, Alpha)(alpha);
}

/// Test params from alpha
nothrow @nogc unittest {
  static param = mk!Alpha(0.6);

  assert_eq(param.alpha, 0.6, 1e-6);
  assert_eq(param.cmpl_alpha, 0.4, 1e-6);

  param = 0.5;

  assert_eq(param.alpha, 0.5);
  assert_eq(param.cmpl_alpha, 0.5);
}

/// Filter parameters using number of samples to smooth
alias Samples = Flavor!("Number of samples");

/**
 * Init EMA parameters using number of samples
 *
 * Params:
 *   n = The number of samples in range 1.0 ... ∞
 *
 * Usually the `N` can be treated as the number of samples for smoothing.
 * This means that when the `N` equals to 1 then no smoothing will be applied.
 * The more `N` does more smoothing and vise versa.
 *
 * $(MATH α = \frac{2}{n + 1})
 *
 * Filter formula: $(MATH y = \frac{2}{n + 1} x + \frac{n - 1}{n + 1} y_{z^{-1}})
 *
 * See_Also: [mk].
 */
pure nothrow @nogc @safe
auto mk(F, N)(const N n) if (isFlavor!(F, Samples) && isNumer!N) {
  // α = 2 / (n + 1)
  auto alpha = asnum!(2, N) / (n + asnum!(1, N));

  return Param!(typeof(alpha), Samples)(alpha);
}

/// Params from samples
nothrow @nogc unittest {
  static param = mk!Samples(2.0);

  assert_eq(param.alpha, 0.6666667, 1e-6);
  assert_eq(param.cmpl_alpha, 0.3333333, 1e-6);

  param = 3.0;

  assert_eq(param.alpha, 0.5);
  assert_eq(param.cmpl_alpha, 0.5);
}

/// Params from samples (fixed)
nothrow @nogc unittest {
  static immutable auto param = mk!Samples(asfix!2.0);

  assert_eq(param.alpha, asfix!0.6666666665);
  assert_eq(param.cmpl_alpha, asfix!0.3333333335);
}

/// Filter parameters using time window to smooth
alias Window = Flavor!("Time window");

/**
 * Init EMA parameters using time window
 *
 * Params:
 *   time = The smooth time value
 *   period = The sampling time (or control step period)
 *
 * $(MATH α = \frac{2}{\frac{T}{P} + 1} = \frac{2 P}{T + P})
 *
 * $(MATH T = P \Rightarrow α = 1)
 *
 * $(MATH T > P \Rightarrow α < 1)
 *
 * Filter formula: $(MATH y = \frac{2 P}{T + P} x + \frac{T - P}{T + P} y_{z^{-1}})
 *
 * See_Also: [mk].
 */
pure nothrow @nogc @safe
auto mk(F, alias s, T)(const T time) if (isFlavor!(F, Window) && isTiming!s && hasUnits!(T, Time)) {
  enum dt = asTiming!(s, sec, T).raw;
  /// α = 2 * dt / (t + dt)
  auto alpha = (dt + dt) / (time.to!sec.raw + dt);

  return Param!(typeof(alpha), Window, s)(alpha);
}

/// Test params from time window
nothrow @nogc unittest {
  enum auto dt = 0.1.as!sec;
  static param = mk!(Window, dt)(4.0.as!sec);

  assert_eq(param.alpha, 0.0487805, 1e-6);
  assert_eq(param.cmpl_alpha, 0.951219, 1e-6);

  param = 2.0.as!sec;

  assert_eq(param.alpha, 0.095238, 1e-6);
  assert_eq(param.cmpl_alpha, 0.904762, 1e-6);
}

/// Test params from time window (fixed)
nothrow @nogc unittest {
  enum auto dt = 0.1.as!sec;
  static immutable param = mk!(Window, dt)(asfix!4.0.as!sec);

  assert_eq(param.alpha, asfix!0.0487804878);
  assert_eq(param.cmpl_alpha, asfix!0.9512195126);
}

/// Filter parameters using 1st-order transmission behavior
alias PT1 = Flavor!("PT1 model");

/**
 * Init EMA parameters as 1st-order transmission behavior.
 *
 * See [PT1](https://de.wikipedia.org/wiki/PT1-Glied).
 *
 * $(MATH α = \frac{1}{1 + \frac{T}{P}} = \frac{P}{T + P})
 *
 * Filter formula: $(MATH y = \frac{P}{P + T} x + \frac{T}{P + T} y_{z^{-1}})
 *
 * See_Also: [mk].
 */
pure nothrow @nogc @safe
auto mk(F, alias s, T)(const T time) if (isFlavor!(F, PT1) && isTiming!s && hasUnits!(T, Time)) {
  enum dt = asTiming!(s, sec, T).raw;
  auto alpha = dt / (time.to!sec.raw + dt);

  return Param!(typeof(alpha), PT1, s)(alpha);
}

/// Test params as PT1
nothrow @nogc unittest {
  enum auto dt = 0.1.as!sec;
  static param = mk!(PT1, dt)(4.0.as!sec);

  assert_eq(param.alpha, 0.0243902, 1e-6);
  assert_eq(param.cmpl_alpha, 0.97561, 1e-6);

  param = 2.0.as!sec;

  assert_eq(param.alpha, 0.047619, 1e-6);
  assert_eq(param.cmpl_alpha, 0.95238, 1e-6);
}

/**
 * EMA filter state
 *
 * Params:
 *   P = parameters type
 *   T = input value type
 */
struct State(alias P_, T_) if (isInstanceOf!(Param, P_.Self) && (isNumer!(P_.A, T_) || (hasUnits!T_ && isNumer!(P_.A, rawTypeOf!T_)))) {
  /// Parameters type
  alias P = typeOf!P_;

  /// Value type
  alias T = Unqual!T_;

  /// Raw value type
  alias Traw = rawTypeOf!T;

  /// Self type
  alias Self = typeof(this);

  /// The last output value
  T last_out = 0.0;

  /// Initialize using initial value
  pure nothrow @nogc @safe
  this(const T initial) const {
    last_out = initial;
  }

  /// Set last filtered value
  pure nothrow @nogc @safe
  void opAssign(const T value) {
    last_out = value;
  }

  /// Get last filtered value
  pure nothrow @nogc @safe
  T opCast() const {
    return last_out;
  }

  /**
     Apply filter or evaluate filtering step

     Params:
     param = filter parameters
     value = input value

     Returns: filtered value
   */
  pure nothrow @nogc @safe
  T opCall(const ref P param, const T value) {
    // X = alpha * X + (1 - alpha) * X0
    return last_out = Traw(param.alpha * value.rawof +
                           param.cmpl_alpha * last_out.rawof).as!T;
  }
}

/// Params from alpha
nothrow @nogc unittest {
  static immutable auto param = mk!Alpha(0.6);
  static auto state = State!(param, double)();

  assert_eq(state(param, 1.3), 0.78, 1e-6);
  assert_eq(state(param, 0.8), 0.792, 1e-6);
  assert_eq(state(param, -0.5), 0.0168, 1e-6);
  assert_eq(state(param, -0.3), -0.17328, 1e-6);
}

/// Params from samples
nothrow @nogc unittest {
  static immutable auto param = mk!Samples(2.0);
  static auto state = State!(param, double)();

  assert_eq(state(param, 1.0), 0.6666667, 1e-6);
  assert_eq(state(param, 1.0), 0.8888889, 1e-6);
}

/// Params from time
nothrow @nogc unittest {
  enum auto dt = 0.1.as!sec;

  static immutable auto param = mk!(Window, dt)(4.0.as!sec);
  static auto state = State!(param, double)();

  assert_eq(state(param, 1.3), 0.06341463327, 1e-8);
  assert_eq(state(param, 0.8), 0.09934562445, 1e-8);
  assert_eq(state(param, -0.5), 0.07010925002, 1e-8);
  assert_eq(state(param, -0.3), 0.05205513909, 1e-8);
}

/// Params from samples (fixed)
nothrow @nogc unittest {
  alias X = fix!(0, 1);

  static immutable auto param = mk!Samples(asfix!2.0);
  static auto state = State!(param, X)();

  assert_eq(state(param, cast(X) 1.0), cast(X) 0.666666666);
  assert_eq(state(param, cast(X) 1.0), cast(X) 0.8888888881);
}

/// Params from time (fixed)
nothrow @nogc unittest {
  enum auto dt = 0.1.as!sec;
  alias X = fix!(-1, 2);

  static immutable auto param = mk!(Window, dt)(asfix!4.0.as!sec);
  static auto state = State!(param, X)();

  assert_eq(state(param, cast(X) 1.3), cast(X) 0.06341463327);
  assert_eq(state(param, cast(X) 0.8), cast(X) 0.09934562445);
  assert_eq(state(param, cast(X) -0.5), cast(X) 0.07010925002);
  assert_eq(state(param, cast(X) -0.3), cast(X) 0.05205513909);
}

/// Params from time (with units)
nothrow @nogc unittest {
  import uctl.unit: degC;

  enum auto dt = 0.1.as!sec;

  static immutable auto param = mk!(Window, dt)(4.0.as!sec);
  static auto state = State!(param, Val!(double, degC))();

  assert_eq(state(param, 1.3.as!degC), 0.06341463327.as!degC, 1e-8);
  assert_eq(state(param, 0.8.as!degC), 0.09934562445.as!degC, 1e-8);
  assert_eq(state(param, -0.5.as!degC), 0.07010925002.as!degC, 1e-8);
  assert_eq(state(param, -0.3.as!degC), 0.05205513909.as!degC, 1e-8);
}
