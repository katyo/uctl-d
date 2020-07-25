/**
   Fixed-point range-based arithmetic
 */
module fix;

import std.math: fabs, fmin, fmax, pow, log2, floor, ceil;

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

  /// The number is positive
  /// (both rmin and rmax greater than zero)
  enum bool ispos = rmin > 0 && rmax > 0;

  /// The number is negative
  /// (both rmin and rmax less than zero)
  enum bool isneg = rmin < 0 && rmax < 0;

  /// The number is not negative
  /// (both rmin and rmax greater than or equals zero)
  enum bool isntneg = rmin >= 0 && rmax >= 0;

  /// The number is not positive
  /// (both rmin and rmax less than or equals zero)
  enum bool isntpos = rmin <= 0 && rmax <= 0;

  /// Mantissa type
  alias raw_t = raw_type!(bits);

  /// Self type alias
  alias self = fix!(rmin, rmax, bits);

  /// Raw mantisa value
  raw_t raw = 0;

  /// Create number from raw mantissa value
  @safe @nogc
  pure nothrow static
  self from_raw(raw_t val) {
    self ret;
    ret.raw = val;
    return ret;
  }

  /// Create number from generic floating-point value
  @safe @nogc
  pure nothrow
  this(T)(T val) if (is(T) && isFloat!T) {
    auto val2 = val * exp.exp_ratio();
    version(fixRound) {
      val2 += val2 < 0 ? -0.5 : 0.5;
    }
    raw = cast(raw_t) val2;
  }

  /// Create number from generic integer value
  @safe @nogc
  pure nothrow
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
  @safe @nogc
  pure nothrow const
  T to(T)() if (is(T) && isFloat!T) {
    version(fixRound) {
      return ((cast(T) raw) * 2 + (raw < 0 ? -0.5 : 0.5)) * (cast(T) (-exp + 1).exp_ratio());
    } else {
      return (cast(T) raw) * (cast(T) (-exp).exp_ratio());
    }
  }

  /// Convert number into generic integer value
  @safe @nogc
  pure nothrow const
  T to(T)() if (is(T) && isInt!T) {
    static if (exp < 0) {
      version(fixRound) {
        // FIXME: rounding
        return ((raw >> (-exp - 1)) + (raw < 0 ? -1 : 1)) >> 1;
      } else {
        return raw >> (-exp);
      }
    } else {
      return (cast(T) raw) << exp;
    }
  }

  /// Convert number to different range or mantissa width
  @safe @nogc
  pure nothrow const
  T to(T)() if (is(T) && isFixed!T) {
    return T.from_raw(raw.raw_to!(exp, T.exp, T.bits)());
  }

  /// Unified cast operation
  @safe @nogc
  pure nothrow const
  T opCast(T)() if (is(T) && isNumer!T) {
    return to!T();
  }

  /// Negation (unary -)
  @safe @nogc
  pure nothrow const
  self opUnary(string op)() if (op == "-") {
    return from_raw(-raw);
  }

  /// Addition of fixed-point value (binary +)
  @safe @nogc
  pure nothrow const
  fixSum!(self, T) opBinary(string op, T)(T other) if (op == "+" && is(T) && isFixed!T) {
    alias R = fixSum!(self, T);

    auto a = raw.raw_to!(exp, R.exp, R.bits)();
    auto b = other.raw.raw_to!(T.exp, R.exp, R.bits)();

    return R.from_raw(a + b);
  }

  /// Subtraction of fixed-point value (binary -)
  @safe @nogc
  pure nothrow const
  fixDiff!(self, T) opBinary(string op, T)(T other) if (op == "-" && is(T) && isFixed!T) {
    alias R = fixDiff!(self, T);

    auto a = raw.raw_to!(exp, R.exp, R.bits)();
    auto b = other.raw.raw_to!(T.exp, R.exp, R.bits)();

    return R.from_raw(a - b);
  }

  /// Fixed-point multiplication (binary *)
  @safe @nogc
  pure nothrow const
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
  @safe @nogc
  pure nothrow const
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
  @safe @nogc
  pure nothrow const
  fixMod!(self, T) opBinary(string op, T)(T other) if (op == "%" && is(T) && isFixed!T) {
    alias R = fixMod!(self, T);

    auto a = raw;
    auto b = other.raw.raw_to!(T.exp, exp, bits)();

    auto r = (a % b).raw_to!(exp, R.exp, R.bits);

    return R.from_raw(r);
  }
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

/// Create fixed-point constant from floating-point
template asfix(real val, uint bits = 32) {
  enum fix!(val, val, bits) asfix = val;
}

/// Create fixed-point constant from integer
template asfix(int val, uint bits = 32) {
  enum fix!(cast(real) val, cast(real) val, bits) asfix = val;
}

@safe @nogc
pure nothrow
int estimate_exp(real lim) {
  auto lim2 = lim < real.epsilon ? 1 : lim;
  auto exp = lim2.log2();
  auto exp2 = fabs(exp) < real.epsilon ? 1 : cast(int) exp.ceil();
  return exp2;
}

@safe @nogc
pure nothrow
real exp_ratio(int exp, real radix = 2) {
  return radix.pow(-exp);
}

@safe @nogc
pure nothrow
T max(T)(T a, T b) if (is(T) && isNumer!T) {
  return a > b ? a : b;
}

@safe @nogc
pure nothrow
raw_type!(rbits) raw_to_bits(uint rbits, T)(T raw) if (is(T) && isInt!T) {
  return cast(raw_type!(rbits)) raw;
}

@safe @nogc
pure nothrow
T raw_to_exp(int exp, int rexp, T)(T raw) if (is(T) && isInt!T) {
  static if (rexp < exp) {
    return raw << (exp - rexp);
  } else static if (rexp > exp) {
    // TODO: rounding
    return raw >> (rexp - exp);
  } else {
    return raw;
  }
}

@safe @nogc
pure nothrow
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

/// Check when type or expr is floating-point number
template isFloat(X...) if (X.length == 1) {
  enum bool isFloat = __traits(isArithmetic, X[0]) && __traits(isFloating, X[0]) && __traits(isScalar, X[0]);
}

/// Check when type or expr is integer number
template isInt(X...) if (X.length == 1) {
  enum bool isInt = __traits(isArithmetic, X[0]) && __traits(isIntegral, X[0]) && __traits(isScalar, X[0]) && !isChar!(X[0]);
}

/// Check when type or expr is numeric
template isNumer(X...) if (X.length == 1) {
  enum bool isNumer = isFloat!(X[0]) || isInt!(X[0]) || isFixed!(X[0]);
}

/// Check when type or expr is character
template isChar(X...) if (X.length == 1) {
  static if (is(X[0])) {
    enum bool isChar = is(X[0] == char);
  } else {
    enum bool isChar = isChar!(typeof(X[0]));
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

/// Get number of bits of specified type
template bitsOf(X...) if (X.length == 1) {
  static if (is(X[0])) {
    enum uint bitsOf = X[0].sizeof * 8;
  } else {
    enum uint bitsOf = bitsOf!(typeof(X[0]));
  }
}

/// Test `isFloat`
@safe @nogc nothrow unittest {
  assert(isFloat!float);
  assert(isFloat!double);
  assert(isFloat!real);
  assert(isFloat!1.0);

  assert(!isFloat!byte);
  assert(!isFloat!int);
  assert(!isFloat!long);
  assert(!isFloat!ubyte);
  assert(!isFloat!uint);
  assert(!isFloat!ulong);
  assert(!isFloat!1);
  assert(!isFloat!char);
  assert(!isFloat!'a');
  assert(!isFloat!"abc");
}

/// Test `isInt`
@safe @nogc nothrow unittest {
  assert(isInt!byte);
  assert(isInt!int);
  assert(isInt!long);
  assert(isInt!ubyte);
  assert(isInt!uint);
  assert(isInt!ulong);
  assert(isInt!1);

  assert(!isInt!float);
  assert(!isInt!double);
  assert(!isInt!real);
  assert(!isInt!1.0);
  assert(!isInt!char);
  assert(!isInt!'a');
  assert(!isInt!"abc");
}

/// Test `isFixed`
@safe @nogc nothrow unittest {
  assert(isFixed!(fix!(0, 1)));
  assert(isFixed!(fix!(0, 1)(1.23)));
  assert(!isFixed!float);
  assert(!isFixed!double);
  assert(!isFixed!real);
  assert(!isFixed!int);
  assert(!isFixed!1.23);
  assert(!isFixed!123);
}

/// Test exponent extimation
@safe @nogc nothrow unittest {
  assert(fix!(0).exp == -30); // -31
  assert(fix!(0.8).exp == -31);
  assert(fix!(0, 0.1).exp == -34);
  assert(fix!(-0.1, 0).exp == -34);
  assert(fix!(0, 0.5).exp == -32);
  assert(fix!(0, 1).exp == -30); // -31
  assert(fix!(0, 100).exp == -24);
  assert(fix!(-100, 0).exp == -24);
  assert(fix!(-100, 100).exp == -24);
  assert(fix!(-100, 1000).exp == -21);
  assert(fix!(100000000).exp == -4);
  assert(fix!(1000000000).exp == -1);
  assert(fix!(10000000000).exp == 3);
  assert(fix!(100000000000).exp == 6);
}

/// Test step (or precision)
@safe @nogc nothrow unittest {
  assert(fix!(1).step.to!double() == 9.313225746154785e-10); //4.656612873077393e-10
  assert(fix!(10).step.to!double() == 7.450580596923828e-9);
  assert(fix!(100).step.to!double() == 5.960464477539063e-8);
  assert(fix!(1000).step.to!double() == 4.76837158203125e-7);
  assert(fix!(100000000).step.to!double() == 0.0625);
  assert(fix!(1000000000).step.to!double() == 0.5);
  assert(fix!(10000000000).step.to!double() == 8);
  assert(fix!(100000000000).step.to!double() == 64);

  assert(fix!(-100, 100)(10).to!double() == 10);
  assert(fix!(-100, 100)(10).to!int() == 10);
  assert(fix!(-100, 100)(0.5).to!double() == 0.5);

  assert(fix!(-100, 100)(0.3).to!int() == 0);
  assert(fix!(-100, 100)(1.3).to!int() == 1);

  version(fixRound) {
    //assert(fix!(-100, 100)(0.5).to!int() == 1);
    //assert(fix!(-100, 100)(1.5).to!int() == 2);
  }
}

/// Test `asfix`
@safe @nogc nothrow unittest {
  assert(asfix!0.exp == -30); // -31
  assert(asfix!0.to!double() == 0);

  assert(asfix!1.exp == -30); // -31
  assert(asfix!1.to!double == 1);

  assert(asfix!(0.1).exp == -34);
  assert(asfix!(0.1).to!double() == 0.09999999997671694);

  assert(asfix!(100).exp == -24);
  assert(asfix!(100).to!double() == 100);
}

/// Test adjustment
@safe @nogc nothrow unittest {
  assert(fix!(-10, 10)(5).to!(fix!(-10, 100)) == fix!(-10, 100)(5));
  assert(fix!(-10, 10)(5).to!(fix!(-10, 100)).to!int() == 5);
  assert(fix!(-10, 10)(1.5).to!(fix!(-10, 100)) == fix!(-10, 100)(1.5));
}

/// Test negation
@safe @nogc nothrow unittest {
  assert((-fix!(-100, 100)(5)).to!double() == -5);
  assert((-fix!(-100, 100)(5)).to!int() == -5);
  assert((-fix!(-100, 100)(5)) == fix!(-100, 100)(-5));
  assert((-fix!(-100, 100)(-0.5)).to!double() == 0.5);
  assert((-fix!(-100, 100)(-0.5)) == fix!(-100, 100)(0.5));
}

/// Test addition
@safe @nogc nothrow unittest {
  assert(fix!(-100, 200)(1.23) + fix!(-20, 10)(5) == fix!(-120, 210)(6.23));
}

/// Test subtraction
@safe @nogc nothrow unittest {
  assert(fix!(-100, 200)(1.25) - fix!(-20, 10)(5.3) == fix!(-110, 220)(-4.05));
}

/// Test multiplication
@safe @nogc nothrow unittest {
  assert(fix!(-100, 200)(1.25) * fix!(-20, 10)(5.3) == fix!(-4000, 2000)(6.624999));
  //assert(asfix!(1.25) * asfix!(5.3) == asfix!(6.625));
}

/// Test division
@safe @nogc nothrow unittest {
  assert(fix!(-4000, 2000)(6.625) / fix!(-20, 10)(5.3) == fix!(-400, 200)(1.25));

/// Test remainder
@nogc nothrow unittest {
  assert(fix!(-100, 50)(11.25) % fix!(-10, 20)(3.5) == fix!(-20, 20)(0.75));
}

// support for standalone unit testing without a runtime
version(D_BetterC) {
  version(unittest) {
    extern(C) void main() {
      static foreach(unitTest; __traits(getUnitTests, __traits(parent, main)))
        unitTest();
    }
  }
}
