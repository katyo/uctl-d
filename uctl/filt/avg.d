/**
 * Average filter
 *
 * Generic average filter which simply calculates average value.
 *
 * Filter formula: $(MATH y = \frac{1}{N} \displaystyle\sum_{n=0}^{N-1}{x_n})
 */
module uctl.filt.avg;

import std.math: isPowerOf2;
import std.traits: ReturnType, Unqual;
import uctl.num: fix, asfix, isNumer, isFixed;
import uctl.util: isPicker, ident_picker;

version(unittest) {
  import std.algorithm: map;
  import std.array: staticArray;
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/**
 * Apply average filter
 *
 * Apply filter to static array values directly
 *
 * Params:
 *   N = number of elements
 *   T = element type
 *   P = accessor function
 *   data = array of elements
 * Returns: Filtered value
 */
auto avg(uint N, T, alias P = ident_picker!T)(ref T[N] data) if (isPicker!(P, T) && isNumer!(ReturnType!P) && N > 0) {
  alias R = Unqual!(ReturnType!P);

  static if (isFixed!T) {
    alias A = typeof(R() * asfix!N);
  } else {
    alias A = R;
  }

  static if (N == 1) {
    return P(data[0]);
  } else {
    A acc = 0;

    foreach (nth; 0 .. N) {
      acc += P(data[nth]);
    }

    static if (isFixed!T) {
      enum auto div = asfix!N;
      enum auto mul = asfix!(1.0 / N);
    } else {
      enum auto div = cast(R) N;
      enum auto mul = cast(R) 1.0 / cast(R) N;
    }

    static if (isPowerOf2(N)) {
      auto res = acc / div;
    } else {
      auto res = acc * mul;
    }

    return cast(R) res;
  }
}

/// Test average filter (floating-point)
nothrow @nogc unittest {
  static immutable auto a = [0.0, 0.5, 3.15, -0.25].staticArray!float;
  assert_eq(a.avg, 0.85, 1e-7);
  assert_eq(a[1..$-1].avg, 1.825, 1e-7);

  static immutable auto b = [0.0, 1.5, 2.25, -0.125, -1.0].staticArray!float;
  assert_eq(b.avg, 0.525, 1e-7);
  assert_eq(a[2..$].avg, 1.45, 1e-7);
}

/// Test average filter (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(-5, 5);

  static immutable auto c = [0.0, 0.5, 3.15, -0.25].map!(x => cast(X) x).staticArray!4;
  assert_eq(c.avg, cast(X) 0.85, cast(X) 1e-8);

  static immutable auto d = [0.0, 1.5, 2.25, -0.125, -1.0].map!(x => cast(X) x).staticArray!5;
  assert_eq(d.avg, cast(X) 0.525);
}

/**
 * Apply average filter
 *
 * Apply filter to static array using value picker
 *
 * Params:
 *   P = value picker function
 *   N = number of elements
 *   T = element type
 *   data = array of elements
 * Returns: Filtered value
 */
auto avg(alias P, uint N, T)(ref T[N] data) if (isPicker!(P, T) && isNumer!(ReturnType!P) && N > 0) {
  return avg!(N, T, P)(data);
}

/// Test average filter (with accessor)
nothrow @nogc unittest {
  struct A {
    bool a;
    float b;
    int c;
  }

  static immutable auto s = [A(true, 0.0, 1), A(true, 0.25, 5), A(false, -1.75, 2)].staticArray;

  assert_eq(s.avg!(ref (ref immutable A a) => a.b), -0.5);

  static const auto s1 = [A(true, 0.0, 1), A(true, 0.25, 5), A(false, -1.75, 2)].staticArray;

  assert_eq(s.avg!(ref (ref immutable A a) => a.b), -0.5);

  static auto s2 = [A(true, 0.0, 1), A(true, 0.25, 5), A(false, -1.75, 2)].staticArray;

  assert_eq(s2.avg!(ref (ref A a) => a.b), -0.5);
}
