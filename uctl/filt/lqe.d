/**
  ## LQE (Kalman) filter

  This module implements Linear Quadratic Estimation (LQE) filter which also known as Kalman filter.

  Filter has four parameters:

  $(LIST
    * `F` - state-transition model (factor of actual value to previous actual value)
    * `H` - observation model (factor of measured value to actual value)
    * `Q` - covariance of the process noise (measurement noise)
    * `R` - covariance of the observation (environment noise)
  )

  Filter consists of two stages:

  $(NUMBERED_LIST
    * Predict
    $(LIST
      * Predict state as $(MATH X_0 = F X)
      * Predict covariance $(MATH P_0 = F^2 P + Q)
    )
    * Update
    $(LIST
      * Innovation covariance as $(MATH S = H^2 P_0 + R)
      * Calculate optimal gain as $(MATH K = P_0 H S^-1)
      * Update estimate covariance as $(MATH P = (1 - K H) P_0)
      * Update state estimate as $(MATH X = X_0 + K (X - H X_0))
    )
  )

  See_Also:
    [Kalman filter](https://en.wikipedia.org/wiki/Kalman_filter) wikipedia article.
*/
module uctl.filt.lqe;

import std.traits: isInstanceOf;
import uctl.num: isNumer, isFixed, fix, asnum, asfix, typeOf;

version(unittest) {
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/**
   LQE filter parameters

   Params:
     F = factor type
     N = noise type
     F2 = square factor type
*/
struct Param(F_, H_, Q_, R_) if (isNumer!(F_, H_, Q_, R_)) {
  alias Self = typeof(this);

  alias F = F_;
  alias H = H_;
  alias Q = Q_;
  alias R = R_;
  alias F2 = typeof(F() * F());
  alias H2 = typeof(H() * H());

  /// Factor of actual value to previous actual value
  F f;
  /// Factor of measured value to actual value
  H h;
  /// Measurement noise
  Q q;
  /// Environment noise
  R r;

  /// Square f
  F2 f2;
  /// Square h
  H2 h2;

  /**
     Init LQE parameters
  */
  const pure nothrow @nogc @safe
  this(F f_, H h_, Q q_, R r_) {
    f = f_;
    h = h_;
    q = q_;
    r = r_;

    f2 = f * f;
    h2 = h * h;
  }
}

/// Create LQE parameters from coefficients
pure nothrow @nogc @safe
Param!(F, H, Q, R) mk(alias P, F, H, Q, R)(const F f, const H h, const Q q, const R r)
if (__traits(isSame, P, Param) && isNumer!(F, H, Q, R)) {
  return Param!(F, H, Q, R)(f, h, q, r);
}

/**
   LQE filter state

   Params:
     P = parameters type
     T = input value type
*/
struct State(alias P_, T_) if (isInstanceOf!(Param, typeOf!P_) && isNumer!(P_.F, T_)) {
  /// Parameters type
  alias P = typeOf!P_;

  /// Self type
  alias Self = typeof(this);

  /// Input value type
  alias T = T_;

  /// Covariance type
  alias C = typeof(P.Q() / (asnum!(1, P.F) - P.F2()));

  /// State value
  T x = 0.0;
  /// Covariance
  C p = 0.0;

  /// Initialize using initial value
  const pure nothrow @nogc @safe
  this(const T initial, const C covariance = 0.0) {
    x = initial;
    p = covariance;
  }

  /// Evaluate filtering step
  pure nothrow @nogc @safe
  auto opCall(const ref P param, const T value) {
    enum auto one = asnum!(1, T);

    // Predict state: X0 = F * X
    const auto x0 = param.f * value;

    // Predict covariance: P0 = F^2 * P + Q
    const auto p0 = param.f2 * p + param.q;

    // S = H^2 * P0 + R
    const auto s = param.h2 * p0 + param.r;

    // K = H * P0 * S^-1
    const auto k = param.h * p0 / s;

    // P = (1 - K * H) * P0
    p = cast(C) ((one - k * param.h) * p0);

    // X = X0 + K * (X - H * X0)
    x = cast(T) (x0 + k * (x - param.h * x0));

    return x;
  }
}

/// Test LQE filter (floating-point)
nothrow @nogc unittest {
  static immutable auto param = mk!Param(0.6, 0.5, 0.2, 0.4);
  static auto state = State!(param, double)();

  assert_eq(state(param, 0.123456), 0.0658432);
  assert_eq(state(param, 1.01246), 0.5400894901287552);
  assert_eq(state(param, -5.198), -2.4904204701174825);
}

/// Test LQE filter (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(-10, 10);

  static immutable auto param = mk!Param(asfix!0.6, asfix!0.5, asfix!0.2, asfix!0.4);
  static auto state = State!(param, X)();

  assert_eq(state(param, cast(X) 0.123456), cast(X) 0.0658432);
  assert_eq(state(param, cast(X) 1.01246), cast(X) 0.54008947);
  assert_eq(state(param, cast(X) -5.198), cast(X) -2.49042048);
}

/// Test LQE filter (fixed-point)
nothrow @nogc unittest {
  alias P = fix!(0.01, 0.9);
  alias X = fix!(-10, 10);

  static immutable auto param = mk!Param(P(0.6), P(0.5), P(0.2), P(0.4));
  static auto state = State!(param, X)();

  assert_eq(state(param, cast(X) 0.123456), cast(X) 0.0658432, cast(X) 1e-5);
  assert_eq(state(param, cast(X) 1.01246), cast(X) 0.54008947, cast(X) 1e-5);
  assert_eq(state(param, cast(X) -5.198), cast(X) -2.49042048, cast(X) 1e-5);
}
