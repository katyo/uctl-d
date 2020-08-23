/**
   ## Logarithm functions

   Logarithm functions which uses fast binary logarithm algorithm.

   See_Also:
     [A Fast Binary Logarithm](https://www.researchgate.net/publication/252059702_A_Fast_Binary_Logarithm_Algorithm) article by Clay. S. Turner ([pdf](http://www.claysturner.com/dsp/BinaryLogarithm.pdf)).
 */
module uctl.math.log;

import std.math: std_log2 = log2, LOG2E, LOG2T;
import uctl.num: isFloat, fix, asfix, asnum, isNumer, isFixed;

version(unittest) {
  import std.math: pow;
  import uctl.test: assert_eq, max_abs_error, mean_sqr_error, unittests;

  mixin unittests;
}

/**
   Logarithm of base 2

   See_Also: [log], [log10].
*/
auto log2(T)(T x) if (isNumer!T) {
  static if (isFixed!T) {
    static assert(T.rmin > 0, "Logarithm is negative infinity for values which can be zero. Argument has type " ~ T.stringof);

    enum auto Rrmin = std_log2(T.rmin);
    enum auto Rrmax = std_log2(T.rmax);

    alias R = fix!(Rrmin, Rrmax);

    /*if (x == cast(T) 0) {
      return R.min;
    }*/

    alias T1 = fix!(T.rmin > 1 ? 1 : T.rmin, T.rmax < 2 ? 2 : T.rmax);

    T1 x1 = x;
    R y = 0;

    static if (T.rmin < 1) {
      while (x1 < cast(T1) 1) {
        x1 *= 2;
        y -= cast(R) 1;
      }
    }

    static if (T.rmax > 2) {
      while (x1 >= cast(T1) 2) {
        x1 /= 2;
        y += cast(R) 1;
      }
    }

    alias T2 = fix!(1, 2);

    T2 x2 = x1;
    R b = 0.5;

    foreach (i; 0 .. -R.exp) {
      x2 = cast(T2) (x2 * x2);
      if (x2 >= cast(T2) 2) {
        x2 /= 2;
        y += b;
      }
      b /= 2;
    }

    return y;
  }

  static if (isFloat!T) {
    if (x == 0) {
      return -T.infinity;
    }

    T y = 0;

    while (x < 1) {
      x *= 2;
      y -= 1;
    }

    while (x >= 2) {
      x /= 2;
      y += 1;
    }

    T b = 0.5;

    static if (is(T == float)) {
      enum uint prec = 24;
    } else {
      enum uint prec = 52;
    }

    foreach (i; 0 .. prec) {
      x = x * x;
      if (x >= 2) {
        x /= 2;
        y += b;
      }
      b /= 2;
    }

    return y;
  }
}

/// Test `log2` for x < 1 (floating-point)
nothrow @nogc unittest {
  foreach (i; 1..10) {
    assert_eq(log2(2.0f.pow(-i)), cast(float) -i);
  }

  assert_eq(log2(1e-3f), -9.965784284662087f);
  assert_eq(log2(1e-2f), -6.643856189774724f);
  assert_eq(log2(1e-1f), -3.321928094887362f);
}

/// Test `log2` for x > 1 (floating-point)
nothrow @nogc unittest {
  foreach (i; 1..10) {
    assert_eq(log2(2.0f.pow(i)), i);
  }

  assert_eq(log2(1e1f), 3.321928094887362f);
  assert_eq(log2(1e2f), 6.643856189774724f);
  assert_eq(log2(1e3f), 9.965784284662087f);
}

/// Test `log2` for x < 1 (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(1e-3, 1);
  alias Y = fix!(-10, 0);

  foreach (i; 1..10) {
    assert_eq(log2(cast(X) 2.0.pow(-i)), cast(Y) -i);
  }

  assert_eq(log2(cast(X) 1e-3), cast(Y) -9.965784284662087, cast(Y) 1e-6);
  assert_eq(log2(cast(X) 1e-2), cast(Y) -6.643856189774724, cast(Y) 1e-6);
  assert_eq(log2(cast(X) 1e-1), cast(Y) -3.321928094887362, cast(Y) 1e-6);
}

/// Test `log2` for x > 1 (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(1, 1e3);
  alias Y = fix!(0, 10);

  foreach (i; 1..10) {
    assert_eq(log2(cast(X) 2.0.pow(i)), cast(Y) i);
  }

  assert_eq(log2(cast(X) 1e1), cast(Y) 3.321928094887362, cast(Y) 1e-6);
  assert_eq(log2(cast(X) 1e2), cast(Y) 6.643856189774724, cast(Y) 1e-6);
  assert_eq(log2(cast(X) 1e3), cast(Y) 9.965784284662087, cast(Y) 1e-6);
}

/**
   Natural logarithm

   See_Also: [log2], [log10].
*/
auto log(T)(T x) if (isNumer!T) {
  enum auto inv_log2_e = asnum!(1.0 / LOG2E, T);

  return log2(x) * inv_log2_e;
}

/**
   Logarightm of base 10

   See_Also: [log2], [log].
*/
auto log10(T)(T x) if (isNumer!T) {
  enum auto inv_log2_10 = asnum!(1.0 / LOG2T, T);

  return log2(x) * inv_log2_10;
}
