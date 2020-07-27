/**
   Fixed-point range-based arithmetic
 */
module fix;

import std.math: fabs, fmin, fmax, pow, log2, floor, ceil;
import num: isInt, isFloat, isNum, bitsOf;

version(unittest) {
  import test: assert_eq;
}

/**
   Fixed-point range-based numeric type

   TODO:
 */
struct fix(real rmin_, real rmax_ = rmin_, uint bits_ = 32) {
  static assert(rmin_ <= rmax_, "Invalid range: minimum should be less than or equals to maximum.");

  /// Real minimum
  static const real rmin = rmin_;
  /// Real maximum
  static const real rmax = rmax_;
  /// Number of mantissa bits
  static const uint bits = bits_;

  /// Real limit (absolute maximum)
  static const real rlim = fmax(fabs(rmin), fabs(rmax));

  /// Exponent of number
  static const int exp = rlim.estimate_exp() - bits + 1;

  /// Minimum value
  static const self min = rmin;
  /// Maximum value
  static const self max = rmax;
  /// Stepping value (precision)
  static const self step = from_raw(1);

  /// Number is positive
  /// (both rmin and rmax greater than zero)
  enum bool ispos = rmin > 0 && rmax > 0;

  /// Number is negative
  /// (both rmin and rmax less than zero)
  enum bool isneg = rmin < 0 && rmax < 0;

  /// Number is not negative
  /// (both rmin and rmax greater than or equals zero)
  enum bool isntneg = rmin >= 0 && rmax >= 0;

  /// Number is not positive
  /// (both rmin and rmax less than or equals zero)
  enum bool isntpos = rmin <= 0 && rmax <= 0;

  /// Number has integer part
  enum bool hasint = fabs(rmin) >= 1.0 || fabs(rmax) >= 1.0;

  /// Number has fraction part
  enum bool hasfrac = exp < 0;

  /// Mantissa type
  alias raw_t = raw_type!(bits);

  /// Self type alias
  alias self = fix!(rmin, rmax, bits);

  /// Raw mantisa value
  raw_t raw = 0;

  /// Create number from raw mantissa value
  pure nothrow @nogc @safe static
  self from_raw(raw_t val) {
    self ret;
    ret.raw = val;
    return ret;
  }

  /// Create number from generic floating-point value
  const pure nothrow @nogc @safe
  this(T)(T val) if (is(T) && isFloat!T) {
    auto val2 = val * (cast(real) 2).pow(-exp);
    version(fixRound) {
      val2 += val2 < 0 ? -0.5 : 0.5;
    }
    raw = cast(raw_t) val2;
  }

  /// Create number from generic integer value
  const pure nothrow @nogc @safe
  this(T)(T val) if (is(T) && isInt!T) {
    static if (bitsOf!T > bitsOf!raw_t) {
      auto val2 = val;
    } else {
      auto val2 = cast(raw_t) val;
    }

    static if (exp < 0) {
      /*version(fixRound) {
        val2 = ((val2 << (-exp + 1)) + (val2 < 0 ? -1 : 1)) >> 1;
      } else {
        val2 = val2 << -exp;
      }*/
      val2 = val2 << -exp;
    } else {
      version(fixRound) {
        val2 = ((val2 >> (exp - 1)) + (val2 < 0 ? -1 : 1)) >> 1;
      } else {
        val2 = val2 >> exp;
      }
    }

    static if (bitsOf!T > bitsOf!raw_t) {
      raw = cast(raw_t) val2;
    } else {
      raw = val2;
    }
  }

  /// Convert number into generic floating-point value
  const pure nothrow @nogc @safe
  T opCast(T)() if (is(T) && isFloat!T) {
    return (cast(T) raw) * (cast(T) (cast(real) 2).pow(exp));
  }

  /// Convert number into generic integer value
  const pure nothrow @nogc @safe
  T opCast(T)() if (is(T) && isInt!T) {
    static if (exp < 0) {
      version(fixRound) {
        // FIXME: rounding
        return ((raw >> (-exp - 1)) + (raw < 0 ? -1 : 1)) >> 1;
      } else {
        return raw >> -exp;
      }
    } else {
      return (cast(T) raw) << exp;
    }
  }

  /// Convert number to different range or mantissa width
  const pure nothrow @nogc @safe
  T opCast(T)() if (is(T) && isFixed!T) {
    return T.from_raw(raw.raw_to!(exp, T.exp, T.bits)());
  }

  /// Unified cast operation
  const pure nothrow @nogc @safe
  T to(T)() if (is(T) && isNumer!T) {
    return cast(T) this;
  }

  /// Negation (unary -)
  const pure nothrow @nogc @safe
  fixNeg!(self) opUnary(string op)() if (op == "-") {
    alias R = fixNeg!(self);

    return R.from_raw(-raw);
  }

  /// Addition of fixed-point value (binary +)
  const pure nothrow @nogc @safe
  fixSum!(self, T) opBinary(string op, T)(T other) if (op == "+" && is(T) && isFixed!T) {
    alias R = fixSum!(self, T);

    auto a = raw.raw_to!(exp, R.exp, R.bits)();
    auto b = other.raw.raw_to!(T.exp, R.exp, R.bits)();

    return R.from_raw(a + b);
  }

  /// Subtraction of fixed-point value (binary -)
  const pure nothrow @nogc @safe
  fixDiff!(self, T) opBinary(string op, T)(T other) if (op == "-" && is(T) && isFixed!T) {
    alias R = fixDiff!(self, T);

    auto a = raw.raw_to!(exp, R.exp, R.bits)();
    auto b = other.raw.raw_to!(T.exp, R.exp, R.bits)();

    return R.from_raw(a - b);
  }

  /// Fixed-point multiplication (binary *)
  const pure nothrow @nogc @safe
  fixProd!(self, T) opBinary(string op, T)(T other) if (op == "*" && is(T) && isFixed!T) {
    alias R = fixProd!(self, T);

    enum uint op_bits = bits + T.bits;
    enum uint op_exp = exp + T.exp;

    auto a = raw.raw_to_bits!op_bits();
    auto b = other.raw.raw_to_bits!op_bits();

    auto r = (a * b).raw_to!(op_exp, R.exp, R.bits)();

    return R.from_raw(r);
  }

  /// Fixed-point division (binary /)
  const pure nothrow @nogc @safe
  fixQuot!(self, T) opBinary(string op, T)(T other) if (op == "/" && is(T) && isFixed!T) {
    alias R = fixQuot!(self, T);

    enum uint op_bits = T.bits + R.bits;
    enum uint op_exp = T.exp + R.exp;

    auto a = raw.raw_to!(exp, op_exp, op_bits)();
    auto b = other.raw.raw_to_bits!op_bits();

    auto r = (a / b).raw_to_bits!(R.bits)();

    return R.from_raw(r);
  }

  /// Fixed-point remainder (binary %)
  const pure nothrow @nogc @safe
  fixMod!(self, T) opBinary(string op, T)(T other) if (op == "%" && is(T) && isFixed!T) {
    alias R = fixMod!(self, T);

    auto a = raw;
    auto b = other.raw.raw_to!(T.exp, exp, bits)();

    auto r = (a % b).raw_to!(exp, R.exp, R.bits);

    return R.from_raw(r);
  }
}

/// Test exponent estimation
nothrow @nogc unittest {
  assert_eq(fix!(0).exp, -30); // -31
  assert_eq(fix!(0.8).exp, -31);
  assert_eq(fix!(0, 0.1).exp, -34);
  assert_eq(fix!(-0.1, 0).exp, -34);
  assert_eq(fix!(0, 0.5).exp, -32);
  assert_eq(fix!(0, 1).exp, -30); // -31
  assert_eq(fix!(0, 100).exp, -24);
  assert_eq(fix!(-100, 0).exp, -24);
  assert_eq(fix!(-100, 100).exp, -24);
  assert_eq(fix!(-100, 1000).exp, -21);
  assert_eq(fix!(100000000).exp, -4);
  assert_eq(fix!(1000000000).exp, -1);
  assert_eq(fix!(10000000000).exp, 3);
  assert_eq(fix!(100000000000).exp, 6);
}

/// Test step (or precision)
nothrow @nogc unittest {
  assert_eq(cast(double) fix!(1).step, 9.313225746154785e-10); //4.656612873077393e-10
  assert_eq(cast(double) fix!(10).step, 7.450580596923828e-9);
  assert_eq(cast(double) fix!(100).step, 5.960464477539063e-8);
  assert_eq(cast(double) fix!(1000).step, 4.76837158203125e-7);
  assert_eq(cast(double) fix!(100000000).step, 0.0625);
  assert_eq(cast(double) fix!(1000000000).step, 0.5);
  assert_eq(cast(double) fix!(10000000000).step, 8);
  assert_eq(cast(double) fix!(100000000000).step, 64);
}

/// Test casting
nothrow @nogc unittest {
  assert_eq(cast(double) fix!(-100, 100)(10), 10);
  assert_eq(cast(int) fix!(-100, 100)(10), 10);
  assert_eq(cast(float) fix!(-100, 100)(0.5), 0.5);

  assert_eq(cast(int) fix!(-100, 100)(0.3), 0);
  assert_eq(cast(int) fix!(-100, 100)(1.3), 1);

  version(fixRound) {
    assert_eq(cast(int) fix!(-100, 100)(0.5), 1);
    assert_eq(cast(int) fix!(-100, 100)(1.5), 2);
  }
}

/// Test casting fixed
nothrow @nogc unittest {
  assert_eq(cast(fix!(-10, 100)) fix!(-10, 10)(5), fix!(-10, 100)(5));
  assert_eq(cast(int) cast(fix!(-10, 100)) fix!(-10, 10)(5), 5);
  assert_eq(cast(fix!(-10, 100)) fix!(-10, 10)(1.5), fix!(-10, 100)(1.5));
}

/// Test negation
nothrow @nogc unittest {
  assert_eq(-fix!(-100, 200)(5), fix!(-200, 100)(-5));
  assert_eq(-fix!(-22, 11)(-0.5), fix!(-11, 22)(0.5));
}

/// Test addition
nothrow @nogc unittest {
  assert_eq(fix!(-100, 200)(1.23) + fix!(-20, 10)(5), fix!(-120, 210)(6.23));
}

/// Test subtraction
nothrow @nogc unittest {
  assert_eq(fix!(-100, 200)(1.25) - fix!(-20, 10)(5.3), fix!(-110, 220)(-4.05));
}

/// Test multiplication
nothrow @nogc unittest {
  version(fixRound) {
    assert_eq(fix!(-100, 200)(1.25) * fix!(-20, 10)(5.3), fix!(-4000, 2000)(6.625));
    assert_eq(asfix!(1.25) * asfix!(5.3), asfix!(6.625));
  } else {
    assert_eq(fix!(-100, 200)(1.25) * fix!(-20, 10)(5.3), fix!(-4000, 2000)(6.624999));
  }
}

/// Test division
nothrow @nogc unittest {
  assert_eq(fix!(-4000, 2000)(6.625) / fix!(-20, 10)(5.3), fix!(-400, 200)(1.25));
}

/// Test remainder
nothrow @nogc unittest {
  assert_eq(fix!(-100, 50)(11.25) % fix!(-10, 20)(3.5), fix!(-20, 20)(0.75));
}

/// The result of negation
template fixNeg(T) if (is(T) && isFixed!T) {
  enum real rmin = -T.rmax;
  enum real rmax = -T.rmin;

  enum uint bits = T.bits;

  alias fixNeg = fix!(rmin, rmax, bits);
}

/// The result of fixed-point addition
template fixSum(A, B) if (is(A) && isFixed!A && is(B) && isFixed!B) {
  enum real rmin = A.rmin + B.rmin;
  enum real rmax = A.rmax + B.rmax;

  enum uint bits = max(A.bits, B.bits);

  alias fixSum = fix!(rmin, rmax, bits);
}

/// The result of fixed-point subtraction
template fixDiff(A, B) if (is(A) && isFixed!A && is(B) && isFixed!B) {
  enum real rmin = A.rmin - B.rmax;
  enum real rmax = A.rmax - B.rmin;

  enum uint bits = max(A.bits, B.bits);

  alias fixDiff = fix!(rmin, rmax, bits);
}

/// The result of fixed-point multiplication
template fixProd(A, B) if (is(A) && isFixed!A && is(B) && isFixed!B) {
  enum real minXmin = A.rmin * B.rmin;
  enum real minXmax = A.rmin * B.rmax;
  enum real maxXmin = A.rmax * B.rmin;
  enum real maxXmax = A.rmax * B.rmax;

  enum real rmin = fmin(fmin(minXmin, minXmax), fmin(maxXmin, maxXmax));
  enum real rmax = fmax(fmax(minXmin, minXmax), fmax(maxXmin, maxXmax));

  enum uint bits = max(A.bits, B.bits);

  alias fixProd = fix!(rmin, rmax, bits);
}

/// The result of fixed-point division
template fixQuot(A, B) if (is(A) && isFixed!A && is(B) && isFixed!B) {
  enum real minXmin = A.rmin / B.rmin;
  enum real minXmax = A.rmin / B.rmax;
  enum real maxXmin = A.rmax / B.rmin;
  enum real maxXmax = A.rmax / B.rmax;

  enum real rmin = fmin(fmin(minXmin, minXmax), fmin(maxXmin, maxXmax));
  enum real rmax = fmax(fmax(minXmin, minXmax), fmax(maxXmin, maxXmax));

  enum uint bits = max(A.bits, B.bits);

  alias fixQuot = fix!(rmin, rmax, bits);
}

/// The result of fixed-point remainder
template fixMod(A, B) if (is(A) && isFixed!A && is(B) && isFixed!B) {
  enum real rlim = fmax(fabs(B.rmin), fabs(B.rmax));

  enum real rmin = A.isntneg ? 0.0 : -rlim;
  enum real rmax = A.isntpos ? 0.0 : rlim;

  enum uint bits = B.bits;

  alias fixMod = fix!(rmin, rmax, bits);
}

/// Create fixed-point constant from an arbitrary number
///
/// This macro accepts optional number of mantissa bits which is set to 32 by default.
template asfix(X...) if ((X.length == 1 || X.length == 2) && is(typeof(X[0])) && isNum!(typeof(X[0])) && (X.length == 1 || is(typeof(X[1]) == int) && X[1] <= 64)) {
  static if (X.length == 2) {
    enum uint bits = X[1];
  } else {
    enum uint bits = 32;
  }
  enum fix!(cast(real) X[0], cast(real) X[0], bits) asfix = X[0];
}

/// Test `asfix`
nothrow @nogc unittest {
  assert_eq(asfix!0.exp, -30); // -31
  assert_eq(cast(double) asfix!0, 0);

  assert_eq(asfix!1.exp, -30); // -31
  assert_eq(cast(double) asfix!1, 1);

  assert_eq(asfix!0.1.exp, -34);
  assert_eq(cast(double) asfix!0.1, 0.09999999997671694);

  assert_eq(asfix!100.exp, -24);
  assert_eq(cast(double) asfix!100, 100);

  assert(is(typeof(asfix!(100, 64).raw) == long));
  assert_eq(asfix!(100, 64).exp, -56);
  assert_eq(cast(double) asfix!(100, 64), 100);
}

pure nothrow @nogc @safe
int estimate_exp(real lim) {
  auto lim2 = lim < real.epsilon ? 1 : lim;
  auto exp = lim2.log2();
  auto exp2 = fabs(exp) < real.epsilon ? 1 : cast(int) exp.ceil();
  return exp2;
}

pure nothrow @nogc @safe
T max(T)(T a, T b) if (is(T) && isNum!T) {
  return a > b ? a : b;
}

pure nothrow @nogc @safe
raw_type!(rbits) raw_to_bits(uint rbits, T)(T raw) if (is(T) && isInt!T) {
  return cast(raw_type!(rbits)) raw;
}

pure nothrow @nogc @safe
T raw_to_exp(int exp, int rexp, T)(T raw) if (is(T) && isInt!T) {
  static if (rexp < exp) {
    return raw << (exp - rexp);
  } else static if (rexp > exp) {
    version(fixRound) {
      // FIXME: rounding
      // raw + 0.5 <=> (raw * 2 + 1) / 2
      return ((raw >> (rexp - exp - 1)) + 1) >> 1;
    } else {
      return raw >> (rexp - exp);
    }
  } else {
    return raw;
  }
}

pure nothrow @nogc @safe
raw_type!(rbits) raw_to(int exp, int rexp, uint rbits, T)(T raw) if (is(T) && isInt!T) {
  enum uint bits = bitsOf!T;
  static if (rexp < exp && rbits > bits) {
    return raw.raw_to_bits!(rbits)().raw_to_exp!(exp, rexp)();
  } else {
    return raw.raw_to_exp!(exp, rexp)().raw_to_bits!(rbits)();
  }
}

/// Selects appropriate mantissa type by width in bits
template raw_type(uint bits) {
  static if (bits <= 8 && is(byte)) {
    alias raw_type = byte;
  } else static if (bits <= 16 && is(short)) {
    alias raw_type = short;
  } else static if (bits <= 32 && is(int)) {
    alias raw_type = int;
  } else static if (bits <= 64 && is(long)) {
    alias raw_type = long;
  } else static if (bits <= 128 && is(cent)) {
    alias raw_type = cent;
  } else {
    static assert(0, "Unsupported bits width: " ~ bits.stringof);
  }
}

/// Check when type or expr is fixed-point number
template isFixed(X...) if (X.length == 1) {
  static if (is(X[0])) {
    static if (__traits(hasMember, X[0], "rmin") && __traits(hasMember, X[0], "rmax") && __traits(hasMember, X[0], "bits")) {
      enum bool isFixed = is(X[0] == fix!(X[0].rmin, X[0].rmax, X[0].bits));
    }  else {
      enum bool isFixed = false;
    }
  } else {
    enum bool isFixed = isFixed!(typeof(X[0]));
  }
}

/// Test `isFixed`
nothrow @nogc @safe unittest {
  assert(isFixed!(fix!(0, 1)));
  assert(isFixed!(fix!(0, 1)(1.23)));
  assert(!isFixed!float);
  assert(!isFixed!double);
  assert(!isFixed!real);
  assert(!isFixed!int);
  assert(!isFixed!1.23);
  assert(!isFixed!123);
}

/// Check when type or expr is numeric
template isNumer(X...) if (X.length == 1) {
  enum bool isNumer = isFloat!(X[0]) || isInt!(X[0]) || isFixed!(X[0]);
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
