/**
   Generic math utils
 */
module uctl.math.util;

static import std.math;
import uctl.num: isFixed, isNumer;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.num: fix, asfix;

  mixin unittests;
}

/// Absolute value
pure nothrow @nogc @safe
auto abs(T)(const T x) if (isNumer!T) {
  static if (isFixed!T) {
    return x.absof;
  } else {
    return std.math.abs(x);
  }
}

/// Test `abs`
nothrow @nogc unittest {
  assert_eq(2.abs, 2);
  assert_eq((-3).abs, 3);

  assert_eq(0.5.abs, 0.5);
  assert_eq((-1.5).abs, 1.5);

  assert_eq(1.5f.abs, 1.5f);
  assert_eq((-2.5f).abs, 2.5f);

  alias X = fix!(-2, 1);
  alias Y = fix!(0, 2);

  assert_eq(X(-1.5).abs, Y(1.5));
  assert_eq(X(0.5).abs, Y(0.5));
}
