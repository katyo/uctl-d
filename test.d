/**
   Extra utilities for testing
 */
module test;

import std.math: fabs;
import core.stdc.stdio: snprintf;
import core.stdc.assert_: __assert;

import num: isInt, isFloat, fmtOf;
import fix: fix, isFixed, isNumer;

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
void assert_eq(T, string file = __FILE__, int line = __LINE__)(T a, T b) if (isFixed!T) {
  alias R = double;
  enum string F = "%0.10g (%i)";

  auto ra = cast(R) a;
  auto rb = cast(R) b;

  if (fabs(ra - rb) > R.epsilon) {
    char[64] buf;

    snprintf(buf.ptr, buf.length, (F ~ " == " ~ F).ptr, ra, a.raw, rb, b.raw);
    __assert(buf.ptr, file.ptr, line);
  }
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

// Run tests without D-runtime
version(D_BetterC) {
  version(unittest) {
    nothrow @nogc extern(C) void main() {
      static foreach(unitTest; __traits(getUnitTests, __traits(parent, main)))
        unitTest();
    }
  }
}
