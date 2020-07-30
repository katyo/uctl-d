/**
   Extra utilities for testing
 */
module test;

import std.math: fabs;
import core.stdc.stdio: snprintf;
import core.stdc.assert_: __assert;

import num: isInt, isFloat, fmtOf;
import fix: fix, isFixed, isNumer;
import unit: Val, isUnits;

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
void assert_eq(T, string file = __FILE__, int line = __LINE__)(T a, T b, T epsilon = T.epsilon) if (isFloat!T) {
  enum string F = fmtOf!T;

  if (fabs(a - b) > epsilon) {
    char[64] buf;

    snprintf(buf.ptr, buf.length, (F ~ " == " ~ F).ptr, a, b);
    __assert(buf.ptr, file.ptr, line);
  }
}

/**
   Assert equality of fixed-point values
*/
nothrow @nogc
void assert_eq(T, string file = __FILE__, int line = __LINE__)(T a, T b, T max_error = T.zero) if (isFixed!T) {
  alias R = double;
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
void assert_eq(T, U, string file = __FILE__, int line = __LINE__)(Val!(T, U) a, Val!(T, U) b) if (isInt!(T) && isUnits!U) {
  assert_eq!(T.raw_t, file, line)(a.raw, b.raw);
}

/**
   Assert equality of floating-point values with units
*/
nothrow @nogc
void assert_eq(T, U, string file = __FILE__, int line = __LINE__)(Val!(T, U) a, Val!(T, U) b, T epsilon = T.epsilon) if (isFloat!(T) && isUnits!U) {
  assert_eq!(T, file, line)(a.raw, b.raw, epsilon);
}

/**
   Assert equality of fixed-point values with units
*/
nothrow @nogc
void assert_eq(T, U, string file = __FILE__, int line = __LINE__)(Val!(T, U) a, Val!(T, U) b, T max_error = T.zero) if (isFixed!(T) && isUnits!U) {
  assert_eq!(T, file, line)(a.raw, b.raw, max_error);
}

/// Test `assert_eq`
nothrow @nogc unittest {
  import fix: asfix;

  int i = 123;
  assert_eq(i, 123);

  double f = -12.3;
  assert_eq(f, -12.3);

  fix!(0, 20) x = 12.3;
  assert_eq(x, cast(typeof(x)) asfix!(12.3));
}

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

mixin unittests;
