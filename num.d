/**
   Various numeric utilities
 */
module num;

/// Check when type or expr is number
template isNum(X...) if (X.length == 1) {
  enum bool isNum = isInt!(X[0]) || isFloat!(X[0]);
}

/// Check when type or expr is floating-point number
template isFloat(X...) if (X.length == 1) {
  enum bool isFloat = __traits(isArithmetic, X[0]) && __traits(isFloating, X[0]) && __traits(isScalar, X[0]);
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
  enum bool isInt = __traits(isArithmetic, X[0]) && __traits(isIntegral, X[0]) && __traits(isScalar, X[0]) && !isChar!(X[0]);
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

/// Check when type or expr is character
template isChar(X...) if (X.length == 1) {
  static if (is(X[0])) {
    enum bool isChar = is(X[0] == char);
  } else {
    enum bool isChar = isChar!(typeof(X[0]));
  }
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
      /*
      import core.stdc.inttypes: PRIu8, PRId8, PRIu16, PRId16, PRIu32, PRId32, PRIu64, PRId64;

      static if (is(X[0] == ubyte)) {
        enum string fmtOf = cast(string) "%" ~ PRIu8;
      } else static if (is(X[0] == byte)) {
        enum string fmtOf = cast(string) "%" ~ PRId8;
      } else static if (is(X[0] == ushort)) {
        enum string fmtOf = cast(string) "%" ~ PRIu16;
      } else static if (is(X[0] == short)) {
        enum string fmtOf = cast(string) "%" ~ PRId16;
      } else static if (is(X[0] == uint)) {
        enum string fmtOf = cast(string) "%" ~ PRIu32;
      } else static if (is(X[0] == int)) {
        enum string fmtOf = cast(string) "%" ~ PRId32;
      } else static if (is(X[0] == ulong)) {
        enum string fmtOf = cast(string) "%" ~ PRIu64;
      } else static if (is(X[0] == long)) {
        enum string fmtOf = cast(string) "%" ~ PRId64;
      } else {
        static assert(false, "Unsupported formatting of integer type: " ~ T.stringof);
      }
      */

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
        static assert(false, "Unsupported formatting of integer type: " ~ T.stringof);
      }
    } else static if (isFloat!(X[0])) {
      static if (is(X[0] == float)) {
        enum string fmtOf = "%f";
      } else static if (is(X[0] == double)) {
        enum string fmtOf = "%g";
      } else {
        static assert(false, "Unsupported formatting of floating-point type: " ~ T.stringof);
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

// Run tests without D-runtime
version(D_BetterC) {
  version(unittest) {
    nothrow @nogc extern(C) void main() {
      static foreach(unitTest; __traits(getUnitTests, __traits(parent, main)))
        unitTest();
    }
  }
}
