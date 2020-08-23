/**
   Various numeric utilities
 */
module uctl.util.val;

import uctl.num: isNum, fix, asfix, isFixed, isNumer;

version(unittest) {
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/**
   Get minimum value
 */
pure nothrow @nogc @safe
T[0] minof(T...)(T arg) if (isNumer!(T[0])) {
  static if (arg.length > 1) {
    static assert(is(T[0] == T[1]));
    auto head = arg[0];
    auto tail = minof(arg[1 .. $]);
    return head < tail ? head : tail;
  } else {
    return arg[0];
  }
}

/// Minimum
nothrow @nogc unittest {
  assert_eq(minof(0), 0);
  assert_eq(minof(-3, -1), -3);
  assert_eq(minof(1, 5, 3, -1), -1);

  assert_eq(minof(1.5, -0.5), -0.5);
  assert_eq(minof(-0.1, 3.0, 1.5), -0.1);

  alias X = fix!(-10, 5);
  assert_eq(minof(cast(X) 0.1), cast(X) 0.1);
  assert_eq(minof(cast(X) 1.5, cast(X) -0.5), cast(X) -0.5);

  void func(float function(float, float, float) pure nothrow @nogc @safe f) {
    assert_eq(f(2.4, 1.6, 0.5), 0.5);
  }

  alias minof3 = minof!(float, float, float);

  func(&minof3);
}

/**
   Get maximum value
*/
pure nothrow @nogc @safe
T[0] maxof(T...)(T arg) if (isNumer!(T[0])) {
  static if (arg.length > 1) {
    static assert(is(T[0] == T[1]));
    auto head = arg[0];
    auto tail = maxof(arg[1 .. $]);
    return head > tail ? head : tail;
  } else {
    return arg[0];
  }
}

/// Maximum
nothrow @nogc unittest {
  assert_eq(maxof(0), 0);
  assert_eq(maxof(-3, -1), -1);
  assert_eq(maxof(1, 5, 3, -1), 5);

  assert_eq(maxof(1.5, -0.5), 1.5);
  assert_eq(maxof(-0.1, 3.0, 1.5), 3.0);

  alias X = fix!(-10, 5);
  assert_eq(maxof(cast(X) 0.1), cast(X) 0.1);
  assert_eq(maxof(cast(X) 1.5, cast(X) -0.5), cast(X) 1.5);

  void func(float function(float, float, float) pure nothrow @nogc @safe f) {
    assert_eq(f(2.5, 1.6, 0.5), 2.5);
  }

  alias maxof3 = maxof!(float, float, float);

  func(&maxof3);
}

/**
   Clamp value to the range
 */
pure nothrow @nogc @safe
T clamp(T)(T val, T min, T max) if (isNumer!T) {
  return val < max ? (val > min ? val : min) : max;
}

/**
   Limit absolute value
*/
pure nothrow @nogc @safe
T limit(T)(T val, T lim) if (isNumer!T) {
  return clamp(val, -lim, lim);
}

/**
   Scale value from some range to another
 */
pure nothrow @nogc @safe
T scale(real from_min, real from_max, real to_min, real to_max, T)(T val) if (isNum!T) {
  enum auto scale = cast(T) ((to_max - to_min) / (from_max - from_min));
  enum auto offset = cast(T) (to_min - from_min * (to_max - to_min) / (from_max - from_min));

  return val * scale + offset;
}

/// Scale float
nothrow @nogc unittest {
  assert_eq(33.4.scale!(-11.5, 39.0, -1.15, 3.9)(), 3.34);
}

/**
   Scale value from some range to another
*/
pure nothrow @nogc @safe
R scale(R, A)(A val) if (isFixed!R && isFixed!A) {
  enum auto scale = asfix!((R.rmax - R.rmin) / (A.rmax - A.rmin));
  enum auto offset = asfix!(R.rmin - A.rmin * (R.rmax - R.rmin) / (A.rmax - A.rmin));

  return val * scale + offset;
}

/// Scale fixed
nothrow @nogc unittest {
  alias F = fix!(-11.5, 39.0);
  alias T = fix!(-1.15, 3.9);
  assert_eq((cast(F) 33.4).scale!(T, F)(), cast(T) 3.34, cast(T) 1e-8);
}
