/**
   Compile-time generated lookup tables

   This module provide some utils which helps generate lookup tables easy.
*/
module lt;

import num: isFloat;
import fix: isFixed, fix, asfix;

version(unittest) {
  import test: assert_eq, unittests;
  import std.math: PI, sin;

  enum auto eps = 1e-7;

  mixin unittests;
}

/**
   Floating-point compile-time generated lookup table

   Regular lookup table for one argument with linear interpolation which can be used by calling it as a function.

   ---
   alias sqr = lt1!(10, float, float, 0.0, 1.0, (x) => x * x);

   assert(sqr(0) == 0);
   ---
*/
pure nothrow @nogc @safe
R lt1(uint len, R, A, real start, real end, real function(real) pure nothrow @nogc @safe gen)(A arg) if (isFloat!R && isFloat!A) {
  enum A init = cast(A) start;
  enum A fact = (cast(A) (len - 1)) / (end - start);

  static immutable R[len] data = (){
    R[len] data;
    foreach (uint i; 0 .. len) {
      data[i] = cast(R) gen(start + i * (end - start) / (len - 1));
    }
    return data;
  }();

  auto pos = (arg - init) * fact;
  auto idx = cast(int) pos;

  if (idx < 0) {
    idx = 0;
  } else if (idx > len - 2) {
    idx = len - 2;
  }

  auto uidx = cast(uint) idx;

  return data[uidx] + cast(R) (pos - cast(typeof(pos)) idx) * (data[uidx + 1] - data[uidx]);
}

/// Test floating-point lookup tables (x^2)
nothrow @nogc unittest {
  alias sqr = lt1!(10, float, float, 0.0, 1.0, (x) => x * x);

  assert_eq(sqr(0), 0);
  assert_eq(sqr(0.1), 0.01, 0.002);
  assert_eq(sqr(0.5), 0.25, 0.004);
  assert_eq(sqr(1), 1);

  void test_as_func(float delegate(float) pure nothrow @safe @nogc f) {
    assert_eq(f(0), 0);
    assert_eq(f(0.1), 0.01, 0.002);
    assert_eq(f(0.5), 0.25, 0.004);
    assert_eq(f(1), 1);
  }

  test_as_func(&sqr);
}

/// Test floating-point lookup tables (sin)
nothrow @nogc unittest {
  alias fsin = lt1!(32, float, float, 0.0, PI/2.0, (x) => sin(x));

  assert_eq(fsin(0.0), 0.0, eps);
  assert_eq(fsin(PI/6.0), 0.499856, eps);
  assert_eq(fsin(PI/2.0), 1.0, eps);
}

/**
   Fixed-point compile-time generated lookup table

   Regular lookup table for one argument with linear interpolation which can be used by calling it as a function.

   ---
   alias X = fix!(0.0, 1.0);

   alias sqr = lt1!(10, X, X, (x) => x * x);

   assert(sqr(cast(X) 0.0) == cast(X) 0.0);
   ---
*/
pure nothrow @nogc @safe
R lt1(uint len, R, A, real function(real) pure nothrow @nogc @safe gen)(A arg) if (isFixed!R && isFixed!A) {
  enum auto init = asfix!(A.rmin);
  enum auto fact = asfix!((cast(real) (len - 1)) / (A.rmax - A.rmin));

  static immutable R[len] data = () {
    R[len] data;
    foreach (uint i; 0 .. len) {
      data[i] = cast(R) gen(A.rmin + i * (A.rmax - A.rmin) / (len - 1));
    }
    return data;
  }();

  auto pos = (arg - init) * fact;
  auto idx = cast(int) pos;

  if (idx < 0) {
    idx = 0;
  } else if (idx > len - 2) {
    idx = len - 2;
  }

  auto uidx = cast(uint) idx;

  //auto interp = cast(fix!(0, 1)) (pos - cast(fix!(0, len - 2)) idx);
  auto interp = cast(fix!(0, 1)) (pos - cast(typeof(pos)) idx);

  auto offset = data[uidx];
  auto factor = data[uidx + 1] - data[uidx];

  return cast(R) (offset + interp * factor);
}

/// Test fixed-point lookup tables (x^2)
@nogc nothrow unittest {
  alias X = fix!(0.0, 1.0);

  alias sqr = lt1!(10, X, X, (x) => x * x);

  assert_eq(sqr(cast(X) 0), cast(X) 0);
  assert_eq(sqr(cast(X) 0.1), cast(X) 0.01, cast(X) 0.002);
  assert_eq(sqr(cast(X) 0.5), cast(X) 0.25, cast(X) 0.005);
  assert_eq(sqr(cast(X) 1), cast(X) 1, cast(X) 0.000001);

  void test_as_func(X delegate(X) pure nothrow @safe @nogc f) {
    assert_eq(sqr(cast(X) 0), cast(X) 0);
    assert_eq(sqr(cast(X) 0.1), cast(X) 0.01, cast(X) 0.002);
    assert_eq(sqr(cast(X) 0.5), cast(X) 0.25, cast(X) 0.005);
    assert_eq(sqr(cast(X) 1), cast(X) 1, cast(X) 0.000001);
  }

  test_as_func(&sqr);
}

/// Test fixed-point lookup tables (sin)
nothrow @nogc unittest {
  alias X = fix!(0.0, PI/2.0);
  alias Y = fix!(-1.0, 1.0);

  alias fsin = lt1!(32, Y, X, (x) => sin(x));

  assert_eq(fsin(cast(X) 0.0), cast(Y) 0.0, cast(Y) eps);
  assert_eq(fsin(cast(X) (PI/6.0)), cast(Y) 0.499856, cast(Y) eps);
  assert_eq(fsin(cast(X) (PI/2.0)), cast(Y) 1.0, cast(Y) eps);
}
