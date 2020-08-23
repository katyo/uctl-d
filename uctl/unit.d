/**
   Measurement units
 */
module uctl.unit;

import std.math: PI;
import std.traits: Unqual, isInstanceOf;
import uctl.num: isNum, fix, asfix, isFixed, isNumer;

version(unittest) {
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/**
   Value with measurement units
 */
struct Val(T, U) if (is(T) && isNumer!T && is(U) && isUnits!U) {
  alias units = U;
  alias raw_t = Unqual!T;

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

  /// Negation
  const pure nothrow @nogc @safe
  auto opUnary(string op)() if (op == "-") {
    return (- cast(T) raw).as!U;
  }

  /// Addition/subtraction
  const pure nothrow @nogc @safe
  auto opBinary(string op, A)(const A other) if ((op == "+" || op == "-") && hasUnits!A && is(U.Class == A.units.Class)) {
    auto raw1 = cast(T) raw;
    static if(is(U == A.units)) { // same units
      // casting needs for removing const qualifiers
      auto raw2 = cast(A.raw_t) other.raw;
    } else { // same class
      auto other2 = other.to!U;
      auto raw2 = cast(typeof(other2).raw_t) other2.raw;
    }
    return mixin("raw1" ~ op ~ "raw2").as!U;
  }

  /// Multiplication/division by unit-less
  const pure nothrow @nogc @safe
  auto opBinary(string op, A)(const A other) if ((op == "*" || op == "/" || op == "%") && isNumer!A) {
    auto raw1 = cast(T) raw;
    auto raw2 = cast(A) other;

    return mixin("raw1" ~ op ~ "raw2").as!U;
  }

  /// Equality (==)
  const pure nothrow @nogc @safe
  bool opEquals(A)(const A other) if (hasUnits!A && is(U.Class == A.units.Class)) {
    static if(is(U == A.units)) { // same units
      auto raw2 = other.raw;
    } else { // same class
      auto raw2 = other.to!U.raw;
    }
    return raw == raw2;
  }

  /// Comparison (<>)
  const pure nothrow @nogc @safe
  int opCmp(A)(const A other) if (hasUnits!A && is(U.Class == A.units.Class)) {
    static if(is(U == A.units)) { // same units
      auto raw2 = other.raw;
    } else { // same class
      auto raw2 = other.to!U.raw;
    }
    return raw < raw2 ? -1 : raw > raw2 ? 1 : 0;
  }

  /// Adding/subtracting value (+=, -=)
  pure nothrow @nogc @safe
  opOpAssign(string op, A)(const A other) if ((op == "+" || op == "-") && hasUnits!A && is(U.Class == A.units.Class)) {
    static if(is(U == A.units)) { // same units
      auto raw2 = other.raw;
    } else { // same class
      auto raw2 = other.to!U.raw;
    }
    mixin("raw" ~ op ~ "=raw2;");
  }

  /// Multiplying to/dividing by/remainder of raw value (*=, /=, %=)
  pure nothrow @nogc @safe
  opOpAssign(string op, A)(const A other) if ((op == "*" || op == "/" || op == "%") && isNumer!A) {
    mixin("raw" ~ op ~ "=other;");
  }
}

/// Check that some value or type has measurement units
template hasUnits(X...) if (X.length == 1) {
  static if (is(X[0])) {
    enum bool hasUnits = isInstanceOf!(Val, X[0]);
  } else {
    enum bool hasUnits = hasUnits!(typeof(X));
  }
}

/// Add measurement units to raw value
pure nothrow @nogc @safe
Val!(T, U) as(U, T)(T val) if (is(T) && isNumer!T && is(U) && isUnits!U) {
  return typeof(return)(val);
}

/// Convert angle values from some units to another
pure nothrow @nogc @safe
auto to(U, T)(const T val) if (hasUnits!T && isUnits!(T.units) && isUnits!U && is(T.units.Class == U.Class)) {
  static if (is(T.units == U)) { // units is same
    return val;
  } else {
    // (raw + T.units.offset) * T.units.factor = (return.raw + U.offset) * U.factor
    // return.raw = raw * factor + offset
    // where
    //   factor = T.units.factor / U.factor,
    //   offset = (T.units.offset * factor - U.offset)

    enum real factor = T.units.factor / U.factor;
    enum real offset = T.units.offset * factor - U.offset;

    static if (isFixed!(T.raw_t)) {
      return (val.raw * asfix!(factor) + asfix!(offset)).as!U;
    } else {
      return (val.raw * cast(T.raw_t) factor + cast(T.raw_t) offset).as!U;
    }
  }
}

alias Length = UnitsClass!("Length");
alias Angle = UnitsClass!("Angle");

alias LinearVel = UnitsClass!("Linear Velocity");
alias AngularVel = UnitsClass!("Angular Velocity");
alias LinearAccel = UnitsClass!("Linear Acceleration");
alias AngularAccel = UnitsClass!("Angular Acceleration");
alias LinearJerk = UnitsClass!("Linear Jerk");
alias AngularJerk = UnitsClass!("Angular Jerk");

alias Area = UnitsClass!("Area");
alias Volume = UnitsClass!("Volume");

alias Voltage = UnitsClass!("Voltage");
alias Current = UnitsClass!("Current");
alias Power = UnitsClass!("Power");
alias Energy = UnitsClass!("Energy");

alias Resistance = UnitsClass!("Resistance");
alias Capacitance= UnitsClass!("Capacitance");
alias Inductance = UnitsClass!("Inductance");

alias Temperature = UnitsClass!("Temperature");

alias Time = UnitsClass!("Time");

alias m = Units!("Meter", Length);
alias dm = Units!("Deci meter", Length, 1e-1);
alias cm = Units!("Centi meter", Length, 1e-2);
alias mm = Units!("Milli meter", Length, 1e-3);
alias um = Units!("Micro meter", Length, 1e-6);
alias nm = Units!("Nano meter", Length, 1e-9);
alias Km = Units!("Kilo meter", Length, 1e3);

alias rev = Units!("Revolution", Angle);
alias hpi = Units!("Half PI", Angle, 1.0/4.0);
alias deg = Units!("Degree", Angle, 1.0/360.0);
alias rad = Units!("Radian", Angle, 1.0/(PI*2));

alias V = Units!("Volt", Voltage);
alias mV = Units!("Milli Volt", Voltage, 1e-3);
alias uV = Units!("Micro Volt", Voltage, 1e-6);
alias nV = Units!("Nano Volt", Voltage, 1e-9);
alias KV = Units!("Kilo Volt", Voltage, 1e3);
alias MV = Units!("Mega Volt", Voltage, 1e3);

alias A = Units!("Ampere", Current);
alias mA = Units!("Milli Ampere", Current, 1e-3);
alias uA = Units!("Micro Ampere", Current, 1e-6);
alias nA = Units!("Nano Ampere", Current, 1e-9);
alias KA = Units!("Kilo Ampere", Current, 1e3);

alias Ohm = Units!("Ohm", Resistance);
alias mOhm = Units!("Milli Ohm", Resistance, 1e-3);
alias uOhm = Units!("Micro Ohm", Resistance, 1e-6);
alias KOhm = Units!("Kilo Ohm", Resistance, 1e3);
alias MOhm = Units!("Mega Ohm", Resistance, 1e6);

alias F = Units!("Farad", Capacitance);
alias mF = Units!("Milli Farad", Capacitance, 1e-3);
alias uF = Units!("Micro Farad", Capacitance, 1e-6);
alias nF = Units!("Nano Farad", Capacitance, 1e-9);
alias pF = Units!("Pico Farad", Capacitance, 1e-12);

alias H = Units!("Henry", Inductance);
alias mH = Units!("Milli Henry", Inductance, 1e-3);
alias uH = Units!("Micro Henry", Inductance, 1e-6);
alias nH = Units!("Nano Henry", Inductance, 1e-9);
alias pH = Units!("Pico Henry", Inductance, 1e-12);

alias W = Units!("Watt", Power);
alias mW = Units!("Milli Watt", Power, 1e-3);
alias uW = Units!("uW", Power, 1e-6);
alias nW = Units!("nW", Power, 1e-9);
alias KW = Units!("Kilo Watt", Power, 1e3);
alias MW = Units!("Mega Watt", Power, 1e6);

alias J = Units!("Joule", Energy);
alias mJ = Units!("Milli Joule", Energy, 1e-3);
alias uJ = Units!("Micro Joule", Energy, 1e-6);
alias nJ = Units!("Nano Joule", Energy, 1e-9);
alias KJ = Units!("Kilo Joule", Energy, 1e3);
alias MJ = Units!("Mega Joule", Energy, 1e6);

alias Kelvin = Units!("Kelvin", Temperature);
alias Celsius = Units!("Celsius", Temperature, 1.0, 273.15);
alias Fahrenheit = Units!("Fahrenheit", Temperature, 5.0/9.0, 459.67);

alias sec = Units!("Second", Time);
alias msec = Units!("Milli Second", Time, 1e-3);
alias usec = Units!("Micro Second", Time, 1e-6);
alias nsec = Units!("Nano Second", Time, 1e-9);
alias min = Units!("Minute", Time, 60);
alias hour = Units!("Hour", Time, 60*60);
alias day = Units!("Day", Time, 60*60*24);
alias week = Units!("Week", Time, 60*60*24*7);
alias mon = Units!("Month", Time, 60*60*24*30);
alias year = Units!("Year", Time, 60*60*24*365);

/// Units wrapping and conversion
nothrow @nogc unittest {
  assert(1.25.as!m == cast(Val!(double, m)) 1.25);
  assert(1.25.as!m.to!mm == 1250.0.as!mm);
  assert(1.25.as!m.to!cm == 125.0.as!cm);

  assert(123.as!deg == cast(Val!(int, deg)) 123);
  assert_eq(180.0.as!deg.to!rad, (cast(double) PI).as!rad, 0.00001);
  assert_eq(60.0.as!deg.to!rad, (cast(double) PI / 3.0).as!rad, 0.000001);

  assert(1.5.as!sec == cast(Val!(double, sec)) 1.5);
  assert(1.5.as!sec.to!msec == 1500.0.as!msec);
  assert(3.125.as!sec.to!usec == 3125000.0.as!usec);
  assert(0.25.as!sec.to!usec == 250000.0.as!usec);

  alias X = fix!(-10, 10);

  assert(X(1.25).as!m.raw == X(1.25));
  assert(X(1.25).as!m == Val!(X, m)(X(1.25)));
  assert(X(1.25).as!m == cast(Val!(X, m)) 1.25);

  assert_eq((fix!(-10, 10)(1.25)).as!m.to!mm, (fix!(-10000, 10000)(1250.0)).as!mm);
  assert_eq(fix!(-10, 10)(1.25).as!m.to!cm, fix!(-1000, 1000)(125.0).as!cm);
}

/// Arithmetic operations
nothrow @nogc unittest {
  assert_eq(-(1.0.as!V), (-1.0).as!V);

  assert_eq(1.0.as!V + 2.0.as!V, 3.0.as!V);
  assert_eq(1.0.as!V + 2000.0.as!mV, 3.0.as!V);
  assert_eq(1.0.as!V + 0.002.as!MV, 3.0.as!V);

  assert_eq(1.0.as!V - 2.0.as!V, -1.0.as!V);
  assert_eq(1.0.as!V - 2000.0.as!mV, -1.0.as!V);
  assert_eq(1.0.as!V - 0.002.as!MV, -1.0.as!V);

  assert_eq(1.0.as!V * 2.0, 2.0.as!V);
  assert_eq(1.0.as!V / 2.0, 0.5.as!V);
  assert_eq(1.0.as!V % 2.0, 1.0.as!V);
}

/// Comparison operations
nothrow @nogc unittest {
  assert(1.0.as!V == 1.0.as!V);
  assert(1.0.as!V == 1000.0.as!mV);
  assert(1.0.as!V == 0.001.as!MV);

  assert(1.0.as!V != 2.0.as!V);
  assert(1.0.as!V != 1001.0.as!mV);
  assert(1.0.as!V != 0.0011.as!MV);

  assert(1.0.as!V < 2.0.as!V);
  assert(1.0.as!V < 2000.0.as!mV);
  assert(1.0.as!V < 0.002.as!MV);

  assert(1.0.as!V > 0.9.as!V);
  assert(1.0.as!V > 900.0.as!mV);
  assert(1.0.as!V > 0.0009.as!MV);
}

/// Op-assign operations
nothrow @nogc unittest {
  auto a = 3.0.as!V;

  a += 1.5.as!V;
  assert_eq(a, 4.5.as!V);

  a -= 1.5.as!V;
  assert_eq(a, 3.0.as!V);

  a += 1500.0.as!mV;
  assert_eq(a, 4.5.as!V);

  a -= 1500.0.as!mV;
  assert_eq(a, 3.0.as!V);

  a += 0.0015.as!MV;
  assert_eq(a, 4.5.as!V);

  a -= 0.0015.as!MV;
  assert_eq(a, 3.0.as!V);

  a *= 2.0;
  assert_eq(a, 6.0.as!V);

  a /= 2.0;
  assert_eq(a, 3.0.as!V);

  a %= 2.0;
  assert_eq(a, 1.0.as!V);
}

/// Defines new measurement units
struct Units(string name_, alias Class_, real factor_ = 1, real offset_ = 0) if (isUnitsClass!Class_) {
  alias Class = Class_;
  enum string name = name_;
  enum real factor = factor_;
  enum real offset = offset_;
}

/// Checks if somethig is measurement units
template isUnits(X...) if (X.length == 1) {
  enum bool isUnits = isInstanceOf!(Units, X[0]);
}

/// Defines new measurement units class
struct UnitsClass(string name_) {
  enum string name = name_;
}

/// Checks if something is measurement units class
template isUnitsClass(X...) if (X.length == 1) {
  enum bool isUnitsClass = isInstanceOf!(UnitsClass, X[0]);
}
