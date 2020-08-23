/**
 * Sorting utils
 */
module uctl.util.sort;

import std.traits: ReturnType;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import std.array: staticArray;

  mixin unittests;
}

/// Identity picker which selects element entirely
ref T ident_picker(T)(ref T v) {
  return v;
}

/// Check if function can be used as value picker
template isPicker(alias P, T) {
  import std.traits;

  static if (isCallable!P) {
    enum bool isPicker = Parameters!P.length == 1 && is(Parameters!P[0] == T) && (ParameterStorageClassTuple!P[0] & (ParameterStorageClass.ref_ | ParameterStorageClass.return_)) && hasFunctionAttributes!(P, "pure", "nothrow", "@nogc", "ref");
  } else {
    enum bool isPicker = false;
  }
}

nothrow @nogc unittest {
  assert(isPicker!(ref (ref int x) => x, int));
  assert(isPicker!(ref (ref const int x) => x, const int));
  assert(isPicker!(ref (ref immutable int x) => x, immutable int));

  assert(isPicker!(ident_picker!int, int));
  assert(isPicker!(ident_picker!(const int), const int));
  assert(isPicker!(ident_picker!(immutable int), immutable int));

  assert(!isPicker!((int x) => x, int));
  assert(!isPicker!((ref int x) => x, int));
  assert(!isPicker!(ref (ref const int x) => x, int));
  assert(!isPicker!(ref (ref int x) => x, const int));
  assert(!isPicker!(ref (ref int x) => x, const int));
  assert(!isPicker!(ref (ref immutable int x) => x, const int));
  assert(!isPicker!(ref (ref const int x) => x, immutable int));
}

/// Check if type is mutable
template isMutable(T) {
  import std.traits;

  enum bool isMutable = is(T == Unconst!T);
}

/// Test isMubale
nothrow @nogc unittest {
  assert(isMutable!int);
  assert(!isMutable!(const int));
  assert(!isMutable!(immutable int));
}

/// Swap two elements entirely
void swap(T, alias P = ident_picker!T)(ref T a, ref T b) if (isPicker!(P, T) && isMutable!(ReturnType!P)) {
  auto c = P(a);
  P(a) = P(b);
  P(b) = c;
}

/// Test swap
nothrow @nogc unittest {
  int a = 1;
  int b = 2;

  swap(a, b);
  assert_eq(a, 2);
  assert_eq(b, 1);
}

/// Swap two elements partially using picker function
void swap(alias P, T)(ref T a, ref T b) if (isPicker!(P, T) && isMutable!(ReturnType!P)) {
  swap!(T, P)(a, b);
}

/// Test swap using picker function
nothrow @nogc unittest {
  struct A {
    int a;
    int b;
  }

  auto a = A(1, 2);
  auto b = A(3, 4);

  swap!(ref (ref A a) => a.a)(a, b);
  assert_eq(a.a, 3);
  assert_eq(a.b, 2);
  assert_eq(b.a, 1);
  assert_eq(b.b, 4);

  swap!(ref (ref A a) => a.b)(a, b);
  assert_eq(a.a, 3);
  assert_eq(a.b, 4);
  assert_eq(b.a, 1);
  assert_eq(b.b, 2);
}

/**
 * Sort values in vector using bubble algorithm
 *
 * This is simple and best choice for short arrays.
 *
 * Params:
 *   N = number of elements in array
 *   T = type of element
 *   C = Picker function for comparison
 *   S = Picker function for swapping
 *
 * See_Also: [comb_sort]
 */
void bubble_sort(uint N, T, alias C = ident_picker!T, alias S = C)(ref T[N] data) if (isPicker!(C, T) && isPicker!(S, T) && isMutable!(ReturnType!S)) {
  enum uint L = N - 1;

  for (uint i = 0; i < L; i ++) {
    bool swapped = 0;

    for (uint j = 0; j < L - i; j ++) {
      auto a = &data[j];
      auto b = &data[j + 1];
      if (C(*a) > C(*b)) {
        swap!S(*a, *b);
        swapped = 1;
      }
    }

    if (!swapped) {
      break;
    }
  }
}

/// Test sorting using bubble algorithm
nothrow @nogc unittest {
  static auto a = [1, 5, 3, 4, 2].staticArray!int;

  bubble_sort(a);

  assert_eq(a[0], 1);
  assert_eq(a[1], 2);
  assert_eq(a[2], 3);
  assert_eq(a[3], 4);
  assert_eq(a[4], 5);

  static auto a2 = [0.5, 0.0, 3.15, -0.25].staticArray!double;

  a2.bubble_sort;

  assert_eq(a2[0], -0.25);
  assert_eq(a2[1], 0.0);
  assert_eq(a2[2], 0.5);
  assert_eq(a2[3], 3.15);
}

/**
 * Sort values in vector using bubble algorithm
 *
 * This is simple and best choice for short arrays.
 *
 * Params:
 *   C = Picker function for comparison
 *   S = Picker function for swapping
 *   N = number of elements in array
 *   T = type of element
 *
 * See_Also: [comb_sort]
 */
void bubble_sort(alias C, alias S = C, uint N, T)(ref T[N] data) if (isPicker!(C, T) && isPicker!(S, T) && isMutable!(ReturnType!S)) {
  bubble_sort!(N, T, C, S)(data);
}

/// Test sorting using bubble algorithm with picker
nothrow @nogc unittest {
  struct A {
    int a;
    int b;
  }
  static auto a = [A(1, 0), A(5, 2), A(3, 1), A(4, 4), A(2, 3)].staticArray;

  bubble_sort!(ref (ref A a) => a.a)(a);
  assert_eq(a[0].a, 1);
  assert_eq(a[0].b, 0);
  assert_eq(a[1].a, 2);
  assert_eq(a[1].b, 2);
  assert_eq(a[2].a, 3);
  assert_eq(a[2].b, 1);
  assert_eq(a[3].a, 4);
  assert_eq(a[3].b, 4);
  assert_eq(a[4].a, 5);
  assert_eq(a[4].b, 3);

  bubble_sort!(ref (ref A a) => a.b, ident_picker!A)(a);
  assert_eq(a[0].a, 1);
  assert_eq(a[0].b, 0);
  assert_eq(a[1].a, 3);
  assert_eq(a[1].b, 1);
  assert_eq(a[2].a, 2);
  assert_eq(a[2].b, 2);
  assert_eq(a[3].a, 5);
  assert_eq(a[3].b, 3);
  assert_eq(a[4].a, 4);
  assert_eq(a[4].b, 4);
}

/**
 * Sort values in vector using comb algorithm
 *
 * Params:
 *   N = number of elements in array
 *   T = type of element
 *   C = Picker function for comparison
 *   S = Picker function for swapping
 *
 * See_Also: [bubble_sort]
 */
void comb_sort(uint N, T, alias C = ident_picker!T, alias S = C)(ref T[N] data) if (isPicker!(C, T) && isPicker!(S, T) && isMutable!(ReturnType!S)) {
  import std.math: E, pow;
  import uctl.num: PHI, fix, asfix;

  enum auto fact = asfix!(1.0 - pow(E, -PHI));

  alias F = fix!(0, N);

  uint step = N - 1;

  for (; step >= 1; ) {
    uint top = N - step;

    for (uint i = 0; i < top; ++ i) {
      auto a = &data[i];
      auto b = &data[i + step];

      if (C(*a) > C(*b)) {
        swap!S(*a, *b);
      }
    }

    step = cast(int) (F(step) * fact);
  }

  bubble_sort!(N, T, C, S)(data);
}

/// Test sorting using comb algorithm
nothrow @nogc unittest {
  static auto a = [1, 5, 3, 4, 2].staticArray!int;

  comb_sort(a);

  assert_eq(a[0], 1);
  assert_eq(a[1], 2);
  assert_eq(a[2], 3);
  assert_eq(a[3], 4);
  assert_eq(a[4], 5);

  static auto a2 = [0.5, 0.0, 3.15, -0.25].staticArray!double;

  a2.comb_sort;

  assert_eq(a2[0], -0.25);
  assert_eq(a2[1], 0.0);
  assert_eq(a2[2], 0.5);
  assert_eq(a2[3], 3.15);
}

/**
 * Sort values in vector using comb algorithm
 *
 * Params:
 *   C = Picker function for comparison
 *   S = Picker function for swapping
 *   N = number of elements in array
 *   T = type of element
 *
 * See_Also: [bubble_sort]
 */
void comb_sort(alias C, alias S = C, uint N, T)(ref T[N] data) if (isPicker!(C, T) && isPicker!(S, T) && isMutable!(ReturnType!S)) {
  comb_sort!(N, T, C, S)(data);
}

/// Test sorting using comb algorithm with picker
nothrow @nogc unittest {
  struct A {
    int a;
    int b;
  }
  static auto a = [A(1, 0), A(5, 2), A(3, 1), A(4, 4), A(2, 3)].staticArray;

  comb_sort!(ref (ref A a) => a.a)(a);
  assert_eq(a[0].a, 1);
  assert_eq(a[0].b, 0);
  assert_eq(a[1].a, 2);
  assert_eq(a[1].b, 2);
  assert_eq(a[2].a, 3);
  assert_eq(a[2].b, 1);
  assert_eq(a[3].a, 4);
  assert_eq(a[3].b, 4);
  assert_eq(a[4].a, 5);
  assert_eq(a[4].b, 3);

  comb_sort!(ref (ref A a) => a.b, ident_picker!A)(a);
  assert_eq(a[0].a, 1);
  assert_eq(a[0].b, 0);
  assert_eq(a[1].a, 3);
  assert_eq(a[1].b, 1);
  assert_eq(a[2].a, 2);
  assert_eq(a[2].b, 2);
  assert_eq(a[3].a, 5);
  assert_eq(a[3].b, 3);
  assert_eq(a[4].a, 4);
  assert_eq(a[4].b, 4);
}
