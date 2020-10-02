/**
  ## α-β (Clarke) transformations

  The implementation of α-β transformations which also known as the Clarke transformations.

  See_Also: [αβ transformation](https://en.wikipedia.org/wiki/Alpha-beta_transformation) wikipedia article.
*/
module uctl.trans.clarke;

import std.traits: isInstanceOf;
import std.math: sqrt;
import uctl.num: isNumer, asnum;
import uctl.unit: hasUnits, Angle, as, to, qrev;
import uctl.math.trig: isSinOrCos;
import uctl.trans.park: DQ;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.num: fix;

  mixin unittests;
}

/**
   Create α-β vector from components

   Unlike the constructor this function allow inferring type of struct parameter.
*/
AlphaBeta!T mk(alias R, T)(const T alpha, const T beta) if (isNumer!T && __traits(isSame, AlphaBeta, R)) {
  return AlphaBeta!T(alpha, beta);
}

/// The α-β vector
struct AlphaBeta(T) if (isNumer!T) {
  /// The value of α component
  T alpha = 0;
  /// The value of β component
  T beta = 0;

  /// Create vector from components
  this(const T alpha_, const T beta_) {
    alpha = alpha_;
    beta = beta_;
  }

  /**
     Transform α-β vector to ABC vector

     The inverted Clarke transformation

     $(MATH A = α),
     $(MATH B = \frac{- α + \sqrt{3} β}{2}),
     $(MATH C = \frac{- α -\sqrt{3} β}{2})
  */
  const pure nothrow @nogc @safe
  auto to(alias R)() if (__traits(isSame, AB, R) || __traits(isSame, ABC, R)) {
    // a = α
    const auto a = alpha;

    // t1 = -α / 2
    const auto t1 = -a / asnum!(2, T);

    // t2 = β * sqrt(3) / 2
    const auto t2 = beta * asnum!(sqrt(3.0) / 2, T);

    // b = t1 + t2
    const auto b = cast(T) (t1 + t2);

    static if (__traits(isSame, ABC, R)) {
      // c = t1 - t2
      const auto c = cast(T) (t1 - t2);

      return ABC!T(a, b, c);
    } else {
      return AB!T(a, b);
    }
  }

  /**
     Transform α-β vector to ABC vector

     The inverted Clarke transformation

     $(MATH A = α),
     $(MATH B = \frac{- α + \sqrt{3} β}{2}),
     $(MATH C = \frac{- α -\sqrt{3} β}{2})

     See_Also: [AlphaBeta.to]
  */
  pure nothrow @nogc @safe
  R opCast(R)() const if (isInstanceOf!(ABC, R) || isInstanceOf!(AB, R)) {
    static if (isInstanceOf!(ABC, R)) {
      return to!ABC;
    } else {
      return to!AB;
    }
  }

  /**
     Transform stationary α-β coordinates to rotating DQ

     The direct Park transformation

     $(MATH d = α cos(θ) + β sin(θ)),
     $(MATH q = β cos(θ) - α sin(θ))
  */
  pure nothrow @nogc @safe
  auto to(alias R, alias S, A)(const A theta) const if (__traits(isSame, DQ, R) &&
                                                        hasUnits!(A, Angle) &&
                                                        isSinOrCos!(S, A) &&
                                                        isNumer!(T, A.raw_t)) {
    const auto sin_theta = S(theta);
    const auto cos_theta = S(asnum!(1, T).as!qrev.to!(A.units) - theta); // cos(a) == sin(pi/2-a)

    const auto d = alpha * cos_theta + beta * sin_theta;
    const auto q = beta * cos_theta - alpha * sin_theta;

    return DQ!T(cast(T) d, cast(T) q);
  }
}

/// Test inverted Clarke transformation (floating-point)
nothrow @nogc unittest {
  auto a = mk!AlphaBeta(1.25, -0.85);

  // transform with to()
  auto b = a.to!ABC;

  assert_eq(b.a, 1.25);
  assert_eq(b.b, -1.361121595, 1e-8);
  assert_eq(b.c, 0.1111215949, 1e-8);

  auto c = a.to!AB;

  assert_eq(c.a, 1.25);
  assert_eq(c.b, -1.361121595, 1e-8);

  // transform using cast
  auto d = cast(ABC!double) a;

  assert_eq(d.a, 1.25);
  assert_eq(d.b, -1.361121595, 1e-8);
  assert_eq(d.c, 0.1111215949, 1e-8);

  auto e = cast(AB!double) a;

  assert_eq(e.a, 1.25);
  assert_eq(e.b, -1.361121595, 1e-8);
}

/// Test inverted Clarke transformation (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(-5, 5);

  auto a = mk!AlphaBeta(X(1.25), X(-0.85));
  auto b = a.to!ABC;
  auto c = a.to!AB;

  assert_eq(b.a, X(1.25));
  assert_eq(b.b, X(-1.361121595));
  assert_eq(b.c, X(0.1111215949));

  assert_eq(c.a, X(1.25));
  assert_eq(c.b, X(-1.361121595));
}

/**
   Create ABC vector from components

   Unlike the constructor this function allow inferring type of struct parameter.
*/
ABC!T mk(alias R, T)(const T a, const T b, const T c) if (isNumer!T && __traits(isSame, ABC, R)) {
  return ABC!T(a, b, c);
}

/// The ABC vector
struct ABC(T) if (isNumer!T) {
  /// The value of A component
  T a = 0;
  /// The value of B component
  T b = 0;
  /// The value of C component
  T c = 0;

  /// Create ABC vector from components
  this(const T a_, const T b_, const T c_) {
    a = a_;
    b = b_;
    c = c_;
  }

  /**
     Transform ABC to α-β

     The direct Clarke transformation

     $(MATH α = A),
     $(MATH β = \frac{A + 2 B}{\sqrt{3}})
  */
  pure nothrow @nogc @safe
  auto to(alias R)() const if (__traits(isSame, AlphaBeta, R)) {
    /* α = a */
    const auto alpha = a;

    /* β = (a + 2 * b) / sqrt(3) */
    const auto beta = cast(T) ((a + b * asnum!(2.0, T)) * asnum!(1.0 / sqrt(3.0), T));

    return AlphaBeta!T(alpha, beta);
  }

  /**
     Transform ABC to α-β

     The direct Clarke transformation

     $(MATH α = A),
     $(MATH β = \frac{A + 2 B}{\sqrt{3}})

     See_Also: [ABC.to]
   */
  pure nothrow @nogc @safe
  R opCast(R)() const if (isInstanceOf!(AlphaBeta, R)) {
    return to!AlphaBeta;
  }

  /// Cast to ABC vector without C component
  pure nothrow @nogc @safe
  auto to(alias R)() const if (__traits(isSame, AB, R)) {
    return AB!T(a, b);
  }

  /// Cast to ABC vector without C component
  pure nothrow @nogc @safe
  R opCast(R)() const if (isInstanceOf!(AB, R)) {
    return to!AB;
  }
}

// Test direct Clarke transformation (floating-point)
nothrow @nogc unittest {
  const auto a = mk!ABC(1.25, -1.361121595, 0.1111215949);

  // transform with to()
  auto b = a.to!AlphaBeta;

  assert_eq(b.alpha, 1.25);
  assert_eq(b.beta, -0.85, 1e-8);

  // transform using cast
  auto c = cast(AlphaBeta!double) a;

  assert_eq(c.alpha, 1.25);
  assert_eq(c.beta, -0.85, 1e-8);
}

// Test direct Clarke transformation (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(-5, 5);

  const auto a = mk!ABC(X(1.25), X(-1.361121595), X(0.1111215949));

  // transform with to()
  auto b = a.to!AlphaBeta;

  assert_eq(b.alpha, X(1.25));
  assert_eq(b.beta, X(-0.85), X(1e-8));

  // transform using cast
  auto c = cast(AlphaBeta!X) a;

  assert_eq(c.alpha, X(1.25));
  assert_eq(c.beta, X(-0.85), X(1e-8));
}

/**
   Create ABC vector from components

   Unlike the constructor this function allow inferring type of struct parameter.
*/
AB!T mk(alias R, T)(const T a, const T b) if (isNumer!T && __traits(isSame, AB, R)) {
  return AB!T(a, b);
}

/**
   Create ABC vector from components

   Unlike the constructor this function allow inferring type of struct parameter.
*/
AB!T mk(alias R, T)(const T a, const T b, const T c) if (isNumer!T && __traits(isSame, AB, R)) {
  return AB!T(a, b);
}

/// The ABC vector without C component
struct AB(T) if (isNumer!T) {
  /// The value of A component
  T a = 0;
  /// The value of B component
  T b = 0;

  /// Create ABC vector from components
  this(const T a_, const T b_) {
    a = a_;
    b = b_;
  }

  /// Create ABC vector from components
  this(const T a_, const T b_, const T c_) {
    a = a_;
    b = b_;
  }

  /**
     Transform ABC to α-β

     The direct Clarke transformation

     $(MATH α = A),
     $(MATH β = \frac{A + 2 B}{\sqrt{3}})
  */
  pure nothrow @nogc @safe
  auto to(alias R)() const if (__traits(isSame, AlphaBeta, R)) {
    /* α = a */
    auto alpha = a;

    /* β = (a + 2 * b) / sqrt(3) */
    auto beta = cast(T) ((a + b * asnum!(2.0, T)) * asnum!(1.0 / sqrt(3.0), T));

    return AlphaBeta!T(alpha, beta);
  }

  /**
     Transform ABC to α-β

     The direct Clarke transformation

     $(MATH α = A),
     $(MATH β = \frac{A + 2 B}{\sqrt{3}})

     See_Also: [ABC.to]
  */
  pure nothrow @nogc @safe
  R opCast(R)() const if (isInstanceOf!(AlphaBeta, R)) {
    return to!AlphaBeta;
  }

  /// Cast to ABC vector with C component
  pure nothrow @nogc @safe
  auto to(alias R)() const if (__traits(isSame, ABC, R)) {
    return to!AlphaBeta.to!ABC;
  }

  /// Cast to ABC vector with C component
  pure nothrow @nogc @safe
  R opCast(R)() const if (isInstanceOf!(ABC, R)) {
    return to!ABC;
  }
}

// Test direct Clarke transformation (floating-point)
nothrow @nogc unittest {
  const auto a = AB!double(1.25, -1.361121595);

  // transform with to()
  auto b = a.to!AlphaBeta;

  assert_eq(b.alpha, 1.25);
  assert_eq(b.beta, -0.85, 1e-8);

  // transform using cast
  auto c = cast(AlphaBeta!double) a;

  assert_eq(c.alpha, 1.25);
  assert_eq(c.beta, -0.85, 1e-8);
}

// Test direct Clarke transformation (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(-5, 5);

  const auto a = AB!X(X(1.25), X(-1.361121595));

  // transform with to()
  auto b = a.to!AlphaBeta;

  assert_eq(b.alpha, X(1.25));
  assert_eq(b.beta, X(-0.85), X(1e-8));

  // transform using cast
  auto c = cast(AlphaBeta!X) a;

  assert_eq(c.alpha, X(1.25));
  assert_eq(c.beta, X(-0.85), X(1e-8));
}
