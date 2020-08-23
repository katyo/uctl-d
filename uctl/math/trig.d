/**
   ## Generic trigonometry functions

   Trigonometric functions which uses polynomial approximation and compatible with both floating point and fixed point types.

   Depending from polynomial order that functions is differ in terms of precision and speed: functions of higher order has more precision and lower speed elsewhere functions of lower order has less precision and higher speed.

   You can select best-fit function according to specific use case.

   $(TABLE_ROWS
   Approximation error vs polynomial order
   * + Polynomial order
     + Maximum error
   * + 2nd
     + ~0.056
   * + 3rd
     + ~0.020
   * + 4th
     + ~0.003
   * + 5th
     + ~0.0002)

   ![Approximation erros](trig_errs.svg)

   #### 2nd-order (quadratic) interpolation

   $(MATH sin(x) = \frac{4}{π} x - \frac{4}{π^2} x^2 = (\frac{4}{π} - \frac{4}{π^2} x) x)

   let $(MATH x = \frac{π}{2} z)

   then $(MATH sin(\frac{π}{2} z) = 2 z - z^2 = (2 - z) z)

   #### 3rd-order (cubic) interpolation

   $(MATH sin(x) = \frac{3}{π} x - \frac{4}{π^3} x^3 = (\frac{3}{π} - \frac{4}{π^3} x^2) x)

   let $(MATH x = \frac{π}{2} z)

   then $(MATH sin(\frac{π}{2} z) = \frac{3 z - z^3}{2} = \frac{(3 - z^2) z}{2} = (\frac{3}{2} - \frac{z^2}{2}) z)

   #### 4th-order interpolation

   $(MATH sin(x) = cos(x - \frac{π}{2}))

   let $(MATH x = \frac{π}{2} z)

   then $(MATH sin(z) = cos(z - 1))

   so $(MATH cos(z) = 1 - (2 - \frac{π}{4}) z^2 + (1 - \frac{π}{4}) z^4)

   or $(MATH cos(z) = 1 - ((2 - \frac{π}{4}) - (1 - \frac{π}{4}) z^2) z^2)
 */
module uctl.math.trig;

import std.math: PI, std_sin = sin, std_cos = cos;
import std.traits: isCallable, Parameters, ReturnType;

import uctl.num: isFloat, fix, asnum, isFixed;
import uctl.unit: to, Angle, rad, hpi, hasUnits;

version(unittest) {
  import uctl.unit: Val, as, deg;
  import uctl.test: assert_eq, max_abs_error, mean_sqr_error, unittests;

  mixin unittests;
}

/**
   Generic sine function using std sin
*/
auto sin(A)(const A angle) if (hasUnits!(A, Angle) && isFloat!(A.raw_t)) {
  return std_sin(angle.to!rad.raw);
}

/// Test generic sine
nothrow @nogc unittest {
  assert_eq(sin(30.0.as!deg), 0.5);
}

/**
   Generic cosine function using std cos
*/
auto cos(A)(const A angle) if (hasUnits!(A, Angle) && isFloat!(A.raw_t)) {
  return std_cos(angle.to!rad.raw);
}

/// Test generic cosine
nothrow @nogc unittest {
  assert_eq(cos(60.0.as!deg), 0.5);
}

/**
   Generic sine function for ½π units using polynomial interpolation

   Usage:
   ---
   auto result = sin!order(angle);
   // where order can be 2, 3, 4 or 5
   ---

   See_Also: [cos]
*/
auto sin(uint N, A)(const A angle) if (N >= 2 && N <= 5 && hasUnits!(A, Angle) && (isFloat!(A.raw_t) || isFixed!(A.raw_t))) {
  alias T = A.raw_t;
  alias U = A.units;

  static if (isFloat!T) {
    alias Z = T;
    alias R = T;
  }
  static if (isFixed!T) {
    alias Z = fix!(-4, 4);
    alias R = fix!(-1, 1);
  }
  alias C(real v) = asnum!(v, Z);

  auto x = angle.to!hpi.raw;

  static if (N == 4) {
    auto x_ = C!1 - x; // sin -> cos
  } else {
    auto x_ = x;
  }

  auto z = cast(Z) (x_ % C!4); // x %= 2π

  auto n = false;

  static if (N == 2) { // 2nd-order
    if (z < cast(Z) 0) { // z < 0
      n = true;
      z = -z;
    }

    if (z > cast(Z) 2) { // x > π
      n = !n;
      z = cast(Z) (z - C!2); // x -= π
    }

    auto y = cast(R) ((C!2 - z) * z);

    return cast(R) (n ? -y : y);
  }

  static if (N == 3) { // 3rd-order
    /*
      Qsinx: sin(x) = 3/%pi * x - 4/%pi^3 * x^3$
      Qsinz: Qsinx, x = z * %pi/2$
      factor(Qsinz);
    */
    if (z < cast(Z) 0) { // x < 0
      n = true;
      z = -z;
    }

    if (z > cast(Z) 2) { // x > π
      n = !n;
      z = cast(Z) (z - C!2); // x -= π
    }

    if (z > cast(Z) 1) { // x > π/2
      z = cast(Z) (C!2 - z); // x = π - x
    }

    if (n) {
      z = -z;
    }

    return cast(R) ((C!1.5 - C!0.5 * z * z) * z);
  }

  static if (N == 4) { // 4th-order
    /*
      cos(z) = 1 - ((2 - π/4) - (1 - π/4) * z^2) * z^2
    */
    enum auto a = 1.0;
    enum auto b = 2.0 - PI/4.0;
    enum auto c = 1.0 - PI/4.0;

    if (z < cast(Z) 0) { // x < 0
      z = -z; // x = -x
    }

    if (z > cast(Z) 1 && z < cast(Z) 3) { // x > π/2 && x < 3π/2
      n = true; // regate result
    }

    z = cast (Z) (z % C!2); // x %= 2π

    if (z > cast(Z) 1) { // x < π/2
      z = cast(Z) (C!2 - z); // x = π - x
    }

    auto z2 = z * z;

    auto y = cast(R) (C!a - (C!b - C!c * z2) * z2);

    return cast(R) (n ? -y : y);
  }

  static if (N == 5) { // 5th-order
    enum real a = 4.0 * (3.0 / PI - 9.0 / 16.0);
    enum real b = 2.0 * a - 5.0 / 2.0;
    enum real c = a - 3.0 / 2.0;

    if (z < cast(Z) 0) { // x < 0
      n = true;
      z = -z;
    }

    if (z > cast(Z) 2) { // x > π
      n = !n;
      z = cast(Z) (z - C!2); // x -= π
    }

    if (z > cast(Z) 1) { // x > π/2
      z = cast(Z) (C!2 - z); // x = π - x
    }

    if (n) {
      z = -z;
    }

    auto z2 = z * z;

    return cast(R) ((C!a - (C!b - C!c * z2) * z2) * z);
  }
}

/// Test sine for floating-point
nothrow @nogc unittest {
  void test_sign(uint N)(double max_err) {
    assert_eq(sin!N(30.0.as!deg), 0.5, max_err);
    assert_eq(sin!N(150.0.as!deg), 0.5, max_err);
    assert_eq(sin!N(-30.0.as!deg), -0.5, max_err);
    assert_eq(sin!N(-150.0.as!deg), -0.5, max_err);
  }

  test_sign!2(0.056009);
  test_sign!3(0.020017);
  test_sign!4(0.002787);
  test_sign!5(0.000193);

  template max_err(uint N) {
    auto max_err =
      max_abs_error!((double x) => sin!N(x.as!rad),
                     (double x) => sin(x.as!rad))
      (-10*PI, 10*PI, 1000);
  }

  assert_eq(max_err!2, 0.056009, 1e-6);
  assert_eq(max_err!3, 0.020017, 1e-6);
  assert_eq(max_err!4, 0.002787, 1e-6);
  assert_eq(max_err!5, 0.000193, 1e-6);
}

/// Test sine for fixed-point
nothrow @nogc unittest {
  template max_err(uint N) {
    alias X = fix!(-10*PI, 10*PI);
    auto max_err =
      max_abs_error!((double x) => cast(double) sin!N(X(x).as!rad),
                     (double x) => sin(x.as!rad))
      (-10*PI, 10*PI, 1000);
  }

  assert_eq(max_err!2, 0.056009, 1e-6);
  assert_eq(max_err!3, 0.020017, 1e-6);
  assert_eq(max_err!4, 0.002787, 1e-6);
  assert_eq(max_err!5, 0.000193, 1e-6);
}

/**
   Generic cosine function for ½π units using polynomial interpolation

   Usage:
   ---
   auto result = cos!order(angle);
   // where order can be 2, 3, 4 or 5
   ---

   See_Also: [sin]
 */
auto cos(uint N, A)(const A angle) if (N >= 2 && N <= 5 && hasUnits!(A, Angle) && (isFloat!(A.raw_t) || isFixed!(A.raw_t))) {
  return sin!N(asnum!(1, A.raw_t).as!hpi - angle.to!hpi);
}

/// Test cosine for floating-point
nothrow @nogc unittest {
  template max_err(uint N) {
    auto max_err =
      max_abs_error!((double x) => cos!N(x.as!rad),
                     (double x) => cos(x.as!rad))
      (-10*PI, 10*PI, 1000);
  }

  assert_eq(max_err!2, 0.056009, 1e-6);
  assert_eq(max_err!3, 0.020017, 1e-6);
  assert_eq(max_err!4, 0.002787, 1e-6);
  assert_eq(max_err!5, 0.000193, 1e-6);
}

/// Test cosine for fixed-point
nothrow @nogc unittest {
  template max_err(uint N) {
    alias X = fix!(-10*PI, 10*PI);
    auto max_err =
      max_abs_error!((double x) => cast(double) cos!N(X(x).as!rad),
                     (double x) => cos(x.as!rad))
      (-10*PI, 10*PI, 1000);
  }

  assert_eq(max_err!2, 0.056009, 1e-6);
  assert_eq(max_err!3, 0.020017, 1e-6);
  assert_eq(max_err!4, 0.002787, 1e-6);
  assert_eq(max_err!5, 0.000193, 1e-6);
}
