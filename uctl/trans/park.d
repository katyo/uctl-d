/**
  ## DQZ (Park) transformation

  The implementation of Direct-Quadrature-Zero (DQZ) transformations which also known as Park transformations.

  See_Also: [DQZ transformation](https://en.wikipedia.org/wiki/Direct-quadrature-zero_transformation) wikipedia article.
*/
module uctl.trans.park;

import std.traits: isInstanceOf;
import std.math: sqrt;
import uctl.num: isNumer, asnum;
import uctl.unit: hasUnits, Angle, as, to, qrev;
import uctl.math.trig: isSinOrCos;
import uctl.trans.clarke: AlphaBeta, mk;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.num: fix;
  import uctl.unit: deg;
  import uctl.math.trig: sin, cos;

  mixin unittests;
}

/**
   Create DQZ vector from components

   Unlike the constructor this function allow inferring type of struct parameter.
*/
DQ!T mk(alias R, T)(const T d, const T q) if (isNumer!T && __traits(isSame, DQ, R)) {
  return DQ!T(d, q);
}

/// The DQZ vector
struct DQ(T) if (isNumer!T) {
  /// The value of D component
  T d = 0;

  /// The value of Q component
  T q = 0;

  /// Create DQ vector from components
  this(const T d_, const T q_) {
    d = d_;
    q = q_;
  }

  /**
   Transform rotating DQ coordinates to stationary α-β coordinates

   The inverted Park transformation

   $(MATH α = d cos(θ) - q sin(θ)),
   $(MATH β = q cos(θ) + d sin(θ))
   */
  pure nothrow @nogc @safe
  auto to(alias R, alias S, A)(const A theta) const if (__traits(isSame, AlphaBeta, R) &&
                                                        hasUnits!(A, Angle) &&
                                                        isSinOrCos!(S, A) &&
                                                        isNumer!(T, A.raw_t)) {
    const auto sin_theta = S(theta);
    const auto cos_theta = S(asnum!(1, T).as!qrev.to!(A.units) - theta); // cos(a) == sin(pi/2-a)

    const auto alpha = d * cos_theta - q * sin_theta;
    const auto beta = q * cos_theta + d * sin_theta;

    return AlphaBeta!T(cast(T) alpha, cast(T) beta);
  }
}

// Test direct Park transformation (floating-point)
nothrow @nogc unittest {
  auto a = mk!AlphaBeta(2.5, -1.25);
  auto t = 30.0.as!deg;

  auto b = a.to!(DQ, sin!5)(t);

  assert_eq(b.d, 1.540688649, 1e-6);
  assert_eq(b.q, -2.33235538, 1e-6);
}

// Test direct Park transformation (fixed-point)
nothrow @nogc unittest {
  alias A = fix!(-200, 200);
  alias X = fix!(-5, 5);

  auto a = mk!AlphaBeta(X(2.5), X(-1.25));
  auto t = A(30.0).as!deg;

  auto b = a.to!(DQ, sin!5)(t);

  assert_eq(b.d, X(1.540688649), X(1e-8));
  assert_eq(b.q, X(-2.33235538), X(1e-8));
}

// Test inverted Park transformation (floating-point)
nothrow @nogc unittest {
  auto a = mk!DQ(1.540688649, -2.33235538);
  auto t = 30.0.as!deg;

  auto b = a.to!(AlphaBeta, sin!5)(t);

  assert_eq(b.alpha, 2.500353001, 1e-6);
  assert_eq(b.beta, -1.250176512, 1e-6);
}

// Test inverted Park transformation (fixed-point)
nothrow @nogc unittest {
  alias A = fix!(-200, 200);
  alias X = fix!(-5, 5);

  auto a = mk!DQ(X(1.540688649), X(-2.33235538));
  auto t = A(30.0).as!deg;

  auto b = a.to!(AlphaBeta, sin!5)(t);

  assert_eq(b.alpha, X(2.500353001), X(1e-8));
  assert_eq(b.beta, X(-1.250176512), X(1e-8));
}
