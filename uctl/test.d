/**
   Extra utilities for testing
 */
module uctl.test;

import std.traits: isCallable, Parameters, ReturnType;
import std.math: fmax, fabs;

import core.stdc.stdio: snprintf;
import core.stdc.assert_: __assert;

import uctl.num: isInt, isFloat, fmtOf, fix, asfix, isFixed, isSameFixed, isNumer;
import uctl.unit: hasUnits, rawTypeOf;

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
  import uctl.unit: as, cm, sec;

  mixin unittests;
}

/**
   Unified assert equality of values
*/
void assert_eq(T, S, string file = __FILE__, int line = __LINE__)(const T a, const S b)
if ((hasUnits!T && hasUnits!S && is(T.units == S.units) && isNumer!(T.raw_t, S.raw_t)) || isNumer!(T, S)) {
  alias R = rawTypeOf!S;

  static if (isInt!R) {
    enum R max_error = 0;
  } else static if (isFloat!R) {
    enum R max_error = R.epsilon;
  } else static if (isFixed!R) {
    enum R max_error = R.zero;
  }

  assert_eq!(T, S, R, file, line)(a, b, max_error);
}

/**
   Unified assert equality of values with `max_error`
*/
void assert_eq(T, S, E, string file = __FILE__, int line = __LINE__)(const T a, const S b, const E max_error)
 if ((hasUnits!T && hasUnits!S && is(T.units == S.units) && isNumer!(T.raw_t, S.raw_t, E)) || isNumer!(T, S, E)) {
  static if (hasUnits!T) {
    alias T_ = T.raw_t;
    auto a_ = a.raw;
    auto b_ = cast(T_) b.raw;
    auto e_ = cast(T_) max_error;
  } else {
    alias T_ = T;
    auto a_ = a;
    auto b_ = cast(T_) b;
    auto e_ = cast(T_) max_error;
  }

  static if (isInt!T_ || isFloat!T_) {
    enum string F = fmtOf!T_;
  } else static if (isFixed!T_) {
    enum string F = "%0.10g (%i)";
  }

  auto d_ = a_ > b_ ? a_ - b_ : b_ - a_;

  if (d_ > e_) {
    char[128] buf;

    static if (isInt!T_ || isFloat!T_) {
      snprintf(buf.ptr, buf.length, (F ~ " == " ~ F ~ " (error " ~ F ~ " > " ~ F ~ ")").ptr, a_, b_, d_, e_);
    } else static if (isFixed!T_) {
      snprintf(buf.ptr, buf.length, (F ~ " == " ~ F ~ " (error " ~ F ~ " > " ~ F ~ ")").ptr,
               cast(double) a_, a_.raw, cast(double) b_, b_.raw, cast(double) d_, d_.raw, cast(double) e_, e_.raw);
    }

    __assert(buf.ptr, file.ptr, line);
  }
}

/// Test `assert_eq`
nothrow @nogc unittest {
  immutable int i = 123;
  assert_eq(i, 123);

  immutable double d = -12.3;
  assert_eq(d, -12.3);

  immutable float f = 1.25;
  assert_eq(f, 1.25);

  assert_eq(1.2345678, 1.2345679, 1e-6);

  alias X = fix!(0, 20);

  X x = 12.3;
  assert_eq(x, cast(X) asfix!12.3);

  assert_eq(X(-1.25), cast(X)-1.25);
}

/// Test `assert_eq` with units
nothrow @nogc unittest {
  assert_eq(5.as!cm, 5.as!cm);

  assert_eq(0.125.as!sec, 0.125.as!sec);
  assert_eq(0.125.as!sec, 0.1251.as!sec, 1e-4);

  alias X = fix!(0, 10);

  assert_eq(X(12.3).as!cm, (cast(X) asfix!(12.3)).as!cm);
}

/**
   Calculate maximum absolute error
 */
template max_abs_error(alias F, alias R) if (isCallable!F && isCallable!R &&
                                             is(ReturnType!F == ReturnType!R) &&
                                             is(Parameters!F == Parameters!R)) {
  alias A = Parameters!F[0];
  alias E = ReturnType!F;

  alias max_abs_error = (A x, A X, uint N = 32) pure nothrow @nogc @safe {
    static if (isFloat!A && isFloat!E) {
      immutable step = (X - x) / (N - 1);

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
        immutable arg = cast(A) (x + step * i);
        immutable err = cast(E) fabs(F(arg) - R(arg));

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
template mean_abs_error(alias F, alias R) if (isCallable!F && isCallable!R &&
                                              is(ReturnType!F == ReturnType!R) &&
                                              is(Parameters!F == Parameters!R)) {
  alias A = Parameters!F[0];
  alias E = ReturnType!F;

  alias mean_abs_error = (A x, A X, uint N = 32) pure nothrow @nogc @safe {
    static if (isFloat!A && isFloat!E) {
      immutable step = (X - x) / (N - 1);
      auto res = cast(E) 0;

      foreach (i; 0..N) {
        immutable arg = cast(A) (x + step * i);
        immutable err = fabs(F(arg) - R(arg));

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
template mean_sqr_error(alias F, alias R) if (isCallable!F && isCallable!R &&
                                              is(ReturnType!F == ReturnType!R) &&
                                              is(Parameters!F == Parameters!R)) {
  alias A = Parameters!F[0];
  alias E = typeof(ReturnType!F() * ReturnType!F());

  alias mean_sqr_error = (A x, A X, uint N = 32) pure nothrow @nogc @safe {
    static if (isFloat!A && isFloat!E) {
      immutable step = (X - x) / (N - 1);
      auto res = cast(E) 0;

      foreach (i; 0..N) {
        immutable arg = cast(A) (x + step * i);
        immutable err = F(arg) - R(arg);
        immutable err2 = err * err;

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
