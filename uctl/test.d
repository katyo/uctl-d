/**
   Extra utilities for testing
 */
module uctl.test;

import std.traits: isCallable, Parameters, ReturnType;
import std.math: fmax, fabs;

import core.stdc.stdio: snprintf;
import core.stdc.assert_: __assert;

import uctl.num: isInt, isFloat, fmtOf, fix, asfix, isFixed, isSameFixed, isNumer;
import uctl.unit: Val, isUnits, hasUnits;

/**
   Unittests runner mixin

   Use this mixin in modules to run tests in -betterC mode
 */
mixin template unittests() {
  // Run tests without D-runtime
  version(D_BetterC) {
    version(unittest) {
      pragma(mangle, "main")
        nothrow @nogc extern(C) void main() {
        static foreach(unitTest; __traits(getUnitTests, __traits(parent, main)))
          unitTest();
      }
    }
  }
}

version(unittest) {
  mixin unittests;
}

/**
   Assert equality of integer values
*/
nothrow @nogc
void assert_eq(T, string file = __FILE__, int line = __LINE__)(T a, T b) if (isInt!T) {
  enum string F = fmtOf!T;

  if (a != b) {
    char[64] buf;

    snprintf(buf.ptr, buf.length, (F ~ " == " ~ F).ptr, a, b);
    __assert(buf.ptr, file.ptr, line);
  }
}

/**
   Assert equality of floating-point values
*/
nothrow @nogc
void assert_eq(T, string file = __FILE__, int line = __LINE__)(T a, T b, T max_error = T.epsilon) if (isFloat!T) {
  enum string F = fmtOf!T;

  if (fabs(a - b) > max_error) {
    char[64] buf;

    snprintf(buf.ptr, buf.length, (F ~ " == " ~ F).ptr, a, b);
    __assert(buf.ptr, file.ptr, line);
  }
}

/**
   Assert equality of fixed-point values
*/
nothrow @nogc
void assert_eq(T, S, string file = __FILE__, int line = __LINE__)(T a, S b, S max_error = S.zero) if (isFixed!T && isFixed!S && isSameFixed!(T, S)) {
  enum string F = "%0.10g (%i)";

  auto d = a.raw > b.raw ? a.raw - b.raw : b.raw - a.raw;

  if (d > max_error.raw) {
    char[128] buf;

    snprintf(buf.ptr, buf.length, (F ~ " == " ~ F ~ " (error > " ~ F ~ ")").ptr, cast(double) a, a.raw, cast(double) b, b.raw, cast(double) max_error, max_error.raw);
    __assert(buf.ptr, file.ptr, line);
  }
}

/**
   Assert equality of integer values with units
*/
nothrow @nogc
void assert_eq(T, S, U, string file = __FILE__, int line = __LINE__)(Val!(T, U) a, Val!(S, U) b) if (isInt!T && isInt!S && isUnits!U && is(T == S)) {
  assert_eq!(T.raw_t, file, line)(a.raw, b.raw);
}

/**
   Assert equality of floating-point values with units
*/
nothrow @nogc
void assert_eq(T, S, U, string file = __FILE__, int line = __LINE__)(Val!(T, U) a, Val!(S, U) b, S max_error = S.epsilon) if (isFloat!T && isFloat!S && isUnits!U && is(T == S)) {
  assert_eq!(T, file, line)(a.raw, b.raw, max_error);
}

/**
   Assert equality of fixed-point values with units
*/
nothrow @nogc
void assert_eq(T, S, U, string file = __FILE__, int line = __LINE__)(Val!(T, U) a, Val!(S, U) b, S max_error = S.zero) if (isFixed!T && isFixed!S && isUnits!U && isSameFixed!(T, S)) {
  assert_eq!(T, S, file, line)(a.raw, b.raw, max_error);
}

/// Test `assert_eq`
nothrow @nogc unittest {
  int i = 123;
  assert_eq(i, 123);

  double f = -12.3;
  assert_eq(f, -12.3);

  fix!(0, 20) x = 12.3;
  assert_eq(x, cast(typeof(x)) asfix!(12.3));
}

/**
   Calculate maximum absolute error
 */
template max_abs_error(alias F, alias R) if (isCallable!F && isCallable!R && is(ReturnType!F == ReturnType!R) && is(Parameters!F == Parameters!R)) {
  alias A = Parameters!F[0];
  alias E = ReturnType!F;

  alias max_abs_error = (A x, A X, uint N = 32) pure nothrow @nogc @safe {
    static if (isFloat!A && isFloat!E) {
      const auto step = (X - x) / (N - 1);

      /* Hmm... Strange. Unfortutately we cannot use closures without GC.
         return iota(0, N)
         .map!((uint i) scope pure nothrow @nogc @safe {
         auto arg = cast(A) (x + step * i);
         return abs(F(arg) - R(arg));
         })
         .maxElement();
      */
      auto res = cast(E) 0;

      foreach (i; 0..N) {
        auto arg = cast(A) (x + step * i);
        auto err = cast(E) fabs(F(arg) - R(arg));

        res = cast(E) fmax(res, err);
      }

      return res;
    }
  };
}

/// Test maximum absolute error
nothrow @nogc unittest {
  import std.math: PI, sin;

  assert_eq(max_abs_error!((double x) => sin(x), (double x) => sin(x))(-2*PI, 2*PI), 0.0);
  assert_eq(max_abs_error!((double x) => sin(x), (double x) => sin(x+1e-5))(-2*PI, 2*PI), 1e-5, 1e-9);
}

/**
   Calculate mean absolute error
*/
template mean_abs_error(alias F, alias R) if (isCallable!F && isCallable!R && is(ReturnType!F == ReturnType!R) && is(Parameters!F == Parameters!R)) {
  alias A = Parameters!F[0];
  alias E = ReturnType!F;

  alias mean_abs_error = (A x, A X, uint N = 32) pure nothrow @nogc @safe {
    static if (isFloat!A && isFloat!E) {
      const auto step = (X - x) / (N - 1);
      auto res = cast(E) 0;

      foreach (i; 0..N) {
        auto arg = cast(A) (x + step * i);
        auto err = fabs(F(arg) - R(arg));

        res = cast(E) (res + err);
      }

      return res * (1.0 / N);
    }
  };
}

/// Test mean absolute error
nothrow @nogc unittest {
  import std.math: PI, sin;

  assert_eq(mean_abs_error!((double x) => sin(x), (double x) => sin(x))(-2*PI, 2*PI), 0.0);
  assert_eq(mean_abs_error!((double x) => sin(x), (double x) => sin(x+1e-5))(-2*PI, 2*PI), 6.48239e-6, 1e-10);
}

/**
   Calculate mean square error
*/
template mean_sqr_error(alias F, alias R) if (isCallable!F && isCallable!R && is(ReturnType!F == ReturnType!R) && is(Parameters!F == Parameters!R)) {
  alias A = Parameters!F[0];
  alias E = typeof(ReturnType!F() * ReturnType!F());

  alias mean_sqr_error = (A x, A X, uint N = 32) pure nothrow @nogc @safe {
    static if (isFloat!A && isFloat!E) {
      const auto step = (X - x) / (N - 1);
      auto res = cast(E) 0;

      foreach (i; 0..N) {
        auto arg = cast(A) (x + step * i);
        auto err = F(arg) - R(arg);
        auto err2 = err * err;

        res = cast(E) (res + err2);
      }

      return res * (1.0 / N);
    }
  };
}

/// Test mean square error
nothrow @nogc unittest {
  import std.math: PI, sin;

  assert_eq(mean_sqr_error!((double x) => sin(x), (double x) => sin(x))(-2*PI, 2*PI), 0.0);
  assert_eq(mean_sqr_error!((double x) => sin(x), (double x) => sin(x+1e-5))(-2*PI, 2*PI), 5.15625e-11);
}
