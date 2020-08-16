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
 * See_Also: [Exponential moving average](https://en.wikipedia.org/wiki/Moving_average#Exponential_moving_average).
 */
module uctl.filt.ema;

import std.traits: isInstanceOf;
import uctl.fix: fix, asfix, isNumer, isFixed;

version(unittest) {
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/**
 * EMA filter parameters
 *
 * Params:
 *   A = filter weights type
 */
struct Param(A = float) if (isNumer!A) {
  alias Self = typeof(this);

  /// The value of `α` parameter
  A alpha = 1.0;

  static if (isFixed!A) {
    alias Acmpl = typeof(asfix!1.0 - alpha);
  } else {
    alias Acmpl = A;
  }

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

    static if (isFixed!A) {
      cmpl_alpha = asfix!1.0 - alpha_;
    } else {
      cmpl_alpha = 1.0 - alpha_;
    }
  }

  /**
   * Adjust parameters gain
   */
  const pure nothrow @nogc @safe
  auto opBinary(string op, G)(const G gain) if ((op == "*" || op == "/") && isNumer!G) {
    return Param(alpha * gain, cmpl_alpha * gain);
  }
}

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
auto param_from_alpha(A)(const A alpha) if (isNumer!A) {
  return Param!A(alpha);
}

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
 * See_Also: `param_from_alpha`.
 */
pure nothrow @nogc @safe
auto param_from_samples(N)(const N n) if (isNumer!N) {
  // α = 2 / (n + 1)
  static if (isFixed!N) {
    auto alpha = asfix!2.0 / (n + asfix!1.0);
  } else {
    auto alpha = 2.0 / (n + 1.0);
  }
  return param_from_alpha(alpha);
}

/**
 * Init EMA parameters using time factor
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
 * See_Also: `param_from_alpha`.
 */
pure nothrow @nogc @safe
auto param_from_time(T, P)(const T time, const P period) if (isNumer!T && isNumer!P) {
  auto alpha = (period + period) / (time + period);

  return param_from_alpha(alpha);
}

/**
 * Init EMA parameters as 1st-order transmission behavior.
 *
 * See [PT1](https://de.wikipedia.org/wiki/PT1-Glied).
 *
 * $(MATH α = \frac{1}{1 + \frac{T}{P}} = \frac{P}{T + P})
 *
 * Filter formula: $(MATH y = \frac{P}{P + T} x + \frac{T}{P + T} y_{z^{-1}})
 *
 * See_Also: `param_from_alpha`.
 */
pure nothrow @nogc @safe
auto param_from_pt1(T, P)(const T time, const P period) if (isNumer!T && isNumer!P) {
  auto alpha = period / (time + period);
  return param_from_alpha(alpha);
}

/**
 * EMA filter state
 *
 * Params:
 *   P = parameters type
 *   T = input value type
 */
struct State(P = Param!float, T = float) if (isInstanceOf!(Param, P) && isNumer!T) {
  alias Self = typeof(this);

  /// Output value type
  static if (isFixed!T) {
    alias R = typeof(P().alpha * T() + P().cmpl_alpha * T());
  } else {
    alias R = T;
  }

  /// The last output value
  R last_out = 0.0;

  /// Initialize using initial value
  const pure nothrow @nogc @safe
  this(const R initial) {
    last_out = initial;
  }

  /**
   * Apply filter or evaluate filtering step
   *
   * Params:
   *   param = filter parameters
   *   value = input value
   *
   * Returns: filtered value
   */
  pure nothrow @nogc @safe
  R apply(const ref P param, const T value) {
    // X = alpha * X + (1 - alpha) * X0
    auto res = (param.alpha * value +
                param.cmpl_alpha * last_out);
    last_out = res;
    return res;
  }
}

/// Params from alpha
nothrow @nogc unittest {
  static immutable auto param = param_from_alpha(0.6);

  assert_eq(param.alpha, 0.6, 1e-6);
  assert_eq(param.cmpl_alpha, 0.4, 1e-6);

  static auto state = State!(typeof(param))();

  assert_eq(state.apply(param, 1.3), 0.78, 1e-6);
  assert_eq(state.apply(param, 0.8), 0.792, 1e-6);
  assert_eq(state.apply(param, -0.5), 0.0168, 1e-6);
  assert_eq(state.apply(param, -0.3), -0.17328, 1e-6);
}

/// Params with gain
nothrow @nogc unittest {
  static immutable auto param = param_from_alpha(0.6) * 1.2;

  assert_eq(param.alpha, 0.72, 1e-6);
  assert_eq(param.cmpl_alpha, 0.48, 1e-6);
}

/// Params from samples
nothrow @nogc unittest {
  static immutable auto param = param_from_samples(2.0);

  assert_eq(param.alpha, 0.6666667, 1e-6);
  assert_eq(param.cmpl_alpha, 0.3333333, 1e-6);

  static auto state = State!(param.Self)();

  assert_eq(state.apply(param, 1.0), 0.6666667, 1e-6);
  assert_eq(state.apply(param, 1.0), 0.8888889, 1e-6);
}

/// Params from time
nothrow @nogc unittest {
  static immutable auto param = param_from_time(4.0, 0.1);

  assert_eq(param.alpha, 0.0487805, 1e-6);
  assert_eq(param.cmpl_alpha, 0.951219, 1e-6);

  static auto state = State!(param.Self)();

  assert_eq(state.apply(param, 1.3), 0.06341463327, 1e-8);
  assert_eq(state.apply(param, 0.8), 0.09934562445, 1e-8);
  assert_eq(state.apply(param, -0.5), 0.07010925002, 1e-8);
  assert_eq(state.apply(param, -0.3), 0.05205513909, 1e-8);
}

/// Params from pt1
nothrow @nogc unittest {
  static immutable auto param = param_from_pt1(4.0, 0.1);

  assert_eq(param.alpha, 0.0243902, 1e-6);
  assert_eq(param.cmpl_alpha, 0.97561, 1e-6);
}

/// Params from samples (fixed)
nothrow @nogc unittest {
  static immutable auto param = param_from_samples(asfix!2.0);

  assert_eq(param.alpha, asfix!0.6666666665);
  assert_eq(param.cmpl_alpha, asfix!0.3333333335);

  alias X = fix!(0, 1);

  static auto state = State!(param.Self, X)();

  assert_eq(state.apply(param, cast(X) 1.0), cast(X) 0.666666666);
  assert_eq(state.apply(param, cast(X) 1.0), cast(X) 0.8888888881);
}

/// Params from time (fixed)
nothrow @nogc unittest {
  static immutable auto param = param_from_time(asfix!4.0, asfix!0.1);

  assert_eq(param.alpha, asfix!0.0487804878);
  assert_eq(param.cmpl_alpha, asfix!0.9512195126);

  alias X = fix!(-1, 2);

  static auto state = State!(param.Self, X)();

  assert_eq(state.apply(param, cast(X) 1.3), cast(X) 0.06341463327);
  assert_eq(state.apply(param, cast(X) 0.8), cast(X) 0.09934562445);
  assert_eq(state.apply(param, cast(X) -0.5), cast(X) 0.07010925002);
  assert_eq(state.apply(param, cast(X) -0.3), cast(X) 0.05205513909);
}
