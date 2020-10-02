/**
   Various numeric utilities
 */
module uctl.util.adj;

import uctl.num: isNum, fix, asfix, asnum, isFixed, isNumer, likeNum;
import uctl.math: abs;
import uctl.util.vec: isVec, vecSize, VecType, sliceof, GenVec, genVecOf;

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
    static assert(is(T[1]: T[0]));
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
    static assert(is(T[1]: T[0]));
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

/// Check that all values is matches predicate
template isAll(alias pred, X...) {
  static if (X.length > 0) {
    enum bool isAll = pred!(X[0]) && isAll!(pred, X[1..$]);
  } else {
    enum bool isAll = true;
  }
}

/// Check that any value is matches predicate
template isAny(alias pred, X...) {
  static if (X.length > 0) {
    enum bool isAny = pred!(X[0]) || isAny!(pred, X[1..$]);
  } else {
    enum bool isAny = false;
  }
}

/**
   Clamp value to the range
*/
template clamp(X...) if (X.length >= 0 && X.length <= 2 && isAll!(likeNum, X)) {
  static if (X.length == 0) {
    pure nothrow @nogc @safe
    auto clamp(V, A, B)(const V val, const A min_, const B max_) if (isNumer!(V, A, B) ||
                                                                     (isVec!V && isNumer!(VecType!V, A, B))) {
      static if (isNumer!V) {
        alias T = V;
      } else {
        alias T = VecType!V;
      }

      auto min = cast(T) min_;
      auto max = cast(T) max_;

      static if (isNumer!V) {
        return val.minof(max).maxof(min);
      } else {
        enum auto N = vecSize!V;
        GenVec!(genVecOf!V, T) ret;

        foreach (i; 0..N) {
          ret.sliceof[i] = val.sliceof[i].minof(max).maxof(min);
        }

        return ret;
      }
    }

    pure nothrow @nogc @safe
    auto clamp(V, A)(const V val, const A lim_) if (isNumer!(V, A) || (isVec!V && isNumer!(VecType!V, A))) {
      auto lim = lim_.abs;

      return clamp(val, -lim, lim);
    }
  } else {
    pure nothrow @nogc @safe
    V clamp(V)(const V val) if (isNumer!V || (isVec!V && isNumer!(VecType!V))) {
      static if (isNumer!V) {
        alias T = V;
      } else {
        alias T = VecType!V;
      }

      static if (X.length == 2) {
        enum auto min = cast(T) X[0];
        enum auto max = cast(T) X[1];
      } else static if (X.length == 1) {
        enum auto lim = X[0].abs;
        enum auto min = cast(T) -lim;
        enum auto max = cast(T) lim;
      }

      static if (isNumer!V) {
        return val.minof(max).maxof(min);
      } else {
        enum auto N = vecSize!V;
        GenVec!(genVecOf!V, T) ret;

        foreach (i; 0..N) {
          ret.sliceof[i] = val.sliceof[i].minof(max).maxof(min);
        }

        return ret;
      }
    }
  }
}

/// Clamp value (floating-point)
nothrow @nogc unittest {
  assert_eq(clamp(1.2, 0.0, 1.0), 1.0);
  assert_eq(clamp!(0.0, 1.0)(1.2), 1.0);

  assert_eq(clamp(1.2, 1.0), 1.0);
  assert_eq(clamp!1.0(1.2), 1.0);

  assert_eq((-1.2).clamp(1.0), -1.0);
  assert_eq((-1.2).clamp(-0.5, 1.0), -0.5);

  assert_eq((-1.2).clamp!1.0, -1.0);
  assert_eq((-1.2).clamp!(-0.5, 1.0), -0.5);
}

/// Clamp vector (floating-point)
nothrow @nogc unittest {
  double[2] ab = [1.25, -0.5];
  auto ab1 = ab.clamp!(-0.25, 1.0);

  assert_eq(ab1.sliceof[0], 1.0);
  assert_eq(ab1.sliceof[1], -0.25);

  auto ab2 = ab.clamp!1.0;

  assert_eq(ab2.sliceof[0], 1.0);
  assert_eq(ab2.sliceof[1], -0.5);

  auto ab3 = ab.clamp(-0.25, 0.5);

  assert_eq(ab3.sliceof[0], 0.5);
  assert_eq(ab3.sliceof[1], -0.25);

  auto ab4 = ab.clamp(1.5);

  assert_eq(ab4.sliceof[0], 1.25);
  assert_eq(ab4.sliceof[1], -0.5);
}

/**
   Scale value from some range to another
 */
template scale(X...) if ((X.length == 0 || X.length == 2 || X.length == 4) && isAll!(likeNum, X)) {
  static if (X.length == 0) {
    pure nothrow @nogc @safe
    auto scale(V, FA, FB, TA, TB)(const V val, const FA from_min, const FB from_max,
                                  const TA to_min, const TB to_min) if (isNumer!V ||
                                                                        (isVec!V && isNumer!(VecType!V))) {
      static if (isNumer!V) {
        alias T = V;
      } else {
        alias T = VecType!V;
      }

      enum auto scale = asnum!((to_max - to_min) / (from_max - from_min), T);
      enum auto offset = asnum!(to_min - from_min * (to_max - to_min) / (from_max - from_min), T);

      static if (isNumer!V) {
        return val * scale + offset;
      } else {
        enum auto N = vecSize!V;
        alias R = typeof(T() * scale + offset);

        GenVec!(genVecOf!V, R) ret;

        foreach (i; 0..N) {
          ret.sliceof[i] = val.sliceof[i] * scale + offset;
        }

        return ret;
      }
    }

    pure nothrow @nogc @safe
    auto scale(V, F, T)(const V val, const F from_, const T to_) if (isNumer!V || (isVec!V && isNumer!(VecType!V))) {
      const auto from = from_.abs;
      const auto to = to_.abs;

      const auto from_min = -from;
      const auto from_max = from;
      const auto to_min = -to;
      const auto to_max = to;

      return scale(val, from_min, from_max, to_min, to_max);
    }
  } else {
    pure nothrow @nogc @safe
    auto scale(V)(const V val) if (isNumer!V || (isVec!V && isNumer!(VecType!V))) {
      static if (X.length == 4) {
        enum auto from_min = X[0];
        enum auto from_max = X[1];
        enum auto to_min = X[2];
        enum auto to_max = X[3];
      } else {
        enum auto from = X[0].abs;
        enum auto to = X[1].abs;

        enum auto from_min = -from;
        enum auto from_max = from;
        enum auto to_min = -to;
        enum auto to_max = to;
      }

      static if (isNumer!V) {
        alias T = V;
      } else {
        alias T = VecType!V;
      }

      enum auto scale = asnum!((to_max - to_min) / (from_max - from_min), T);
      enum auto offset = asnum!(to_min - from_min * (to_max - to_min) / (from_max - from_min), T);

      static if (isNumer!V) {
        return val * scale + offset;
      } else {
        enum auto N = vecSize!V;
        alias R = typeof(T() * scale + offset);

        GenVec!(genVecOf!V, R) ret;

        foreach (i; 0..N) {
          ret.sliceof[i] = val.sliceof[i] * scale + offset;
        }

        return ret;
      }
    }
  }
}

/// Scale value (floating-point)
nothrow @nogc unittest {
  assert_eq(33.4.scale!(-11.5, 39.0, -1.15, 3.9)(), 3.34);

  alias S = scale!(-11.5, 39.0, -1.15, 3.9);
  assert_eq(S(33.4), 3.34);
}

/// Scale value (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(-15, 40);
  alias Y = fix!(-1.5, 4);

  assert_eq(X(33.4).scale!(-11.5, 39.0, -1.15, 3.9)(), Y(3.339999996));

  alias S = scale!(-11.5, 39.0, -1.15, 3.9);
  assert_eq(S(X(33.4)), Y(3.339999996));
}

/// Scale vector (floating-point)
nothrow @nogc unittest {
  const double[2] ab = [33.4, 0.5];
  auto sab = ab.scale!(-11.5, 39.0, -1.15, 3.9);

  assert_eq(sab.sliceof[0], 3.34);
  assert_eq(sab.sliceof[1], 0.05);
}

/// Scale vector (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(-15, 40);
  alias Y = fix!(-1.5, 4);

  const X[2] ab = [X(33.4), X(0.5)];
  auto sab = ab.scale!(-11.5, 39.0, -1.15, 3.9);

  assert_eq(sab.sliceof[0], Y(3.339999996));
  assert_eq(sab.sliceof[1], Y(0.04999999702));
}

/**
   Scale fixed-point value
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
