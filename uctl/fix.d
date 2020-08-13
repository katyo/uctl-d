/**
   Fixed-point range-based arithmetic
 */
module uctl.fix;

import std.traits: isInstanceOf;
import std.algorithm.comparison: max;
import std.math: fabs, fmin, fmax, pow, log2, floor, ceil;
import uctl.num: isInt, isFloat, isNum, bitsOf, filledBits;

version(unittest) {
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

version(fixDouble) {
  alias real_t = double;
} else {
  version(fixFloat) {
    alias real_t = float;
  } else {
    alias real_t = real;
  }
}

version(fixRoundToNearest) {
  version = fixRoundTo;
} else {
  version(fixRoundToZero) {
    version = fixRoundTo;
  } else {
    version = fixRoundDown;
  }
}

private pure nothrow @nogc @safe
int estimate_exp(real_t min, real_t max, uint bits)
in (min <= max)
in (bits <= 64)
do {
  if (fabs(min) <= real_t.epsilon && fabs(max) < real_t.epsilon) {
    return 1 - cast(int) bits;
  }

  auto lim = fmax(fabs(min), fabs(max));
  auto dig = cast(int) lim.log2().ceil();
  auto exp = dig + 1 - cast(int) bits;

  auto alim = (cast(real_t) 2).pow(dig);
  auto amin = -alim;
  auto amax = alim - (cast(real_t) 2).pow(exp);

  if (min < amin || max > amax) {
    exp += 1;
  }

  return exp;
}

/**
   Select mantissa type

   Selects appropriate mantissa type by width in bits.
*/
private template raw_type(uint bits) {
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

/**
  Convert mantissa bits only

  Converts mantissa type to `rbits`.
*/
private pure nothrow @nogc @safe
raw_type!(rbits) raw_to(uint rbits, T)(T raw) if (is(T) && isInt!T) {
  return cast(typeof(return)) raw;
}

/**
   Convert mantissa exponent only

   Converts mantissa exponent from `exp` to `rexp`.
*/
private pure nothrow @nogc @safe
raw_type!(bitsOf!T) raw_to(int exp, int rexp, T)(T raw) if (is(T) && isInt!T) {
  return raw.raw_to!(exp, rexp, bitsOf!T);
}

/**
   Convert both mantissa exponent and bits

   Converts mantissa exponent from `exp` to `rexp` and bits to `rbits`.
*/
private pure nothrow @nogc @safe
raw_type!(rbits) raw_to(int exp, int rexp, uint rbits, T)(const T raw) if (is(T) && isInt!T) {
  enum uint bits = bitsOf!T;

  static if (rexp < exp && rbits > bits) {
    // adjust raw type first
    auto raw2 = raw.raw_to!rbits;
  } else {
    auto raw2 = raw;
  }

  static if (rexp < exp) {
    enum int dexp = exp - rexp;
    auto raw3 = raw2 << dexp;
  } else static if (rexp > exp) {
    enum int dexp = rexp - exp;
    enum typeof(raw2) half = 1 << (dexp - 1);
    enum typeof(raw2) one = 1 << dexp;

    version(fixRoundToNearest) {
      // FIXME: rounding ~ floor(raw + 0.5)
      auto raw21 = raw2 + (raw2 < 0 ? -half : half);
    }

    version(fixRoundToZero) {
      auto raw21 = raw2 < 0 ? raw2 + one : raw2;
    }

    version(fixRoundDown) {
      auto raw21 = raw2;
    }

    auto raw3 = raw21 >> dexp;
    //auto raw3 = raw21 / one;
  } else {
    auto raw3 = raw2;
  }

  static if (rexp < exp && rbits > bits) {
    auto raw4 = raw3;
  } else {
    // finally adjust raw type
    auto raw4 = raw3.raw_to!rbits;
  }

  return raw4;
}

nothrow @nogc unittest {
  version(fixRoundDown) {
    assert_eq(0b01010.raw_to!(0, 1), 0b0101);
    assert_eq(0b01010.raw_to!(0, 2), 0b010);
    assert_eq(0b01010.raw_to!(0, 3), 0b01);
    assert_eq((-0b01010).raw_to!(0, 1), -0b0101);
    assert_eq((-0b01010).raw_to!(0, 2), -0b011);
    assert_eq((-0b01010).raw_to!(0, 3), -0b10);
  }
  version(fixRoundToNearest) {
    assert_eq(0b01010.raw_to!(0, 1), 0b0101);
    assert_eq(0b01010.raw_to!(0, 2), 0b011);
    assert_eq(0b01010.raw_to!(0, 3), 0b01);
    assert_eq((-0b01010).raw_to!(0, 1), -0b0101);
    assert_eq((-0b01010).raw_to!(0, 2), -0b011);
    assert_eq((-0b01010).raw_to!(0, 3), -0b10);
  }
}

/**
   Fixed-point range-based numeric type

   TODO:

   See also: [Interval arithmetic](https://en.wikipedia.org/wiki/Interval_arithmetic).
 */
struct fix(real_t rmin_, real_t rmax_ = rmin_, uint bits_ = 32) {
  static assert(rmin_ != real_t.nan, "Invalid range: minimum is not a number");
  static assert(rmax_ != real_t.nan, "Invalid range: Maximum is not a number");
  static assert(rmin_ != -real_t.infinity, "Invalid range: minimum of range is -∞");
  static assert(rmax_ != -real_t.infinity, "Invalid range: maximum of range is -∞");
  static assert(rmin_ != real_t.infinity, "Invalid range: minimum of range is +∞");
  static assert(rmax_ != real_t.infinity, "Invalid range: maximum of range is +∞");
  static assert(rmin_ <= rmax_, "Invalid range: minimum should be less than or equals to maximum.");

  /// Real minimum
  enum real_t rmin = rmin_;
  /// Real maximum
  enum real_t rmax = rmax_;

  /// Number of mantissa bits
  enum uint bits = bits_;

  /// Exponent of number
  enum int exp = estimate_exp(rmin, rmax, bits);

  /// Minimum value
  enum self min = rmin;
  /// Maximum value
  enum self max = rmax;
  /// Stepping value (precision)
  enum self step = from_raw(1);

  /// Zero value
  enum self zero = from_raw(0);

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

  enum raw_t intmask = filledBits!(raw_t, -exp, bits);

  enum raw_t fracmask = filledBits!(raw_t, 0, -exp);

  /// Self type alias
  alias self = typeof(this);

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
  this(T)(const T val) if (is(T) && isFloat!T) {
    T val2 = val * (cast(T) 2).pow(-exp);
    val2 += val2 < 0 ? -0.5 : 0.5;
    raw = cast(raw_t) val2;
  }

  /// Create number from generic integer value
  const pure nothrow @nogc @safe
  this(T)(const T val) if (is(T) && isInt!T) {
    raw = val.raw_to!(0, exp, bits);
  }

  /// Convert number into generic floating-point value
  const pure nothrow @nogc @safe
  T opCast(T)() if (is(T) && isFloat!T) {
    return (cast(T) raw) * (cast(T) (cast(real_t) 2).pow(exp));
  }

  /// Convert number into generic integer value
  const pure nothrow @nogc @safe
  T opCast(T)() if (is(T) && isInt!T) {
    return raw.raw_to!(exp, 0, bitsOf!T)();
  }

  /// Convert number to different range or mantissa width
  const pure nothrow @nogc @safe
  this(T)(const T other) if (is(T) && isFixed!T) {
    raw = other.raw.raw_to!(T.exp, exp, bits)();
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

  /// Get integer part of number
  const pure nothrow @nogc @property @safe
  auto intof() {
    enum real_t Rrmin = rmin.abs_floor();
    enum real_t Rrmax = rmax.abs_floor();

    enum uint Rbits = bits;

    alias R = fix!(Rrmin, Rrmax, Rbits);

    static if (!hasint) {
      return R.zero;
    } else static if (hasfrac) {
      raw_t raw2 = raw & intmask;
      if (raw < 0 && raw2 < raw) raw2 += fracmask + 1;
      return R.from_raw(raw2.raw_to!(exp, R.exp, R.bits));
    } else {
      return R(this);
    }
  }

  /// Get fraction part of number
  const pure nothrow @nogc @property @safe
  auto fracof() {
    static if (hasfrac) {
      enum real_t Rrmin = fmin(fmax(rmin, -1.0), 1.0);
      enum real_t Rrmax = fmax(fmin(rmax, 1.0), -1.0);
    } else {
      enum real_t Rrmin = 0.0;
      enum real_t Rrmax = 0.0;
    }

    enum uint Rbits = bits;

    alias R = fix!(Rrmin, Rrmax, Rbits);

    static if (hasfrac) {
      return R(this % asfix!(1));
    } else {
      return R.zero;
    }
  }

  /// Negation (unary -)
  const pure nothrow @nogc @safe
  auto opUnary(string op)() if (op == "-") {
    enum real_t Rrmin = -rmax;
    enum real_t Rrmax = -rmin;

    enum uint Rbits = bits;

    alias R = fix!(Rrmin, Rrmax, Rbits);

    return R.from_raw(-raw);
  }

  /// Addition of fixed-point value (binary +)
  const pure nothrow @nogc @safe
  auto opBinary(string op, T)(const T other) if (op == "+" && is(T) && isFixed!T) {
    enum real_t Rrmin = rmin + T.rmin;
    enum real_t Rrmax = rmax + T.rmax;

    enum uint Rbits = max2(bits, T.bits);

    alias R = fix!(Rrmin, Rrmax, Rbits);

    auto a = raw.raw_to!(exp, R.exp, R.bits)();
    auto b = other.raw.raw_to!(T.exp, R.exp, R.bits)();

    return R.from_raw(a + b);
  }

  /// Subtraction of fixed-point value (binary -)
  const pure nothrow @nogc @safe
  auto opBinary(string op, T)(const T other) if (op == "-" && is(T) && isFixed!T) {
    enum real_t Rrmin = rmin - T.rmax;
    enum real_t Rrmax = rmax - T.rmin;

    enum uint Rbits = max2(bits, T.bits);

    alias R = fix!(Rrmin, Rrmax, Rbits);

    auto a = raw.raw_to!(exp, R.exp, R.bits)();
    auto b = other.raw.raw_to!(T.exp, R.exp, R.bits)();

    return R.from_raw(a - b);
  }

  /// Fixed-point multiplication (binary *)
  const pure nothrow @nogc @safe
  auto opBinary(string op, T)(const T other) if (op == "*" && is(T) && isFixed!T) {
    enum real_t minXmin = rmin * T.rmin;
    enum real_t minXmax = rmin * T.rmax;
    enum real_t maxXmin = rmax * T.rmin;
    enum real_t maxXmax = rmax * T.rmax;

    enum real_t Rrmin = fmin(fmin(minXmin, minXmax), fmin(maxXmin, maxXmax));
    enum real_t Rrmax = fmax(fmax(minXmin, minXmax), fmax(maxXmin, maxXmax));

    enum uint Rbits = max2(bits, T.bits);

    alias R = fix!(Rrmin, Rrmax, Rbits);

    enum uint op_bits = bits + T.bits;
    enum uint op_exp = exp + T.exp;

    auto a = raw.raw_to!op_bits();
    auto b = other.raw.raw_to!op_bits();

    auto r = (a * b).raw_to!(op_exp, R.exp, R.bits)();

    return R.from_raw(r);
  }

  /// Fixed-point division (binary /)
  const pure nothrow @nogc @safe
  auto opBinary(string op, T)(const T other) if (op == "/" && is(T) && isFixed!T) {
    static assert(((T.rmin < 0 && T.rmax < 0) || (T.rmin > 0 && T.rmax > 0)), "Fixed-point division is undefined for divider which can be zero.");

    enum real_t minXmin = rmin / T.rmin;
    enum real_t minXmax = rmin / T.rmax;
    enum real_t maxXmin = rmax / T.rmin;
    enum real_t maxXmax = rmax / T.rmax;

    enum real_t Rrmin = fmin(fmin(minXmin, minXmax), fmin(maxXmin, maxXmax));
    enum real_t Rrmax = fmax(fmax(minXmin, minXmax), fmax(maxXmin, maxXmax));

    enum uint Rbits = max2(bits, T.bits);

    alias R = fix!(rmin, rmax, bits);

    enum uint op_bits = T.bits + R.bits;
    enum uint op_exp = T.exp + R.exp;

    auto a = raw.raw_to!(exp, op_exp, op_bits)();
    auto b = other.raw.raw_to!op_bits();

    auto r = (a / b).raw_to!(R.bits)();

    return R.from_raw(r);
  }

  /// Fixed-point remainder (binary %)
  const pure nothrow @nogc @safe
  auto opBinary(string op, T)(const T other) if (op == "%" && is(T) && isFixed!T) {
    static assert(((T.rmin < 0 && T.rmax < 0) || (T.rmin > 0 && T.rmax > 0)), "Fixed-point remainder is undefined for divider which can be zero.");

    enum real_t rlim = fmax(fabs(T.rmin), fabs(T.rmax));

    enum real_t Rrmin = isntneg ? 0.0 : -rlim;
    enum real_t Rrmax = isntpos ? 0.0 : rlim;

    enum uint Rbits = T.bits;

    alias R = fix!(Rrmin, Rrmax, Rbits);

    enum uint op_bits = bits > T.bits ? bits : T.bits;

    auto a = raw.raw_to!op_bits();
    auto b = other.raw.raw_to!(T.exp, exp, op_bits);

    auto r = (a % b).raw_to!(exp, R.exp, R.bits);

    return R.from_raw(r);
  }

  /// Fixed-point equality (==)
  const pure nothrow @nogc @safe
  bool opEquals(T)(const T other) if (is(T) && isFixed!T) {
    alias C = cmp!(self, T);

    auto a = raw.raw_to!(exp, C.exp, C.bits);
    auto b = other.raw.raw_to!(T.exp, C.exp, C.bits);

    return a == b;
  }

  /// Fixed-point comparison (<>)
  const pure nothrow @nogc @safe
  int opCmp(T)(const T other) if (is(T) && isFixed!T) {
    alias C = cmp!(self, T);

    auto a = raw.raw_to!(exp, C.exp, C.bits);
    auto b = other.raw.raw_to!(T.exp, C.exp, C.bits);

    return a < b ? -1 : a > b ? 1 : 0;
  }

  /// Adding fixed-point value (+=)
  ///
  /// **Note**: Be careful to avoid overflows
  pure nothrow @nogc @safe
  opOpAssign(string op, T)(const T other) if (op == "+" && isFixed!T) {
    raw += other.raw.raw_to!(T.exp, exp, bits)();
  }

  /// Subtracting fixed-point value (+=)
  ///
  /// **Note**: Be careful to avoid overflows
  pure nothrow @nogc @safe
  opOpAssign(string op, T)(const T other) if (op == "-" && isFixed!T) {
    raw -= other.raw.raw_to!(T.exp, exp, bits)();
  }

  /// Multiplying to integer value (*=)
  ///
  /// **Note**: Be careful to avoid overflows
  pure nothrow @nogc @safe
  opOpAssign(string op, T)(const T other) if (op == "*" && isInt!T) {
    raw *= other;
  }

  /// Dividing by integer value (/=)
  pure nothrow @nogc @safe
  opOpAssign(string op, T)(const T other) if (op == "/" && isInt!T) {
    raw /= other;
  }

  /// Remainding by integer value (%=)
  pure nothrow @nogc @safe
  opOpAssign(string op, T)(const T other) if (op == "%" && isInt!T) {
    raw %= other.raw_to!(0, exp, bits);
  }
}

/// Test exponent estimation
nothrow @nogc unittest {
  assert_eq(fix!(0, 0, 32).exp, -31);

  assert_eq(fix!(-1, 0.999999999534338712692260742188, 32).exp, -31);
  assert_eq(fix!(-1, 1, 32).exp, -30);
  assert_eq(fix!(-2, 1.99999999906867742538452148438, 32).exp, -30);
  assert_eq(fix!(-2, 2, 32).exp, -29);
  assert_eq(fix!(-4, 3.99999999813735485076904296875, 32).exp, -29);
  assert_eq(fix!(-4, 4, 32).exp, -28);
  assert_eq(fix!(-8, 7.9999999962747097015380859375, 32).exp, -28);
  assert_eq(fix!(-8, 8, 32).exp, -27);
  assert_eq(fix!(-16, 15.999999992549419403076171875, 32).exp, -27);
  assert_eq(fix!(-32, 31.99999998509883880615234375, 32).exp, -26);
  assert_eq(fix!(-64, 63.9999999701976776123046875, 32).exp, -25);
  assert_eq(fix!(-128, 127.999999940395355224609375, 32).exp, -24);
  assert_eq(fix!(-256, 255.99999988079071044921875, 32).exp, -23);
  assert_eq(fix!(-512, 511.9999997615814208984375, 32).exp, -22);
  assert_eq(fix!(-1024, 1023.999999523162841796875, 32).exp, -21);
  assert_eq(fix!(-2048, 2047.99999904632568359375, 32).exp, -20);

  assert_eq(fix!(-2, 0, 32).exp, -30);
  assert_eq(fix!(0, 1, 32).exp, -30);
  assert_eq(fix!(-31, 0, 32).exp, -26);
  assert_eq(fix!(0, 31, 32).exp, -26);
  assert_eq(fix!(-32, 0, 32).exp, -26);
  assert_eq(fix!(0, 32, 32).exp, -25);

  assert_eq(fix!(-0.5, 0.499999999767169356346130371094, 32).exp, -32);
  assert_eq(fix!(-0.5, 0.5, 32).exp, -31);
  assert_eq(fix!(-0.25, 0.249999999883584678173065185547, 32).exp, -33);
  assert_eq(fix!(-0.25, 0.25, 32).exp, -32);
  assert_eq(fix!(-0.125, 0.124999999941792339086532592773, 32).exp, -34);
  assert_eq(fix!(-0.125, 0.125, 32).exp, -33);
  assert_eq(fix!(-0.0625, 0.0623999999999999999985959581866, 32).exp, -35);
  assert_eq(fix!(-0.0625, 0.0625, 32).exp, -34);
  assert_eq(fix!(-0.03125, 0.0312499999854480847716331481934, 32).exp, -36);
  assert_eq(fix!(-0.03125, 0.03125, 32).exp, -35);
  assert_eq(fix!(-0.015625, 0.0156249999927240423858165740967, 32).exp, -37);
  assert_eq(fix!(-0.015625, 0.015625, 32).exp, -36);

  assert_eq(fix!(0.8, 0.8, 32).exp, -31);
  assert_eq(fix!(0, 0.1, 32).exp, -34);
  assert_eq(fix!(-0.1, 0, 32).exp, -34);
  assert_eq(fix!(0, 0.5, 32).exp, -31);
  assert_eq(fix!(0, 1, 32).exp, -30);
  assert_eq(fix!(0, 100, 32).exp, -24);
  assert_eq(fix!(-100, 0, 32).exp, -24);
  assert_eq(fix!(-100, 100, 32).exp, -24);
  assert_eq(fix!(-100, 1000, 32).exp, -21);
  assert_eq(fix!(0, 100000000, 32).exp, -4);
  assert_eq(fix!(0, 1000000000, 32).exp, -1);
  assert_eq(fix!(0, 10000000000, 32).exp, 3);
  assert_eq(fix!(0, 100000000000, 32).exp, 6);

  assert_eq(fix!(-10, 10).exp, -27);
  assert_eq(asfix!(1e3 / 1e0).exp, -21);
}

/// Test step (or precision)
nothrow @nogc unittest {
  assert_eq(cast(double) fix!(1).step, 9.313225746154785e-10);
  assert_eq(cast(double) fix!(10).step, 7.450580596923828e-9);
  assert_eq(cast(double) fix!(100).step, 5.960464477539063e-8);
  assert_eq(cast(double) fix!(1000).step, 4.76837158203125e-7);
  assert_eq(cast(double) fix!(100000000).step, 0.0625);
  assert_eq(cast(double) fix!(1000000000).step, 0.5);
  assert_eq(cast(double) fix!(10000000000).step, 8);
  assert_eq(cast(double) fix!(100000000000).step, 64);
}

/// Casting to float and int
nothrow @nogc unittest {
  assert_eq(cast(double) fix!(-100, 100)(10), 10);
  assert_eq(cast(int) fix!(-100, 100)(10), 10);
  assert_eq(cast(float) fix!(-100, 100)(0.5), 0.5);

  assert_eq(cast(int) fix!(-100, 100)(0.3), 0);
  assert_eq(cast(int) fix!(-100, 100)(1.3), 1);
  assert_eq(cast(int) fix!(-100, 100)(7.4), 7);

  version(fixRoundTo) { // nearest or zero
    assert_eq(cast(int) fix!(-100, 100)(-0.3), 0);
    assert_eq(cast(int) fix!(-100, 100)(-1.3), -1);
    assert_eq(cast(int) fix!(-100, 100)(-7.4), -7);
  } else { // round down
    assert_eq(cast(int) fix!(-100, 100)(-0.3), -1);
    assert_eq(cast(int) fix!(-100, 100)(-1.3), -2);
    assert_eq(cast(int) fix!(-100, 100)(-7.4), -8);
  }

  version(fixRoundNearest) {
    assert_eq(cast(int) fix!(-100, 100)(0.5), 1);
    assert_eq(cast(int) fix!(-100, 100)(1.5), 2);

    assert_eq(cast(int) fix!(-100, 100)(-0.5), -1);
    assert_eq(cast(int) fix!(-100, 100)(-1.5), -2);

    assert_eq(cast(int) fix!(-100, 100)(0.4), 0);
    assert_eq(cast(int) fix!(-100, 100)(1.4), 1);

    assert_eq(cast(int) fix!(-100, 100)(-0.4), 0);
    assert_eq(cast(int) fix!(-100, 100)(-1.4), -1);

    assert_eq(cast(int) fix!(-100, 100)(7.6), 8);
    assert_eq(cast(int) fix!(-100, 100)(-7.6), -8);
  }

  version(fixRoundToZero) {
    assert_eq(cast(int) fix!(-100, 100)(0.5), 0);
    assert_eq(cast(int) fix!(-100, 100)(1.5), 1);

    assert_eq(cast(int) fix!(-100, 100)(-0.5), 0);
    assert_eq(cast(int) fix!(-100, 100)(-1.5), -1);

    assert_eq(cast(int) fix!(-100, 100)(0.4), 0);
    assert_eq(cast(int) fix!(-100, 100)(1.4), 1);

    assert_eq(cast(int) fix!(-100, 100)(-0.4), 0);
    assert_eq(cast(int) fix!(-100, 100)(-1.4), -1);

    assert_eq(cast(int) fix!(-100, 100)(7.6), 7);
    assert_eq(cast(int) fix!(-100, 100)(-7.6), -7);
  }

  version(fixRoundDown) {
    assert_eq(cast(int) fix!(-100, 100)(0.5), 0);
    assert_eq(cast(int) fix!(-100, 100)(1.5), 1);

    assert_eq(cast(int) fix!(-100, 100)(-0.5), -1);
    assert_eq(cast(int) fix!(-100, 100)(-1.5), -2);

    assert_eq(cast(int) fix!(-100, 100)(0.4), 0);
    assert_eq(cast(int) fix!(-100, 100)(1.4), 1);

    assert_eq(cast(int) fix!(-100, 100)(-0.4), -1);
    assert_eq(cast(int) fix!(-100, 100)(-1.4), -2);

    assert_eq(cast(int) fix!(-100, 100)(7.6), 7);
    assert_eq(cast(int) fix!(-100, 100)(-7.6), -8);
  }
}

/// Casting to fixed
nothrow @nogc unittest {
  assert_eq(cast(fix!(-10, 100)) fix!(-10, 10)(5), fix!(-10, 100)(5));
  assert_eq(cast(int) cast(fix!(-10, 100)) fix!(-10, 10)(5), 5);
  assert_eq(cast(fix!(-10, 100)) fix!(-10, 10)(1.5), fix!(-10, 100)(1.5));
}

/// Fraction part
nothrow @nogc unittest {
  assert_eq(fix!(-2, 1)(0.55).fracof, fix!(-1, 1)(0.55));
  assert_eq(fix!(-1, 1)(-0.54).fracof, fix!(-1, 1)(-0.54));
  assert_eq(fix!(-2, 1)(-0.55).fracof, fix!(-1, 1)(-0.55));

  assert_eq(fix!(-1, 2)(1.005).fracof, fix!(-1, 1)(0.005), fix!(-1, 1).step);
  assert_eq(fix!(-2, 1)(-1.005).fracof, fix!(-1, 1)(-0.005), fix!(-1, 1).step);

  assert_eq(fix!(-1, 2)(1.001).fracof, fix!(-1, 1)(0.001), fix!(-1, 1).step);
  assert_eq(fix!(-2, 1)(-1.001).fracof, fix!(-1, 1)(-0.001), fix!(-1, 1).step);

  assert_eq(fix!(-2, 1)(-1.95).fracof, fix!(-1, 1)(-0.95));
  assert_eq(fix!(-1, 2)(1.95).fracof, fix!(-1, 1)(0.95), fix!(-1, 1).step);

  assert_eq(fix!(0, 2)(1.999).fracof, fix!(0, 1)(0.999));
  assert_eq(fix!(-2, 0)(-1.999).fracof, fix!(-1, 0)(-0.999));

  assert_eq(fix!(-1, 1)(-1).fracof, fix!(-1, 1)(0));
  assert_eq(fix!(-1, 1)(1).fracof, fix!(-1, 1)(0));

  assert_eq(fix!(-10, 15)(-1.5).fracof, fix!(-1, 1)(-0.5));
  //assert_eq(fix!(-10, 15)(-1.54).fracof, fix!(-1, 1)(-0.54));

  assert_eq(fix!(-1e10, 1e10)(0).fracof, fix!(0, 0)(0));

  assert_eq(fix!(-10, 15)(-3.09).fracof, fix!(-1, 1)(-0.09), fix!(-1, 1)(0.00000001));
}

/// Integer part
nothrow @nogc unittest {
  assert_eq(fix!(-0.99, 0.0)(-0.55).intof, fix!(-0.0, 0)(0));
  assert_eq(fix!(-0.99, 1.0)(0.55).intof, fix!(-0.0, 1)(0));
  assert_eq(fix!(-1.0, 1.0)(1.0).intof, fix!(-1, 1)(1));
  assert_eq(fix!(-1.0, 1.0)(-1.0).intof, fix!(-1, 1)(-1));

  assert_eq(fix!(-10, 15)(-1.5).intof, fix!(-10, 15)(-1));
  assert_eq(fix!(-10, 15)(-1.55).intof, fix!(-10, 15)(-1));
  assert_eq(fix!(-10, 15)(-3.09).intof, fix!(-10, 15)(-3));
  assert_eq(fix!(-10, 15)(-7.9).intof, fix!(-10, 15)(-7));

  assert_eq(fix!(-10, 15)(9.99).intof, fix!(-10, 15)(9));
}

/// Negation
nothrow @nogc unittest {
  assert_eq(-fix!(-100, 200)(5), fix!(-200, 100)(-5));
  assert_eq(-fix!(-22, 11)(-0.5), fix!(-11, 22)(0.5));
}

/// Addition
nothrow @nogc unittest {
  assert_eq(fix!(-100, 200)(1.23) + fix!(-20, 10)(5), fix!(-120, 210)(6.23));

  // add const
  assert_eq(fix!(-10, 10)(1.25) + asfix!(2.5), fix!(-7.5, 12.5)(3.75));

  // add zero
  assert_eq(fix!(-10, 10)(1.25) + asfix!(0.0), fix!(-10, 10)(1.25));
}

/// Subtraction
nothrow @nogc unittest {
  assert_eq(fix!(-100, 200)(1.25) - fix!(-20, 10)(5.3), fix!(-110, 220)(-4.05));

  // subtract const
  assert_eq(fix!(-10, 10)(1.25) - asfix!(2.5), fix!(-12.5, 7.5)(-1.25));

  // subtract zero
  assert_eq(fix!(-10, 10)(1.25) - asfix!(0.0), fix!(-10, 10)(1.25));

  assert_eq(fix!(-10, 10)(9) - fix!(-10, 10)(8), fix!(-20, 20)(1));

  assert_eq(fix!(-10, 10)(9) - asfix!(8), fix!(-18, 2)(1));
}

/// Multiplication
nothrow @nogc unittest {
  version(fixRoundToNearest) {
    assert_eq(fix!(-100, 200)(1.25) * fix!(-20, 10)(5.3), fix!(-4000, 2000)(6.625));
    assert_eq(asfix!(1.25) * asfix!(5.3), asfix!(6.625));
  } else {
    assert_eq(fix!(-100, 200)(1.25) * fix!(-20, 10)(5.3), fix!(-4000, 2000)(6.624999));
  }

  assert_eq(fix!(-10, 10)(1.25) * asfix!(1e3), fix!(-10000, 10000)(1250.0));
  assert_eq(fix!(-10, 10)(1.25) * asfix!(1/1e-3), fix!(-10000, 10000)(1250.0));
}

/// Division
nothrow @nogc unittest {
  assert_eq(fix!(-4000, 2000)(6.625) / fix!(1, 10)(5.3), fix!(-4000, 2000)(1.25));
}

/// Remainder
nothrow @nogc unittest {
  assert_eq(fix!(-100, 50)(11.25) % fix!(1, 20)(3.5), fix!(-20, 20)(0.75));
}

/// Comparison
nothrow @nogc unittest {
  assert(fix!(-10, 50)(0) == fix!(-5, 20)(0));
  assert(fix!(-10, 50)(0.5) == fix!(-5, 20)(0.5));
  assert(fix!(-10, 50)(0.125) == fix!(-5, 20)(0.125));
  assert(fix!(-10, 50)(9.25) == fix!(-5, 20)(9.25));

  assert(fix!(-10, 50)(-0.5) == fix!(-5, 20)(-0.5));
  assert(fix!(-10, 50)(-0.125) == fix!(-5, 20)(-0.125));
  assert(fix!(-10, 50)(-9.25) == fix!(-5, 20)(-9.25));

  assert(fix!(-10, 50)(0) != fix!(-5, 20)(1));
  assert(fix!(-10, 50)(0.125) != fix!(-5, 20)(0.0625));
  assert(fix!(-100, 50)(11.25) != fix!(-10, 20)(3.5));

  assert(!(fix!(-10, 50)(0) < fix!(-5, 20)(0)));
  assert(fix!(-10, 50)(0) <= fix!(-5, 20)(0));
  assert(!(fix!(-10, 50)(0) > fix!(-5, 20)(0)));
  assert(fix!(-10, 50)(0) >= fix!(-5, 20)(0));

  assert(fix!(-10, 50)(0) < fix!(-5, 20)(1));
  assert(!(fix!(-10, 50)(0) > fix!(-5, 20)(1)));

  assert(fix!(-10, 50)(0.125) > fix!(-5, 20)(0.0625));
  assert(fix!(-10, 50)(0.125) >= fix!(-5, 20)(0.0625));
  assert(fix!(-100, 50)(11.25) > fix!(-10, 20)(3.5));
  assert(fix!(-100, 50)(11.25) >= fix!(-10, 20)(3.5));

  assert(fix!(-10, 50)(-0.125) < fix!(-5, 20)(-0.0625));
  assert(fix!(-10, 50)(-0.125) <= fix!(-5, 20)(-0.0625));
  assert(fix!(-100, 50)(-11.25) < fix!(-10, 20)(-3.5));
  assert(fix!(-100, 50)(-11.25) <= fix!(-10, 20)(-3.5));
}

/// Test op-assign
nothrow @nogc unittest {
  alias X = fix!(-100, 50);
  alias Y = fix!(0, 5);
  alias Z = fix!(-200, 10000);

  X a = 11.25;

  a += X(1.5);
  assert_eq(a, X(12.75));

  a -= X(1.5);
  assert_eq(a, X(11.25));

  a += Y(0.5);
  assert_eq(a, X(11.75));

  a -= Y(0.5);
  assert_eq(a, X(11.25));

  a += Z(2.5);
  assert_eq(a, X(13.75));

  a -= Z(2.5);
  assert_eq(a, X(11.25));

  a *= 2;
  assert_eq(a, X(22.5));

  a /= 2;
  assert_eq(a, X(11.25));

  a %= 2;
  assert_eq(a, X(1.25));
}

private pure nothrow @nogc @safe
T max2(T)(T a, T b) {
  return max(a, b);
}

private pure nothrow @nogc @safe
T abs_floor(T)(T val) if (isFloat!T) {
  return val < 0 ? val.ceil() : val.floor();
}

private template cmp(A, B) if (isFixed!A && isFixed!B) {
  enum real_t rmin = fmin(A.rmin, B.rmin);
  enum real_t rmax = fmax(A.rmax, B.rmax);

  enum uint bits = max2(A.bits, B.bits);

  alias cmp = fix!(rmin, rmax, bits);
}

/// Create fixed-point constant from an arbitrary number
template asfix(real val, uint bits = 32) {
  enum fix!(val, val, bits) asfix = val;
}

/// Test `asfix`
nothrow @nogc unittest {
  assert_eq(asfix!0.exp, -31);
  assert_eq(cast(double) asfix!0, 0);

  assert_eq(asfix!1.exp, -30);
  assert_eq(cast(double) asfix!1, 1);

  assert_eq(asfix!0.1.exp, -34);
  assert_eq(cast(double) asfix!0.1, 0.09999999997671694);

  assert_eq(asfix!100.exp, -24);
  assert_eq(cast(double) asfix!100, 100);

  assert(is(typeof(asfix!(100, 64).raw) == long));
  assert_eq(asfix!(100, 64).exp, -56);
  assert_eq(cast(double) asfix!(100, 64), 100);

  enum auto a = asfix!(1e3);
  enum auto b = asfix!(1/1e-3);
}

/// Checks that type or value is fixed-point number
template isFixed(X...) if (X.length == 1) {
  static if (is(X[0])) {
    enum bool isFixed = isInstanceOf!(fix, X[0]);
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

/// Checks that fixed-point types is same
template isSameFixed(X...) if (X.length == 2) {
  static if (isFixed!(X[0]) && isFixed!(X[1])) {
    enum bool isSameFixed = X[0].bits == X[1].bits && X[0].exp == X[1].exp;
  } else {
    enum bool isSameFixed = false;
  }
}

/// Test `isSameFixed`
nothrow @nogc @safe unittest {
  assert(isSameFixed!(fix!(-1, 1), fix!(-1, 1)));
  assert(isSameFixed!(typeof(fix!(-1.1, 0.3)(0.0) * asfix!(1e3)), fix!(-1100, 300)));
  assert(isSameFixed!(typeof(fix!(-5, 10)(0.0) * asfix!(1e-3)), fix!(-0.005, 0.01)));
  assert(isSameFixed!(asfix!(1/1e-3), asfix!(1e3)));
  assert(isSameFixed!(fix!(-10, 10)(1.25) * asfix!(1e3), fix!(-10000, 10000)(1250.0)));
  assert(isSameFixed!(fix!(-10, 10)(1.25) * asfix!(1/1e-3), fix!(-10000, 10000)(1250.0)));

  assert(!isSameFixed!(fix!(-1, 1), fix!(0, 2)));
  assert(!isSameFixed!(double, double));
}

/// Check when type or expr is numeric
template isNumer(X...) if (X.length == 1) {
  enum bool isNumer = isFloat!(X[0]) || isInt!(X[0]) || isFixed!(X[0]);
}

/// Check that fixed-point number is constant
template isFixedConst(X...) if (X.length == 1) {
  static if (is(X[0]) && isFixed(X[0])) {
    enum bool isFixedConst = fabs(X[0].rmin - X[0].rmax) < real_t.epsilon;
  } else {
    enum bool isFixedConst = isFixedConst!(typeof(X[0]));
  }
}

/// Check that fixed-point number is constant and equals to value
template isFixedEqualsTo(X, real_t val) {
  enum bool isFixedEqualsTo = isFixedConst!(X) && fabs(X.rmin - val) < real_t.epsilon;
}
