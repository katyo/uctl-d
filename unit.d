/**
   Measurement units
 */
module unit;

import std.math: PI;
import num: isNum;
import fix: fix, prod, asfix, isFixed, isNumer;

version(unittest) {
  import test: assert_eq, unittests;

  mixin unittests;
}

/**
   Value with measurement units
 */
struct Val(T, U) if (is(T) && isNumer!T && is(U) && isUnits!U) {
  alias units = U;
  alias raw_t = T;

  T raw;

  /// Wrap raw value to units
  const pure nothrow @nogc @safe
  this(X)(const X val) if (__traits(compiles, cast(T) val)) { raw = cast(T) val; }

  /// Get raw value back
  const pure nothrow @nogc @safe
  X opCast(X)() if (is(X == T)) { return raw; }

  /// Convert underlying raw value
  const pure nothrow @nogc @safe
  X opCast(X)() if (hasUnits!X && is(X.units == U)) {
    return cast(X) raw;
  }
}

/// Check that some value or type has measurement units
template hasUnits(X...) if (X.length == 1) {
  static if (is(X[0])) {
    static if (__traits(hasMember, X[0], "raw") && __traits(hasMember, X[0], "raw_t") && __traits(hasMember, X[0], "units")) {
      enum bool hasUnits = is(X[0] == Val!(X[0].raw_t, X[0].units));
    } else {
      enum bool hasUnits = false;
    }
  } else {
    enum bool hasUnits = hasUnits!(typeof(X));
  }
}

/// Add measurement units to raw value
pure nothrow @nogc @safe
Val!(T, U) as(U, T)(T val) if (is(T) && isNumer!T && is(U) && isUnits!U) {
  return typeof(return)(val);
}

template UnitsTo(U, T) if (hasUnits!T && isUnits!U && U.unitsKind == T.units.unitsKind) {
  static if (isFixed!(T.raw_t)) {
    alias UnitsTo = Val!(prod!(T.raw_t, typeof(asfix!(U.unitsBase / T.units.unitsBase))), U);
  } else {
    alias UnitsTo = Val!(T.raw_t, U);
  }
}

/// Convert angle values from some units to another
pure nothrow @nogc @safe
UnitsTo!(U, T) to(U, T)(const T val) if (is(T) && hasUnits!T && isUnits!(T.units) && isUnits!U && T.units.unitsKind == U.unitsKind) {
  alias R = typeof(return);
  static if (isFixed!(T.raw_t)) {
    return R(val.raw * asfix!(U.unitsBase / T.units.unitsBase));
  } else {
    return R(val.raw * cast(T.raw_t) (U.unitsBase / T.units.unitsBase));
  }
}

mixin defUnits!("km", UnitsKind.Length, 1e-3);
mixin defUnits!("m", UnitsKind.Length, 1);
mixin defUnits!("dm", UnitsKind.Length, 1e1);
mixin defUnits!("cm", UnitsKind.Length, 1e2);
mixin defUnits!("mm", UnitsKind.Length, 1e3);
mixin defUnits!("um", UnitsKind.Length, 1e6);
mixin defUnits!("nm", UnitsKind.Length, 1e9);
mixin defUnits!("pm", UnitsKind.Length, 1e12);

mixin defUnits!("deg", UnitsKind.Angle, 180.0);
mixin defUnits!("rad", UnitsKind.Angle, PI);
mixin defUnits!("hpi", UnitsKind.Angle, 2.0);
mixin defUnits!("rev", UnitsKind.Angle, 0.5);

mixin defUnits!("nsec", UnitsKind.Time, 1e6);
mixin defUnits!("usec", UnitsKind.Time, 1e3);
mixin defUnits!("sec", UnitsKind.Time, 1.0);
mixin defUnits!("min", UnitsKind.Time, 1.0/60.0);
mixin defUnits!("hour", UnitsKind.Time, 1.0/3600.0);

/// Units wrapping and conversion
nothrow @nogc unittest {
  assert(1.25.as!m == cast(Val!(double, m)) 1.25);
  assert(1.25.as!m.to!mm == 1250.0.as!mm);
  assert(1.25.as!m.to!cm == 125.0.as!cm);

  assert(123.as!deg == cast(Val!(int, deg)) 123);
  assert_eq(180.0.as!deg.to!rad, (cast(double) PI).as!rad, 0.00001);
  assert_eq(60.0.as!deg.to!rad, (cast(double) PI / 3.0).as!rad, 0.000001);

  assert(1.5.as!sec == cast(Val!(double, sec)) 1.5);
  assert(1.5.as!sec.to!usec == 1500.0.as!usec);

  alias X = fix!(-10, 10);

  assert(X(1.25).as!m.raw == X(1.25));
  assert(X(1.25).as!m == Val!(X, m)(X(1.25)));
  assert(X(1.25).as!m == cast(Val!(X, m)) 1.25);

  assert_eq(fix!(-10, 10).exp, -27);
  assert_eq(asfix!(1e3 / 1e0).exp, -21);

  assert_eq(fix!(-10, 10)(1.25).as!m.to!mm, fix!(-10000, 10000)(1250.0).as!mm);
  assert_eq(fix!(-10, 10)(1.25).as!m.to!cm, fix!(-1000, 1000)(125.0).as!cm);

  //assert_eq((Y(1.25) * asfix!(1e2)).raw, 1250);
  //assert_eq(cast(Y) (Y(1.25) * asfix!(1e3)), Y(1250));
}

mixin template defUnits(string name, UnitsKind kind, real base = 1.0, string extra = "") {
  mixin("
    struct ", name, " {
      enum string unitsName = \"", name, "\";
      enum UnitsKind unitsKind = ", kind, ";
      enum real unitsBase = ", base, ";
      ", extra, "
    }
  ");
}

template isUnits(X...) if (X.length == 1) {
  enum bool isUnits = __traits(hasMember, X[0], "unitsName");
}

enum UnitsKind {
  Length,
  Angle,
  Time,
  LinearVelocity,
  AngularVelocity,
}
