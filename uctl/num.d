/**
   Various numeric utilities
 */
module uctl.num;

import std.traits: isFloatingPoint, isIntegral, isSigned, isUnsigned;
import std.algorithm: clamp;

version(unittest) {
  import std.meta: AliasSeq;
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/// The __golden ratio__ constant
enum real PHI = 1.61803398874989484820;

/// Check when type or expr is floating-point number
template isFloat(X...) if (X.length == 1) {
  static if (is(X[0])) {
    enum bool isFloat = isFloatingPoint!(X[0]);
  } else {
    enum bool isFloat = isFloat!(typeof(X[0]));
  }
}

/// Test `isFloat`
nothrow @nogc @safe unittest {
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

/// Check when type or expr is integer number
template isInt(X...) if (X.length == 1) {
  static if (is(X[0])) {
    enum bool isInt = isIntegral!(X[0]);
  } else {
    enum bool isInt = isInt!(typeof(X[0]));
  }
}

/// Test `isInt`
nothrow @nogc @safe unittest {
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

/// Check when type or expr is number
template isNum(X...) if (X.length == 1) {
  enum bool isNum = isInt!(X[0]) || isFloat!(X[0]);
}

/// Get number of bits of specified type or value
template bitsOf(X...) if (X.length == 1) {
  static if (is(X[0])) {
    enum uint bitsOf = X[0].sizeof * 8;
  } else {
    enum uint bitsOf = bitsOf!(typeof(X[0]));
  }
}

/// Test `bitsOf`
nothrow @nogc @safe unittest {
  assert(bitsOf!ubyte == 8);
  assert(bitsOf!byte == 8);
  assert(bitsOf!ushort == 16);
  assert(bitsOf!short == 16);
  assert(bitsOf!uint == 32);
  assert(bitsOf!int == 32);
  assert(bitsOf!ulong == 64);
  assert(bitsOf!long == 64);

  ubyte a;

  assert(bitsOf!a == 8);
}

/// Signed version of unsigned type
template signedOf(X...) if (X.length == 1 && isIntegral!(X[0])) {
  static if (is(X[0])) {
    static if (isSigned!(X[0])) {
      alias signedOf = X[0];
    } else {
      static if (is(ubyte) && is(X[0] == ubyte)) {
        alias signedOf = byte;
      } else static if (is(ushort) && is(X[0] == ushort)) {
        alias signedOf = short;
      } else static if (is(uint) && is(X[0] == uint)) {
        alias signedOf = int;
      } else static if (is(ulong) && is(X[0] == ulong)) {
        alias signedOf = long;
      } else static if (is(ucent) && is(X[0] == ucent)) {
        alias signedOf = cent;
      }
    }
  } else {
    alias signedOf = signedOf!(typeof(X[0]));
  }
}

/// Unsigned version of signed type
template unsignedOf(X...) if (X.length == 1 && isIntegral!(X[0])) {
  static if (is(X[0])) {
    static if (isUnsigned!(X[0])) {
      alias unsignedOf = X[0];
    } else {
      static if (is(byte) && is(X[0] == byte)) {
        alias unsignedOf = ubyte;
      } else static if (is(short) && is(X[0] == short)) {
        alias unsignedOf = ushort;
      } else static if (is(int) && is(X[0] == int)) {
        alias unsignedOf = uint;
      } else static if (is(long) && is(X[0] == long)) {
        alias unsignedOf = ulong;
      } else static if (is(cent) && is(X[0] == cent)) {
        alias unsignedOf = ucent;
      }
    }
  } else {
    alias unsignedOf = unsignedOf!(typeof(X[0]));
  }
}

/// Sets single bit with specified index
template filledBit(T, int index) if (isIntegral!T) {
  alias U = unsignedOf!T;
  enum int bits = bitsOf!T;
  static if (index >= 0 && index < bits) {
    enum T filledBit = cast(T) ((cast(U) 1) << index);
  } else {
    enum T filledBit = 0;
  }
}

/// Test `filledBit`
nothrow @nogc unittest {
  static const ulong[] a = [0b1, 0b10, 0b100, 0b1000, 0b10000, 0b100000, 0b1000000, 0b10000000, 0b100000000, 0b1000000000, 0b10000000000, 0b100000000000, 0b1000000000000, 0b10000000000000, 0b100000000000000, 0b1000000000000000, 0b10000000000000000, 0b100000000000000000, 0b1000000000000000000, 0b10000000000000000000, 0b100000000000000000000, 0b1000000000000000000000, 0b10000000000000000000000, 0b100000000000000000000000, 0b1000000000000000000000000, 0b10000000000000000000000000, 0b100000000000000000000000000, 0b1000000000000000000000000000, 0b10000000000000000000000000000, 0b100000000000000000000000000000, 0b1000000000000000000000000000000, 0b10000000000000000000000000000000, 0b100000000000000000000000000000000, 0b1000000000000000000000000000000000, 0b10000000000000000000000000000000000, 0b100000000000000000000000000000000000, 0b1000000000000000000000000000000000000, 0b10000000000000000000000000000000000000, 0b100000000000000000000000000000000000000, 0b1000000000000000000000000000000000000000, 0b10000000000000000000000000000000000000000, 0b100000000000000000000000000000000000000000, 0b1000000000000000000000000000000000000000000, 0b10000000000000000000000000000000000000000000, 0b100000000000000000000000000000000000000000000, 0b1000000000000000000000000000000000000000000000, 0b10000000000000000000000000000000000000000000000, 0b100000000000000000000000000000000000000000000000, 0b1000000000000000000000000000000000000000000000000, 0b10000000000000000000000000000000000000000000000000, 0b100000000000000000000000000000000000000000000000000, 0b1000000000000000000000000000000000000000000000000000, 0b10000000000000000000000000000000000000000000000000000, 0b100000000000000000000000000000000000000000000000000000, 0b1000000000000000000000000000000000000000000000000000000, 0b10000000000000000000000000000000000000000000000000000000, 0b100000000000000000000000000000000000000000000000000000000, 0b1000000000000000000000000000000000000000000000000000000000, 0b10000000000000000000000000000000000000000000000000000000000, 0b100000000000000000000000000000000000000000000000000000000000, 0b1000000000000000000000000000000000000000000000000000000000000, 0b10000000000000000000000000000000000000000000000000000000000000, 0b100000000000000000000000000000000000000000000000000000000000000, 0b1000000000000000000000000000000000000000000000000000000000000000];

  static foreach (T; AliasSeq!(ubyte, byte, ushort, short, uint, int, ulong, long)) {
    static foreach (int i; 0 .. bitsOf!T) {
      assert_eq(filledBit!(T, i), cast(T) (a[i]));
    }
    static foreach (int i; bitsOf!T .. 2 * bitsOf!T) {
      assert_eq(filledBit!(T, i), 0);
    }
    static foreach (int i; -bitsOf!T .. 0) {
      assert_eq(filledBit!(T, i), 0);
    }
  }
}

/// Sets bits from starting to end
template filledBits(T, int start_, int end_) if (isIntegral!T) {
  alias U = unsignedOf!T;

  enum uint bits = bitsOf!T;
  enum uint start = start_.clamp(0, bits);
  enum uint end = end_.clamp(0, bits);

  template fill(uint n) {
    static if (n < end) {
      enum U fill = ((cast(U) 1) << n) | fill!(n + 1);
    } else {
      enum U fill = 0;
    }
  }

  enum T filledBits = cast(T) fill!(start);
}

/// Test `filledBits`
nothrow @nogc unittest {
  static foreach (T; AliasSeq!(ubyte, byte, ushort, short, uint, int, ulong, long)) {
    assert_eq(filledBits!(T, 0, 0), cast(T) 0b00000000);
    assert_eq(filledBits!(T, 8, 8), cast(T) 0b00000000);
    assert_eq(filledBits!(T, 0, 8), cast(T) 0b11111111);
    assert_eq(filledBits!(T, -8, 8), cast(T) 0b11111111);
    assert_eq(filledBits!(T, 2, 7), cast(T) 0b01111100);
    assert_eq(filledBits!(T, 0, 1), cast(T) 0b00000001);
    assert_eq(filledBits!(T, 1, 2), cast(T) 0b00000010);
    assert_eq(filledBits!(T, 1, 3), cast(T) 0b00000110);
    assert_eq(filledBits!(T, 7, 8), cast(T) 0b10000000);
  }
  assert_eq(filledBits!(uint, -32, 64), 0xffffffff);
  assert_eq(filledBits!(int, -32, 64), 0xffffffff);
  assert_eq(filledBits!(uint, 31, 32), 0x80000000);
  assert_eq(filledBits!(int, 31, 32), 0x80000000);
}

/**
   Get formatting specifier for an arbitrary numeric type or value
 */
template fmtOf(X...) if (X.length == 1) {
  static if (is(X[0])) {
    static if (isInt!(X[0])) {
      static if (is(X[0] == ubyte)) {
        enum string fmtOf = cast(string) "%hhu";
      } else static if (is(X[0] == byte)) {
        enum string fmtOf = cast(string) "%hhd";
      } else static if (is(X[0] == ushort)) {
        enum string fmtOf = cast(string) "%hu";
      } else static if (is(X[0] == short)) {
        enum string fmtOf = cast(string) "%hd";
      } else static if (is(X[0] == uint)) {
        enum string fmtOf = cast(string) "%u";
      } else static if (is(X[0] == int)) {
        enum string fmtOf = cast(string) "%d";
      } else static if (is(X[0] == ulong)) {
        enum string fmtOf = cast(string) "%llu";
      } else static if (is(X[0] == long)) {
        enum string fmtOf = cast(string) "%lld";
      } else {
        static assert(false, "Unsupported formatting of integer type: " ~ X[0].stringof);
      }
    } else static if (isFloat!(X[0])) {
      static if (is(X[0] == float)) {
        enum string fmtOf = "%f";
      } else static if (is(X[0] == double)) {
        enum string fmtOf = "%g";
      } else {
        static assert(false, "Unsupported formatting of floating-point type: " ~ X[0].stringof);
      }
    }
  } else {
    enum string fmtOf = fmtOf!(typeof(X[0]));
  }
}

/// Test `fmtOf`
nothrow @nogc @safe unittest {
  assert(fmtOf!ubyte == "%hhu");
  assert(fmtOf!byte == "%hhd");
  assert(fmtOf!ushort == "%hu");
  assert(fmtOf!short == "%hd");
  assert(fmtOf!uint == "%u");
  assert(fmtOf!int == "%d");
  assert(fmtOf!ulong == "%llu");
  assert(fmtOf!long == "%lld");
  assert(fmtOf!float == "%f");
  assert(fmtOf!double == "%g");

  short a;
  assert(fmtOf!a == "%hd");
}
