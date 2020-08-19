/*!
  ## LQE (Kalman) filter

  This module implements **Linear Quadratic Estimation** (LQE) filter which also known as Kalman filter.

  Filter has four parameters:

  $(LIST
    * `F` - factor of actual value to previous actual value
    * `H` - factor of measured value to actual value
    * `Q` - measurement noise
    * `R` - environment noise
  )

  Filter consists of two stages:

  $(ORDERED_LIST
    * Prediction
    $(LIST
      * Predict state as _X0 = F * X_
      * Predict covariance _P0 = F^2 * P + Q_
    )

    * Correction
    $(LIST
      * Calculate gain as _K = H * P0 / (H^2 * P0 + R)_
      * Calculate covariance as _P = (1 - K * H) * P0_
      * Calculate state as _X = X0 + K * (X - H * X0)_
    )
  )

  See_Also:
    [Kalman filter](https://en.wikipedia.org/wiki/Kalman_filter) article.
*/
module uctl.filt.lqe;

import std.traits: isInstanceOf;
import uctl.fix: isNumer, isFixed, fix, asfix;

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
struct Param(F_, H_, Q_, R_) if (isNumer!F_ && isNumer!H_ && isNumer!Q_ && isNumer!R_) {
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
auto param_from(F, H, Q, R)(F f, H h, Q q, R r) if (isNumer!F && isNumer!H && isNumer!Q && isNumer!R) {
  return Param!(F, H, Q, R)(f, h, q, r);
}

template fix_sqrt_t(T) if (isFixed!T) {
  import std.math: sqrt;
  static assert(T.isntneg, "Square root is undefined for negative values.");
  alias fix_sqrt_t = fix!(sqrt(T.rmin), sqrt(T.rmax));
}

/**
   LQE filter state

   Params:
     P = parameters type
     T = input value type
*/
struct State(alias P, T) if (isInstanceOf!(Param, P)) {
  /// Result type
  alias R = T;

  /// Covariance type
  static if (isFixed!T) {
    //alias C = fix!(-1, 1);
    alias Cq = typeof((P.F2() * P.F2() - asfix!2 * P.F2() + asfix!1) * P.R() * P.R() + (asfix!2 * P.F2() + asfix!2) * P.H2() * P.Q() * P.R() + P.H2() * P.H2() * P.Q());
    alias Cp = typeof((fix_sqrt_t!Cq() + (P.F2() - asfix!1) * P.R() - P.H2() * P.Q()) / (asfix!2 * P.F2() * P.H2()));
    alias C = fix!(Cp.rmin*2, Cp.rmax*2);
    //pragma(msg, C.stringof);
  } else {
    alias C = T;
  }

  /// State value
  R x = 0;
  /// Covariance
  C p = 0;

  auto apply(ref const P param, const T value) {
    static if (isFixed!T) {
      enum auto one = asfix!1;
    } else {
      enum auto one = 1;
    }

    // Predict state: X0 = F * X
    auto x0 = param.f * value;

    // Predict covariance: P0 = F^2 * P + Q
    auto p0 = param.f2 * p + param.q;

    // S = H^2 * P0 + R
    auto s = param.h2 * p0 + param.r;

    // K = H * P0 * S^-1
    auto k = param.h * p0 / s;

    // P = (1 - K * H) * P0
    p = cast(C) ((one - k * param.h) * p0);

    // X = X0 + K * (X - H * X0)
    x = cast(T) (x0 + k * (x - param.h * x0));

    return x;
  }
}

/// Test LQE filter (floating-point)
nothrow @nogc unittest {
  static immutable auto param = param_from(0.6, 0.5, 0.2, 0.4);
  static auto state = State!(typeof(param), double)();

  assert_eq(state.apply(param, 0.123456), 0.0658432);
  assert_eq(state.apply(param, 1.01246), 0.54008947, 1e-7);
  assert_eq(state.apply(param, -5.198), -2.49042048, 1e-8);
}

/// Test LQE filter (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(-10, 10);

  static immutable auto param = param_from(asfix!0.6, asfix!0.5, asfix!0.2, asfix!0.4);
  static auto state = State!(typeof(param), X)();

  assert_eq(state.apply(param, cast(X) 0.123456), cast(X) 0.0658432, cast(X) 1e-8);
  assert_eq(state.apply(param, cast(X) 1.01246), cast(X) 0.54008947, cast(X) 1e-8);
  assert_eq(state.apply(param, cast(X) -5.198), cast(X) -2.49042048, cast(X) 1e-8);
}
