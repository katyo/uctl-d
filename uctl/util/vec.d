/**
   Vector utils
 */
module uctl.util.vec;

import std.traits: isArray, Fields, isInstanceOf;
import std.range: ElementType;
import uctl.num: isNumer, isInt;
import uctl.unit: hasUnits;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.num: fix;

  mixin unittests;
}

/// Partially applied vector type
template Vec(uint N) {
  alias Vec(T) = .Vec!(N, T);
}

/// Partially applied vector type
template Vec(T) {
  alias Vec(uint N) = .Vec!(N, T);
}

/// Simple vector type backed by static array
struct Vec(uint N, T) {
  private T[N] data;

  alias data this;
}

/// Test `Vec`
nothrow @nogc @safe unittest {
  alias Vec3 = Vec!3;
  alias FVec = Vec!float;
  alias FVec2 = FVec!2;
  alias FVec3 = Vec3!float;

  assert(isInstanceOf!(Vec, Vec!3));
  assert(isInstanceOf!(Vec, Vec!float));
  assert(isInstanceOf!(Vec, Vec!(3, float)));

  assert(isInstanceOf!(Vec, Vec3));
  assert(isInstanceOf!(Vec, FVec));
  assert(isInstanceOf!(Vec, FVec2));
  assert(isInstanceOf!(Vec, FVec3));

  assert(isInstanceOf!(Vec, Vec3!int));
  assert(isInstanceOf!(Vec, FVec!2));

  assert(!isVec!Vec3);
  assert(!isVec!FVec);
  assert(isVec!FVec2);
  assert(isVec!FVec3);
}

/**
   Get vector element type
*/
template VecType(X...) if (X.length == 1 && isVec!(X[0])) {
  static if (isArray!(X[0])) {
    alias VecType = ElementType!(X[0]);
  } else static if (is(X[0] == struct)) {
    alias VecType = Fields!(X[0])[0];
  }
}

/**
   Get vector size in elements
*/
template VecSize(X...) if (X.length == 1 && isVec!(X[0])) {
  static if (isArray!(X[0])) {
    enum uint VecSize = X[0].length;
  } else static if (is(X[0] == struct)) {
    enum uint VecSize = Fields!(X[0]).length;
  }
}

private template checkFields(F...) {
  static if (F.length > 1) {
    enum bool checkFields = is(F[0] == F[1]) && checkFields!(F[1..$]);
  } else {
    enum bool checkFields = true;
  }
}

/**
   Check that some type can be treated as vector
*/
template isVec(X...) if (X.length >= 1 || X.length <= 3) {
  static if (X.length == 1) {
    static if (is(X[0])) {
      static if (isInstanceOf!(Vec, X[0]) || isArray!(X[0])) {
        enum bool isVec = true;
      } else static if (isNumer!(X[0]) || hasUnits!(X[0])) {
        enum bool isVec = false;
      } else static if (is(X[0] == struct) && Fields!(X[0]).length > 0 && checkFields!(Fields!(X[0]))) {
        enum bool isVec = true;
      } else {
        enum bool isVec = false;
      }
    } else {
      enum bool isVec = isVec!(typeof(X[0]));
    }
  } else static if (isVec!(X[0])) {
    static if (X.length == 2) {
      static if (is(X[1])) {
        enum bool isVec = is(VecType!(X[0]) == X[1]);
      } else static if (isInt!(X[1])) {
        enum bool isVec = VecSize!(X[0]) == X[1];
      } else {
        enum bool isVec = false;
      }
    } else {
      enum bool isVec = isVec!(X[0], X[1]) && isVec!(X[0], X[2]);
    }
  } else {
    enum bool isVec = false;
  }
}

/// Test `isVec`
nothrow @nogc @safe unittest {
  alias X = fix!(-1, 1);

  struct S(T) {
    T a;
    T b;
  }

  struct R(A, B) {
    A a;
    B b;
  }

  assert(isVec!(double[1]));
  assert(isVec!(int[2]));
  assert(isVec!(X[3]));
  assert(isVec!(S!float));
  assert(isVec!(S!int));
  assert(isVec!(S!X));
  assert(isVec!(R!(X, X)));

  assert(isVec!(double[1], double));
  assert(isVec!(int[2], int));
  assert(isVec!(X[3], X));
  assert(isVec!(S!float, float));
  assert(isVec!(S!int, int));
  assert(isVec!(S!X, X));
  assert(isVec!(R!(X, X), X));

  assert(isVec!(double[1], 1));
  assert(isVec!(int[2], 2));
  assert(isVec!(X[3], 3));
  assert(isVec!(S!X, 2));
  assert(isVec!(R!(X, X), 2));

  assert(isVec!(double[1], double, 1));
  assert(isVec!(int[2], int, 2));
  assert(isVec!(X[3], X, 3));
  assert(isVec!(S!X, X, 2));
  assert(isVec!(R!(X, X), X, 2));

  assert(isVec!(double[1], 1, double));
  assert(isVec!(int[2], 2, int));
  assert(isVec!(X[3], 3, X));
  assert(isVec!(S!X, 2, X));
  assert(isVec!(R!(X, X), 2, X));

  assert(!isVec!(double));
  assert(!isVec!(int));
  assert(!isVec!(X));

  assert(!isVec!(double[1], int));
  assert(!isVec!(int[2], X));
  assert(!isVec!(X[3], double));

  assert(!isVec!(double[1], 2));
  assert(!isVec!(int[2], 3));
  assert(!isVec!(X[3], 1));
  assert(!isVec!(R!(int, double)));
  assert(!isVec!(R!(X, float)));
}

/// Interpret vector-like value as slice
pure nothrow @nogc @trusted
ref VecType!V[VecSize!V] sliceof(V)(ref V v) if (isVec!V) {
  return * cast(VecType!V[VecSize!V]*) &v;
}

/// Test `sliceof`
nothrow @nogc unittest {
  struct AB(T) {
    T a;
    T b;

    this(const T a_, const T b_) {
      a = a_;
      b = b_;
    }
  }

  /// Immutable data access
  immutable auto iab = AB!float(1.0, 2.0);

  assert_eq(iab.sliceof[0], 1.0);
  assert_eq(iab.sliceof[1], 2.0);

  /// Mutable data access
  auto ab = AB!float(1.0, 2.0);

  assert_eq(ab.sliceof[0], 1.0);
  assert_eq(ab.sliceof[1], 2.0);

  ab.sliceof[0] = 2.0;
  ab.sliceof[1] = 1.0;

  assert_eq(ab.a, 2.0);
  assert_eq(ab.b, 1.0);
}

private template isGenVecArray(alias V) {
  static if (!is(V) && isArray!(typeof(V))) {
    enum bool isGenVecArray = V.length == 1 && isInt!(V[0]);
  } else {
    enum bool isGenVecArray = false;
  }
}

private template isGenVecStruct(alias V) {
  static if (!is(V)) {
    alias X = V!float;
    enum bool isGenVecStruct = is(X == struct) && checkFields!(Fields!X);
  } else {
    enum bool isGenVecStruct = false;
  }
}

/// Check for generic vector
template isGenVec(alias V) {
  static if (isNumer!V || hasUnits!V) {
    enum bool isGenVec = false;
  } else static if (isGenVecArray!V) {
    enum bool isGenVec = V[0] > 0;
  } else static if (isGenVecStruct!V) {
    enum bool isGenVec = Fields!(V!float).length > 0;
  } else {
    enum bool isGenVec = false;
  }
}

/// Test `isGenVec`
nothrow @nogc @safe unittest {
  assert(isGenVec!([1]));
  assert(isGenVec!([3]));
  assert(!isGenVec!([0]));

  struct ABC(T) {
    T a;
    T b;
    T c;
  }

  assert(isGenVec!ABC);

  struct ABX(T) {
    T a;
    T b;
    int c;
  }

  assert(!isGenVec!ABX);
}

/// Get size of generic vector
template genVecSize(alias V) {
  static if (isGenVecArray!V) {
    enum uint genVecSize = V[0];
  } else static if (isGenVecStruct!V) {
    enum uint genVecSize = Fields!(V!float).length;
  }
}

/// Test `genVecSize`
nothrow @nogc @safe unittest {
  assert(genVecSize!([1]) == 1);
  assert(genVecSize!([3]) == 3);

  struct ABC(T) {
    T a;
    T b;
    T c;
  }

  assert(genVecSize!ABC == 3);
}

/// Check for generic vector of given size
template isGenVec(alias V, uint N) {
  enum bool isGenVec = isGenVec!V && genVecSize!V == N;
}

/// Instantiate generic vector
template GenVec(alias V, T) {
  static if (isGenVecArray!V) {
    alias GenVec = T[V[0]];
  } else static if (isGenVecStruct!V) {
    alias GenVec = V!T;
  }
}

/// Test `GenVec`
nothrow @nogc @safe unittest {
  assert(is(GenVec!([1], int) == int[1]));
  assert(is(GenVec!([3], float) == float[3]));

  struct ABC(T) {
    T a;
    T b;
    T c;
  }

  assert(is(GenVec!(ABC, float) == ABC!float));
}

/// Test return generic vector
nothrow @nogc unittest {
  struct ABC(T) {
    T a;
    T b;
    T c;
  }

  auto retVec(alias V, T)(const T x) if (isGenVec!V) {
    GenVec!(V, T) ret;

    static foreach (i; 0..genVecSize!V) {
      ret.sliceof[i] = x;
    }

    return ret;
  }

  // Return as static array
  auto i2 = retVec!([2])(3);

  assert(i2[0] == 3);
  assert(i2[1] == 3);

  /// Return as ABC vector
  auto abc = retVec!ABC(0.25);

  assert(abc.a == 0.25);
  assert(abc.b == 0.25);
  assert(abc.c == 0.25);
}
