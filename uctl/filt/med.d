/**
 * Median filter
 *
 * Generic median filter which effectively reduces pulse noise.
 *
 * See_Also:
 * [Median filter](https://en.wikipedia.org/wiki/Median_filter).
 */
module uctl.filt.med;

import std.traits: ReturnType;
import avg = uctl.filt.avg;
import uctl.num: isNumer;
import uctl.util: ident_picker, isPicker, isMutable, bubble_sort;

version(unittest) {
  import std.algorithm: map;
  import std.array: staticArray;
  import uctl.num: fix, asfix;
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/**
 * Apply median filter
 *
 * Apply filter to static array values directly.
 *
 * Params:
 *   M = number of elements to select (should be 1..N)
 *   N = number of all elements
 *   T = element type
 *   P = element picker function (identity by default)
 *   S = sorting function ([uctl.util.sort.bubble_sort] by default)
 *   data = array of elements
 * Returns: Filtered value
 *
 * To get more smooth you should select lesser M and vice versa.
 *
 * When `M` == `N` than behavior of this filter is same as average filter.
 *
 * Note: This function modifies `data`.
 *
 * See_Also: [uctl.filt.avg.apply]
 */
auto apply(uint M = 1, uint N, T, alias P = ident_picker!T, alias S = bubble_sort)(ref T[N] data) if (isPicker!(P, T) && isMutable!(ReturnType!P) && isNumer!(ReturnType!P) && M >= 1 && M <= N) {
  S!P(data);
  enum uint S = (N - M) / 2;
  enum uint E = S + M;

  return avg.apply!(P, M, T)(data[S .. E]);
}

/// Test median filter (floating-point)
nothrow @nogc unittest {
  static auto a = [0.5, 0.0, 0.0625, 3.15, -0.25].staticArray!float;
  assert_eq(a.apply, 0.0625);

  static auto a2 = [0.5, 0.0, 0.0625, 3.15, -0.25].staticArray!float;
  assert_eq(a2.apply!3, 0.1875);

  static auto a3 = [0.5, 0.0, 0.0625, 3.15, -0.25].staticArray!float;
  assert_eq(a3.apply!5, 0.6925, 1e-7);
}

/// Test median filter (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(-5, 5);

  static auto a = [0.5, 0.0, 0.0625, 3.15, -0.25].map!(x => cast(X) x).staticArray!5;
  assert_eq(a.apply, cast(X) 0.0625);

  static auto a2 = [0.5, 0.0, 0.0625, 3.15, -0.25].map!(x => cast(X) x).staticArray!5;
  assert_eq(a2.apply!3, cast(X) 0.1875, cast(X) 1e-8);

  static auto a3 = [0.5, 0.0, 0.0625, 3.15, -0.25].map!(x => cast(X) x).staticArray!5;
  assert_eq(a3.apply!5, cast(X) 0.6925, cast(X) 1e-8);
}

/**
 * Apply median filter
 *
 * Apply filter to static array values using value picker
 *
 * Params:
 *   P = element picker function
 *   S = sorting function ([uctl.util.sort.bubble_sort] by default)
 *   M = number of elements to select (should be 1..N, 1 by default)
 *   N = number of all elements
 *   T = element type
 *   data = array of elements
 * Returns: Filtered value
 *
 * To get more smooth you should select lesser M and vice versa.
 *
 * When `M` == `N` than behavior of this filter is same as average filter.
 *
 * Note: This function modifies `data`.
 *
 * See_Also: [uctl.filt.avg.apply]
 */
auto apply(alias P, alias S = bubble_sort, uint M = 1, uint N, T)(ref T[N] data) if (isPicker!(P, T) && isMutable!(ReturnType!P) && isNumer!(ReturnType!P) && M >= 1 && M <= N) {
  return apply!(M, N, T, P, S)(data);
}

/// Test median filter with picker
nothrow @nogc unittest {
  struct A {
    bool b;
    float a;
  }

  static auto a = [A(true, 0.5), A(true, 0.0), A(false, 0.0625), A(false, 3.15), A(true, -0.25)].staticArray;

  assert_eq(a.apply!(ref (ref A a) => a.a), 0.0625);
}
