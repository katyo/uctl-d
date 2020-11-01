/**
   ## Generic Chebyshev polynomial approximation

   Helpers for Chebyshev polynomial approximation of math functions in given range.

   You can either fit function to get polynome coefficients or generate approximation directly.

   ### Examples

   #### Sinus approximation

   ![Sinus approximation errors](cheby_sin.svg)

   #### Logarithm approximation

   ![log2(x) approximation errors](cheby_log2.svg)

   #### Exponent approximation

   ![2^x approximation errors](cheby_exp2.svg)

   #### Square root approximation

   ![sqrt approximation errors](cheby_sqrt.svg)

   See_Also:
   [Chebyshev polynomials](https://en.wikipedia.org/wiki/Chebyshev_polynomials) wikipedia article.
 */
module uctl.math.cheby;

import std.math: PI, cos;
import std.traits: Unqual, isCallable, Parameters, ReturnType, isArray;
import std.range: ElementType;
import uctl.num: isNumer, asnum;

version(unittest) {
  import uctl.test: assert_eq, max_abs_error, mean_sqr_error, unittests;

  mixin unittests;
}

private auto space(uint N)() {
  real[N] u;

  foreach (i; 0..N) {
    u[i] = -cos(PI * (real(i) + 0.5) / real(N));
  }

  return u;
}

private auto matrix(uint N, uint L)(real[L] u) {
  real[N][L] T;

  foreach (i; 0..L) {
    T[0][i] = 1.0;
    T[1][i] = u[i];
  }

  foreach (j; 2..N) {
    foreach (i; 0..L) {
      T[j][i] = 2.0 * u[i] * T[j-1][i] - T[j-2][i];
    }
  }

  return T;
}

auto fit(alias F, real a, real b, uint D)() if (a < b && isCallable!F && Parameters!F.length == 1 && isNumer!(Parameters!F[0]) && isNumer!(ReturnType!F)) {
  enum N = D + 1;
  const u = space!N;

  real[N] x;
  real[N] y;

  enum c = 0.5 * (b + a);
  enum m = 0.5 * (b - a);

  foreach (i; 0..N) {
    x[i] = u[i] * m + c;
    y[i] = F(x[i]);
  }

  const T = matrix!N(u);

  real k = 2.0 / real(N);
  real[N] r;

  foreach (j; 0..N) {
    r[j] = 0.0;
    foreach (i; 0..N) {
      r[j] += k * y[i] * T[j][i];
    }
  }

  r[0] *= 0.5;

  return r;
}

private template val(real x) {
  enum val = x.stringof;
}

private template nth(uint i) {
  enum ii = int(i);
  enum nth = ii.stringof;
}

// Chebyshev polynomial approximation
private template approx(real a, real b, T, alias C) if (isNumer!T) {
  enum N = C.length;
  enum D = N - 1;

  enum c = 0.5 * (b + a);
  enum m = 0.5 * (b - a);
  enum inv_m = 1.0 / m;

  static foreach(i; 0..N) {
    mixin("enum c" ~ nth!i ~ " = asnum!(" ~ val!(cast(real) C[i]) ~ ", T);");
  }

  //pure nothrow @nogc @safe
  auto approx(X)(X x) if (isNumer!(X, T)) {
    const u = (x - asnum!(c, T)) * asnum!(inv_m, T);

    const T0 = asnum!(1, T);
    const y0 = c0;

    static if (N > 1) {
      const y1 = y0 + u * c1;
      const T1 = u;
    }

    static if (N > 2) {
      const u2 = asnum!(2, T) * u;
    }

    static foreach (i; 2..N) {
      mixin("const T" ~ nth!i ~ " = u2 * T" ~ nth!(i - 1) ~ " - T" ~ nth!(i - 2) ~ ";");
      mixin("const y" ~ nth!i ~ " = y" ~ nth!(i - 1) ~ " + T" ~ nth!i ~ " * c" ~ nth!i ~ ";");
    }

    mixin("return cast(Unqual!(typeof(y" ~ nth!(N - 1) ~ "))) y" ~ nth!(N - 1) ~ ";");
  }
}

/// Tag for getting Chebyshev approximation
struct Cheby {}

/// Generate coefficients for function approximation by fitting Chebyshev polynom in range
template mk(alias C, alias F, real a, real b, uint D) if (__traits(isSame, C, Cheby) && isCallable!F && Parameters!F.length == 1 && isNumer!(Parameters!F[0]) && isNumer!(ReturnType!F)) {
  enum mk = fit!(F, a, b, D);
}

/// Test Chebyshev sin fit coefficients (floating-point, 2rd)
nothrow @nogc unittest {
  import std.math: sin;

  enum xsin = mk!(Cheby, sin, 0, PI*0.5, 2);

  assert_eq(cast(float) xsin[0], 0.602201760f);
  assert_eq(cast(float) xsin[1], 0.513518274f);
  assert_eq(cast(float) xsin[2], -0.104905032f);
}

/// Function approximation using Chebyshev polynom coeeficients in range
template mk(alias C, real a, real b, T, alias c) if (__traits(isSame, C, Cheby) && isNumer!T && !is(c) && isArray!(typeof(c)) && isNumer!(ElementType!(typeof(c)))) {
  alias mk = approx!(a, b, T, c);
}

/// Test Chebyshev sin with predefined coefficients (floating-point, 2rd)
nothrow @nogc unittest {
  import std.math: sin;

  alias xsin = mk!(Cheby, 0, PI*0.5, float, [0.602201760, 0.513518274, -0.104905032]);

  enum pi = float(PI);

  assert_eq(xsin(0f), -0.016220979f);
  assert_eq(xsin(pi*1f/6f), 0.512622118f);
  assert_eq(xsin(pi*1f/4f), 0.707107008f);
  assert_eq(xsin(pi*1f/3f), 0.854967356f);
  assert_eq(xsin(pi*1f/2f), 1.010815024f);

  assert_eq(max_abs_error!(function (float x) => sin(x),
                           function (float x) => xsin(x))(0.0, PI*0.5, 64),
            0.016220979f);
  assert_eq(mean_sqr_error!(function (float x) => sin(x),
                            function (float x) => xsin(x))(0.0, PI*0.5, 64),
            9.55991636146791279e-05f);
}

/// Function approximation by fitting Chebyshev polynom in range
template mk(alias C, alias F, real a, real b, uint D, T) if (__traits(isSame, C, Cheby) && isCallable!F && Parameters!F.length == 1 && isNumer!(Parameters!F[0]) && isNumer!(ReturnType!F) && isNumer!T) {
  enum c = fit!(F, a, b, D);
  alias mk = approx!(a, b, T, c);
}

/// Test Chebyshev sin fit (floating-point, 2rd)
nothrow @nogc unittest {
  import std.math: sin;

  alias xsin = mk!(Cheby, sin, 0, PI*0.5, 2, float);

  enum pi = float(PI);

  assert_eq(xsin(0f), -0.016220979f);
  assert_eq(xsin(pi*1f/6f), 0.512622118f);
  assert_eq(xsin(pi*1f/4f), 0.707107008f);
  assert_eq(xsin(pi*1f/3f), 0.854967356f);
  assert_eq(xsin(pi*1f/2f), 1.010815024f);

  assert_eq(max_abs_error!(function (float x) => sin(x),
                           function (float x) => xsin(x))(0.0, PI*0.5, 64),
            0.016220979f);
  assert_eq(mean_sqr_error!(function (float x) => sin(x),
                            function (float x) => xsin(x))(0.0, PI*0.5, 64),
            9.55991636146791279e-05f);
}

/// Test Chebyshev sin fit (floating-point, 3th)
nothrow @nogc unittest {
  import std.math: sin;

  alias xsin = mk!(Cheby, sin, 0, PI*0.5, 3, float);

  enum pi = float(PI);

  assert_eq(xsin(0f), -0.001130653f);
  assert_eq(xsin(pi*1f/6f), 0.499727666f);
  assert_eq(xsin(pi*1f/4f), 0.705733955f);
  assert_eq(xsin(pi*1f/3f), 0.865723073f);
  assert_eq(xsin(pi*1f/2f), 0.998442709f);

  assert_eq(max_abs_error!(function (float x) => sin(x),
                           function (float x) => xsin(x))(0.0, PI*0.5, 64),
            0.001557291f);
  assert_eq(mean_sqr_error!(function (float x) => sin(x),
                            function (float x) => xsin(x))(0.0, PI*0.5, 64),
            9.41874418458610307e-07f);
}

/// Test Chebyshev sin fit (floating-point, 4th)
nothrow @nogc unittest {
  import std.math: sin;

  alias xsin = mk!(Cheby, sin, 0, PI*0.5, 4, float);

  enum pi = float(PI);

  assert_eq(xsin(0f), 0.000121317f);
  assert_eq(xsin(pi*1f/6f), 0.500111818f);
  assert_eq(xsin(pi*1f/4f), 0.707106769f);
  assert_eq(xsin(pi*1f/3f), 0.865923107f);
  assert_eq(xsin(pi*1f/2f), 0.999908149f);

  assert_eq(max_abs_error!(function (float x) => sin(x),
                           function (float x) => xsin(x))(0.0, PI*0.5, 64),
            0.000121317f);
  assert_eq(mean_sqr_error!(function (float x) => sin(x),
                            function (float x) => xsin(x))(0.0, PI*0.5, 64),
            5.8926024060212967e-09f);
}

/// Test Chebyshev sin fit (floating-point, 5th)
nothrow @nogc unittest {
  import std.math: sin;

  alias xsin = mk!(Cheby, sin, 0, PI*0.5, 5, float);

  enum pi = float(PI);

  assert_eq(xsin(0f), 6.989e-06f);
  assert_eq(xsin(pi*1f/6f), 0.500003159f);
  assert_eq(xsin(pi*1f/4f), 0.707099676f);
  assert_eq(xsin(pi*1f/3f), 0.866028726f);
  assert_eq(xsin(pi*1f/2f), 1.000008345f);

  assert_eq(max_abs_error!(function (float x) => sin(x),
                           function (float x) => xsin(x))(0.0, PI*0.5, 64),
            0.000008345f);
  assert_eq(mean_sqr_error!(function (float x) => sin(x),
                            function (float x) => xsin(x))(0.0, PI*0.5, 64),
            2.55523293496429105e-11f);
}

/// Test Chebyshev sin fit (fixed-point, 2nd)
nothrow @nogc unittest {
  import std.math: sin;
  import uctl.num: fix;

  alias X = fix!(0, PI);
  alias Y = fix!(-3.67252, 4.74355);

  alias xsin = mk!(Cheby, sin, 0, PI*0.5, 2, X);

  enum pi = PI;

  assert_eq(xsin(X(0)), Y(-0.01622100174));
  assert_eq(xsin(X(pi*1f/6f)), Y(0.5126221105));
  assert_eq(xsin(X(pi*1f/4f)), Y(0.7071070001));
  assert_eq(xsin(X(pi*1f/3f)), Y(0.85496744));
  assert_eq(xsin(X(pi*1f/2f)), Y(1.010814998));

  assert_eq(max_abs_error!(function (double x) => sin(x),
                           function (double x) => cast(double) xsin(cast(X) x))(0.0, PI*0.5, 64),
            0.0162210017442703247);
  assert_eq(mean_sqr_error!(function (double x) => sin(x),
                            function (double x) => cast(double) xsin(cast(X) x))(0.0, PI*0.5, 64),
            9.56006554951649217e-05);
}

/// Test Chebyshev sin fit (fixed-point, 5th)
nothrow @nogc unittest {
  import std.math: sin;
  import uctl.num: fix;

  alias X = fix!(0, PI);
  alias Y = fix!(-3.67252, 4.74355);

  alias xsin = mk!(Cheby, sin, 0, PI*0.5, 5, X);

  enum pi = PI;

  assert_eq(xsin(X(0)), Y(6.981194019e-06));
  assert_eq(xsin(X(pi*1f/6f)), Y(0.5000031851));
  assert_eq(xsin(X(pi*1f/4f)), Y(0.7070996426));
  assert_eq(xsin(X(pi*1f/3f)), Y(0.8660286553));
  assert_eq(xsin(X(pi*1f/2f)), Y(1.0000083));

  assert_eq(max_abs_error!(function (double x) => sin(x),
                           function (double x) => cast(double) xsin(cast(X) x))(0.0, PI*0.5, 64),
            8.29994678497314453e-06);
  assert_eq(mean_sqr_error!(function (double x) => sin(x),
                            function (double x) => cast(double) xsin(cast(X) x))(0.0, PI*0.5, 64),
            2.54778471053421005e-11);
}

/// Test Chebyshev exp2 fit (floating-point, 2nd)
nothrow @nogc unittest {
  import std.math: exp2;

  alias xexp2 = mk!(Cheby, exp2, -1, 1, 2, float);

  assert_eq(xexp2(-1f), 0.511991978);
  assert_eq(xexp2(1f), 1.983056068);

  enum max_err = max_abs_error!(function (float x) => cast(float) exp2(x),
                                function (float x) => xexp2(x))(-1.0, 1.0, 64);
  assert_eq(max_err, 0.016944);
  enum mean_err = mean_sqr_error!(function (float x) => exp2(x),
                                  function (float x) => xexp2(x))(-1.0, 1.0, 64);
  assert_eq(mean_err, 0.000101418698020560213);
}

/// Test Chebyshev exp2 fit (floating-point, 3rd)
nothrow @nogc unittest {
  import std.math: exp2;

  alias xexp2 = mk!(Cheby, exp2, -1, 1, 3, float);

  assert_eq(xexp2(-1f), 0.498930305);
  assert_eq(xexp2(1f), 1.998589635);

  enum max_err = max_abs_error!(function (float x) => cast(float) exp2(x),
                                function (float x) => xexp2(x))(-1.0, 1.0, 64);
  assert_eq(max_err, 0.001410300);
  enum mean_err = mean_sqr_error!(function (float x) => exp2(x),
                                  function (float x) => xexp2(x))(-1.0, 1.0, 64);
  assert_eq(mean_err, 7.63618342454793614e-07);
}

/// Test Chebyshev exp2 fit (floating-point, 5th)
nothrow @nogc unittest {
  import std.math: exp2;

  alias xexp2 = mk!(Cheby, exp2, -1, 1, 5, float);

  assert_eq(xexp2(-1f), 0.499996930f);
  assert_eq(xexp2(1f), 1.999995828f);

  enum max_err = max_abs_error!(function (float x) => cast(float) exp2(x),
                                function (float x) => xexp2(x))(-1.0, 1.0, 64);
  assert_eq(max_err, 0.000006702f);
  enum mean_err = mean_sqr_error!(function (float x) => exp2(x),
                                  function (float x) => xexp2(x))(-1.0, 1.0, 64);
  assert_eq(mean_err, 1.45588105599773291e-11);
}
