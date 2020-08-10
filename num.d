/**
   Various numeric utilities
 */
module num;

import std.traits: isFloatingPoint, isIntegral, isSigned, isUnsigned;
import std.algorithm.comparison: clamp;

version(unittest) {
  import std.meta: AliasSeq;
  import test: assert_eq, unittests;

  mixin unittests;
}

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
