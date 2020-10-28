/**
   ## Measurement units

   Units grouped by classes. Units can be added to any numeric values using function [as]. The `.raw` field of [Val] can be used to get numeric value back. Units can be converted to another units of same class using function [to].

   $(TABLE_ROWS
   Units prefixes
   * + Prefix
     + Description
     + Factor
   * - `m`
     - Milli
     - 10e-3
   * - `u`
     - Micro
     - 10e-6
   * - `n`
     - Nano
     - 10e-9
   * - `p`
     - Pico
     - 10e-12
   * - `K`
     - Kilo
     - 10e3
   * - `M`
     - Mega
     - 10e6
   * - `G`
     - Giga
     - 10e9
   )

   $(TABLE_ROWS
   Supported measurement units
   * + Class
     + Units
     + Description
     + Variants
   * - Length
     - `m`
     - Meter
     - `dm`, `cm`, `mm`, `um`, `nm`, `Km`
   * - Area
     - `m2`
     - Square meter
     - `dm2`, `cm2`, `mm2`, `um2`, `nm2`, `Km2`
   * - Volume
     - `m3`
     - Cubic meter
     - `dm3`, `cm3`, `mm3`, `um3`, `nm3`, `Km3`
   * - Angle
     - `deg`
     - Degree
   * - Angle
     - `rad`
     - Radian
   * - Angle
     - `rev`
     - Revolution (2π, 360°)
   * - Angle
     - `hrev`
     - Half revolution (π, 180°)
   * - Angle
     - `qrev`
     - Quarter revolution (½π, 90°)
   * - Voltage
     - `V`
     - Volt
     - `mV`, `uV`, `nV`, `KV`, `MV`
   * - Current
     - A
     - Ampere
     - `mA`, `uA`, `nA`, `KA`
   * - Resistance
     - `Ohm`
     - Ohm
     - `mOhm`, `uOhm`, `KOhm`, `MOhm`
   * - Capacitance
     - `F`
     - Farad
     - `mF`, `uF`, `nF`, `pF`
   * - Inductance
     - `H`
     - Henry
     - `mH`, `uH`, `nH`, `pH`
   * - Force
     - `N`
     - Newton
     - `KN`, `MN`, `mN`, `uN`
   * - Mass
     - `Kg`
     - Kilogram
     - `ug`, `mg`, `g`, `Mg`, `T`
   * - Torque
     - `Nm`
     - Newton·meter
     - `mNm`, `KNm`, `Ncm`, `Nmm`
   * - Power
     - `W`
     - Watt
     - `mW`, `uW`, `nW`, `KW`, `MW`
   * - Energy
     - `J`
     - Joule
     - `mJ`, `uJ`, `nJ`, `KJ`, `MJ`
   * - Temperature
     - `degK`
     - Kelvin degree
   * - Temperature
     - `degC`
     - Celsius degree
   * - Temperature
     - `degF`
     - Fahrenheit degree
   * - Time
     - `sec`
     - Second
     - `msec`, `usec`, `nsec`
   * - Time
     - `min`
     - Minute
   * - Time
     - `hour`
     - Hour
   * - Time
     - `day`
     - Day
   * - Time
     - `week`
     - Week
   * - Time
     - `mon`
     - Month
   * - Time
     - `year`
     - Year
   * - Frequency
     - `Hz`
     - Hertz
     - `KHz`, `MHz`, `GHz`
   )
 */
module uctl.unit;

import std.math: PI;
import std.traits: Unqual, isInstanceOf;
import uctl.num: isNum, fix, asnum, isFixed, isNumer;

version(unittest) {
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/**
   Value with measurement units
 */
struct Val(T, U) if (is(T) && isNumer!T && is(U) && isUnits!U) {
  /// Measurement units
  alias units = U;

  /// Raw value type
  alias raw_t = Unqual!T;

  /// Raw numeric value
  T raw;

  /// Wrap raw value to units
  pure nothrow @nogc @safe
  this(X)(const X val) const if (__traits(compiles, cast(T) val)) { raw = cast(T) val; }

  /// Get raw value back
  pure nothrow @nogc @safe
  X opCast(X)() const if (is(X == T)) { return raw; }

  /// Convert underlying raw value
  pure nothrow @nogc @safe
  X opCast(X)() const if (hasUnits!(X, U)) {
    return (cast(X.raw_t) raw).as!U;
  }

  /// Negation
  pure nothrow @nogc @safe
  auto opUnary(string op)() const if (op == "-") {
    return (- cast(T) raw).as!U;
  }

  /// Addition/subtraction
  pure nothrow @nogc @safe
  auto opBinary(string op, A)(const A other) const if ((op == "+" || op == "-") &&
                                                       hasUnits!A && is(U.Class == A.units.Class)) {
    auto raw1 = cast(T) raw;
    static if(is(U == A.units)) { // same units
      // casting needs for removing const qualifiers
      auto raw2 = cast(A.raw_t) other.raw;
    } else { // same class
      const auto other2 = other.to!U;
      auto raw2 = cast(typeof(other2).raw_t) other2.raw;
    }
    return mixin("raw1" ~ op ~ "raw2").as!U;
  }

  /// Multiplication/division by unit-less
  pure nothrow @nogc @safe
  auto opBinary(string op, A)(const A other) const if ((op == "*" || op == "/" ||
                                                        op == "%") && isNumer!A) {
    auto raw1 = cast(T) raw;
    auto raw2 = cast(A) other;

    return mixin("raw1" ~ op ~ "raw2").as!U;
  }

  /// Equality (==)
  pure nothrow @nogc @safe
  bool opEquals(A)(const A other) const if (hasUnits!A && is(U.Class == A.units.Class)) {
    static if(is(U == A.units)) { // same units
      auto raw2 = other.raw;
    } else { // same class
      auto raw2 = other.to!U.raw;
    }
    return raw == raw2;
  }

  /// Hashing
  /// TODO: implement
  pure nothrow @nogc @safe
  size_t toHash(size_t seed = 0) const {
    return seed;
  }

  /// Comparison (<>)
  pure nothrow @nogc @safe
  int opCmp(A)(const A other) const if (hasUnits!A && is(U.Class == A.units.Class)) {
    static if(is(U == A.units)) { // same units
      immutable raw2 = other.raw;
    } else { // same class
      immutable raw2 = other.to!U.raw;
    }
    return raw < raw2 ? -1 : raw > raw2 ? 1 : 0;
  }

  /// Adding/subtracting value (+=, -=)
  pure nothrow @nogc @safe
  opOpAssign(string op, A)(const A other) if ((op == "+" || op == "-") && hasUnits!A && is(U.Class == A.units.Class)) {
    static if(is(U == A.units)) { // same units
      immutable raw2 = other.raw;
    } else { // same class
      immutable raw2 = other.to!U.raw;
    }
    mixin("return raw" ~ op ~ "=raw2;");
  }

  /// Multiplying to/dividing by/remainder of raw value (*=, /=, %=)
  pure nothrow @nogc @safe
  opOpAssign(string op, A)(const A other) if ((op == "*" || op == "/" || op == "%") && isNumer!A) {
    mixin("return raw" ~ op ~ "=other;");
  }
}

/// Check that some value or type has measurement units
template hasUnits(X...) {
  static if (X.length == 1) {
    static if (is(X[0])) {
      enum bool hasUnits = isInstanceOf!(Val, X[0]);
    } else {
      enum bool hasUnits = hasUnits!(typeof(X));
    }
  } else static if (X.length == 2) {
    static if (hasUnits!(X[0])) {
      static if (isUnits!(X[1])) {
        enum bool hasUnits = is(X[0].units == X[1]);
      } else static if (isUnitsClass!(X[1])) {
        enum bool hasUnits = is(X[0].units.Class == X[1]);
      } else {
        enum bool hasUnits = false;
      }
    } else {
      enum bool hasUnits = false;
    }
  } else {
    enum bool hasUnits = false;
  }
}

/// Test `hasUnits`
nothrow @nogc @safe unittest {
  struct NoVal(T) { T val; }

  assert(hasUnits!(Val!(float, rad)));
  assert(!hasUnits!(NoVal!(float)));

  assert(hasUnits!(Val!(float, rad), rad));
  assert(!hasUnits!(Val!(float, rad), deg));

  assert(hasUnits!(Val!(float, rad), Angle));
  assert(!hasUnits!(Val!(float, rad), Length));

  assert(hasUnits!(12.as!rad));

  assert(hasUnits!(12.as!rad, rad));
  assert(!hasUnits!(12.as!rad, deg));

  assert(hasUnits!(12.as!rad.to!deg, deg));
  assert(!hasUnits!(12.as!rad.to!deg, rad));

  assert(hasUnits!(12.as!rad, Angle));
  assert(!hasUnits!(12.as!rad, Length));
}

/// Get raw value type
template rawTypeOf(X...) if (X.length == 1) {
  static if (is(X[0])) {
    static if (hasUnits!(X[0])) {
      alias rawTypeOf = X[0].raw_t;
    } else {
      alias rawTypeOf = X[0];
    }
  } else {
    alias rawTypeOf = rawTypeOf!(typeof(X[0]));
  }
}

/// Test `rawTypeOf`
nothrow @nogc @safe unittest {
  assert(is(rawTypeOf!int == int));
  assert(is(rawTypeOf!(Val!(int, mm)) == int));
  assert(is(rawTypeOf!1 == int));
  assert(is(rawTypeOf!(1.as!mm) == int));

  assert(is(rawTypeOf!(float) == float));
  assert(is(rawTypeOf!(Val!(float, mm)) == float));
  assert(is(rawTypeOf!1f == float));
  assert(is(rawTypeOf!(1f.as!mm) == float));

  alias X = fix!(0, 10);

  assert(is(rawTypeOf!(X) == X));
  assert(is(rawTypeOf!(Val!(X, mm)) == X));
  assert(is(rawTypeOf!(X(1)) == X));
  assert(is(rawTypeOf!(X(1).as!mm) == X));
}

/// Get raw value
pure nothrow @nogc @safe
auto rawOf(T)(const T val) if (isNumer!T || hasUnits!T) {
  static if (hasUnits!T) {
    return val.raw;
  } else {
    return val;
  }
}

/// Create value literal of same class
template asval(T, real raw) if (hasUnits!T) {
  enum auto asval = asval!(raw, T);
}

/// Create value literal of same class
template asval(real raw, T) if (hasUnits!T) {
  enum auto asval = asnum!(raw, T.raw_t).as!(T.units);
}

/// Test `asval`
nothrow @nogc unittest {
  alias F = Val!(float, V);
  assert(is(typeof(asval!(1.0, F)) == F));
  assert(is(typeof(asval!(F, 0.0)) == F));

  alias X = Val!(fix!(-1, 1), Ohm);
  assert(is(typeof(asval!(1.0, X)) == Val!(fix!1, Ohm)));
  assert(is(typeof(asval!(X, 0.0)) == Val!(fix!0, Ohm)));
}

/// Add measurement units to raw value
pure nothrow @nogc @safe
Val!(T, U) as(U, T)(T val) if (is(T) && isNumer!T && is(U) && isUnits!U) {
  return typeof(return)(val);
}

/// Add measurement units from another type to raw value
pure nothrow @nogc @safe
auto as(V, T)(T val) if (is(T) && isNumer!T && is(V) && (isNumer!V || hasUnits!V)) {
  static if (hasUnits!V) {
    return val.as!(V.units);
  } else {
    return val;
  }
}

/// Convert values from some units to another
pure nothrow @nogc @safe
auto to(U, T)(const T val) if (isUnits!U && hasUnits!(T, U.Class)) {
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

    return (val.raw * asnum!(factor, T.raw_t) + asnum!(offset, T.raw_t)).as!U;
  }
}

/// Linear units class
alias Length = UnitsClass!("Length");
/// Angular units class
alias Angle = UnitsClass!("Angle");

/// Linear velocity
alias LinearVel = UnitsClass!("Linear Velocity");
/// Angular velocity
alias AngularVel = UnitsClass!("Angular Velocity");

/// Linear acceleration
alias LinearAccel = UnitsClass!("Linear Acceleration");
/// Angular acceleration
alias AngularAccel = UnitsClass!("Angular Acceleration");

/// Linear jerk
alias LinearJerk = UnitsClass!("Linear Jerk");
/// Angular jerk
alias AngularJerk = UnitsClass!("Angular Jerk");

/// Area units class
alias Area = UnitsClass!("Area");
/// Volume units class
alias Volume = UnitsClass!("Volume");

/// Voltage units class
alias Voltage = UnitsClass!("Voltage");
/// Current units class
alias Current = UnitsClass!("Current");

/// Force units
alias Force = UnitsClass!("Force");
/// Mass units
alias Mass = UnitsClass!("Mass");

/// Torque units
alias Torque = UnitsClass!("Torque");

/// Power units class
alias Power = UnitsClass!("Power");
/// Energy units class
alias Energy = UnitsClass!("Energy");

/// Resistance units class
alias Resistance = UnitsClass!("Resistance");
/// Capacitance units class
alias Capacitance= UnitsClass!("Capacitance");
/// Inductance units class
alias Inductance = UnitsClass!("Inductance");

/// Temperature units class
alias Temperature = UnitsClass!("Temperature");

/// Time units class
alias Time = UnitsClass!("Time");

/// Frequency units class (1/period)
alias Frequency = UnitsClass!("Frequency");

alias m = Units!("Meter", Length);
alias dm = Units!("DeciMeter", Length, 1e-1);
alias cm = Units!("CentiMeter", Length, 1e-2);
alias mm = Units!("MilliMeter", Length, 1e-3);
alias um = Units!("MicroMeter", Length, 1e-6);
alias nm = Units!("NanoMeter", Length, 1e-9);
alias Km = Units!("KiloMeter", Length, 1e3);

alias m2 = Units!("Square Meter", Area);
alias dm2 = Units!("Square deciMeter", Area, 1e-2);
alias cm2 = Units!("Square centiMeter", Area, 1e-4);
alias mm2 = Units!("Square milliMeter", Area, 1e-6);
alias um2 = Units!("Square microMeter", Area, 1e-12);
alias nm2 = Units!("Square nanoMeter", Area, 1e-18);
alias Km2 = Units!("Square kiloMeter", Area, 1e6);

alias m3 = Units!("Cubic Meter", Area);
alias dm3 = Units!("Cubic deciMeter", Area, 1e-3);
alias cm3 = Units!("Cubic centiMeter", Area, 1e-6);
alias mm3 = Units!("Cubic milliMeter", Area, 1e-9);
alias um3 = Units!("Cubic microMeter", Area, 1e-18);
alias nm3 = Units!("Cubic nanoMeter", Area, 1e-27);
alias Km3 = Units!("Cubic kiloMeter", Area, 1e9);

alias rev = Units!("Revolution", Angle);
alias hrev = Units!("Half Revolution", Angle, 1.0/2.0);
alias qrev = Units!("Quarter Revolution", Angle, 1.0/4.0);
alias deg = Units!("Degree", Angle, 1.0/360.0);
alias rad = Units!("Radian", Angle, 1.0/(2.0*PI));

alias V = Units!("Volt", Voltage);
alias mV = Units!("MilliVolt", Voltage, 1e-3);
alias uV = Units!("MicroVolt", Voltage, 1e-6);
alias nV = Units!("NanoVolt", Voltage, 1e-9);
alias KV = Units!("KiloVolt", Voltage, 1e3);
alias MV = Units!("MegaVolt", Voltage, 1e3);

alias A = Units!("Ampere", Current);
alias mA = Units!("MilliAmpere", Current, 1e-3);
alias uA = Units!("MicroAmpere", Current, 1e-6);
alias nA = Units!("NanoAmpere", Current, 1e-9);
alias KA = Units!("KiloAmpere", Current, 1e3);

alias N = Units!("Newton", Force);
alias mN = Units!("MilliNewton", Force, 1e-3);
alias uN = Units!("MicroNewton", Force, 1e-6);
alias KN = Units!("KiloNewton", Force, 1e3);
alias MN = Units!("MegaNewton", Force, 1e6);

alias Kg = Units!("KiloGram", Mass);
alias g = Units!("Gram", Mass, 1e-3);
alias mg = Units!("MilliGram", Mass, 1e-6);
alias ug = Units!("MicroGram", Mass, 1e-9);
alias Mg = Units!("MegaGram", Mass, 1e3);
alias T = Units!("Tonne", Mass, 1e3);

alias Nm = Units!("Newton·Meter", Torque);
alias mNm = Units!("MilliNewton·Meter", Torque, 1e-3);
alias KNm = Units!("KiloNewton·Meter", Torque, 1e3);
alias Ncm = Units!("Newton·CentiMeter", Torque, 1e-2);
alias Nmm = Units!("Newton·MilliMeter", Torque, 1e-3);

alias W = Units!("Watt", Power);
alias mW = Units!("MilliWatt", Power, 1e-3);
alias uW = Units!("MicroWatt", Power, 1e-6);
alias nW = Units!("NanoWatt", Power, 1e-9);
alias KW = Units!("KiloWatt", Power, 1e3);
alias MW = Units!("MegaWatt", Power, 1e6);

alias HP = Units!("Horse power", Power, 735.49875);

alias J = Units!("Joule", Energy);
alias mJ = Units!("MilliJoule", Energy, 1e-3);
alias uJ = Units!("MicroJoule", Energy, 1e-6);
alias nJ = Units!("NanoJoule", Energy, 1e-9);
alias KJ = Units!("KiloJoule", Energy, 1e3);
alias MJ = Units!("MegaJoule", Energy, 1e6);

alias Ohm = Units!("Ohm", Resistance);
alias mOhm = Units!("MilliOhm", Resistance, 1e-3);
alias uOhm = Units!("MicroOhm", Resistance, 1e-6);
alias KOhm = Units!("KiloOhm", Resistance, 1e3);
alias MOhm = Units!("MegaOhm", Resistance, 1e6);

alias F = Units!("Farad", Capacitance);
alias mF = Units!("MilliFarad", Capacitance, 1e-3);
alias uF = Units!("MicroFarad", Capacitance, 1e-6);
alias nF = Units!("NanoFarad", Capacitance, 1e-9);
alias pF = Units!("PicoFarad", Capacitance, 1e-12);

alias H = Units!("Henry", Inductance);
alias mH = Units!("MilliHenry", Inductance, 1e-3);
alias uH = Units!("MicroHenry", Inductance, 1e-6);
alias nH = Units!("NanoHenry", Inductance, 1e-9);
alias pH = Units!("PicoHenry", Inductance, 1e-12);

alias degK = Units!("Kelvin", Temperature);
alias degC = Units!("Celsius", Temperature, 1.0, 273.15);
alias degF = Units!("Fahrenheit", Temperature, 5.0/9.0, 459.67);

alias sec = Units!("Second", Time);
alias msec = Units!("MilliSecond", Time, 1e-3);
alias usec = Units!("MicroSecond", Time, 1e-6);
alias nsec = Units!("NanoSecond", Time, 1e-9);
alias min = Units!("Minute", Time, 60);
alias hour = Units!("Hour", Time, 60*60);
alias day = Units!("Day", Time, 60*60*24);
alias week = Units!("Week", Time, 60*60*24*7);
alias mon = Units!("Month", Time, 60*60*24*30);
alias year = Units!("Year", Time, 60*60*24*365);

alias Hz = Units!("Hertz", Frequency);
alias KHz = Units!("KiloHertz", Frequency, 1e3);
alias MHz = Units!("MegaHertz", Frequency, 1e6);
alias GHz = Units!("GigaHertz", Frequency, 1e9);

/// Units wrapping and conversion
nothrow @nogc unittest {
  assert(1.25.as!m == cast(Val!(double, m)) 1.25);
  assert(1.25.as!m.to!mm == 1_250.0.as!mm);
  assert(1.25.as!m.to!cm == 125.0.as!cm);

  assert(123.as!deg == cast(Val!(int, deg)) 123);
  assert_eq(180.0.as!deg.to!rad, (cast(double) PI).as!rad, 0.000_01);
  assert_eq(60.0.as!deg.to!rad, (cast(double) PI / 3.0).as!rad, 0.000_001);

  assert(1.5.as!sec == cast(Val!(double, sec)) 1.5);
  assert(1.5.as!sec.to!msec == 1_500.0.as!msec);
  assert(3.125.as!sec.to!usec == 3_125_000.0.as!usec);
  assert(0.25.as!sec.to!usec == 250_000.0.as!usec);

  assert_eq(25.0.as!degC.to!degK, 298.15.as!degK);
  assert_eq(298.15.as!degK.to!degC, 25.0.as!degC);
  assert_eq(73.4.as!degF.to!degK, 296.15.as!degK, 1e-10);
  assert_eq(296.15.as!degK.to!degF, 73.4.as!degF, 1e-10);
  assert_eq(73.4.as!degF.to!degC, 23.0.as!degC, 1e-10);
  assert_eq(23.0.as!degC.to!degF, 73.4.as!degF);

  assert_eq(1.0.as!HP.to!W, 735.498_75.as!W);
  assert_eq(1.0.as!W.to!HP, 0.001_359_621_617_303_904.as!HP);

  alias X = fix!(-10, 10);

  assert(X(1.25).as!m.raw == X(1.25));
  assert(X(1.25).as!m == Val!(X, m)(X(1.25)));
  assert(X(1.25).as!m == cast(Val!(X, m)) 1.25);

  assert_eq((fix!(-10, 10)(1.25)).as!m.to!mm, (fix!(-10_000, 10_000)(1_250.0)).as!mm);
  assert_eq(fix!(-10, 10)(1.25).as!m.to!cm, fix!(-1_000, 1_000)(125.0).as!cm);
}

/// Arithmetic operations
nothrow @nogc unittest {
  assert_eq(-(1.0.as!V), (-1.0).as!V);

  assert_eq(1.0.as!V + 2.0.as!V, 3.0.as!V);
  assert_eq(1.0.as!V + 2_000.0.as!mV, 3.0.as!V);
  assert_eq(1.0.as!V + 0.002.as!MV, 3.0.as!V);

  assert_eq(1.0.as!V - 2.0.as!V, -1.0.as!V);
  assert_eq(1.0.as!V - 2_000.0.as!mV, -1.0.as!V);
  assert_eq(1.0.as!V - 0.002.as!MV, -1.0.as!V);

  assert_eq(1.0.as!V * 2.0, 2.0.as!V);
  assert_eq(1.0.as!V / 2.0, 0.5.as!V);
  assert_eq(1.0.as!V % 2.0, 1.0.as!V);
}

/// Comparison operations
nothrow @nogc unittest {
  assert(1.0.as!V == 1.0.as!V);
  assert(1.0.as!V == 1_000.0.as!mV);
  assert(1.0.as!V == 0.001.as!MV);

  assert(1.0.as!V != 2.0.as!V);
  assert(1.0.as!V != 1_001.0.as!mV);
  assert(1.0.as!V != 0.001_1.as!MV);

  assert(1.0.as!V < 2.0.as!V);
  assert(1.0.as!V < 2_000.0.as!mV);
  assert(1.0.as!V < 0.002.as!MV);

  assert(1.0.as!V > 0.9.as!V);
  assert(1.0.as!V > 900.0.as!mV);
  assert(1.0.as!V > 0.000_9.as!MV);
}

/// Op-assign operations
nothrow @nogc unittest {
  auto a = 3.0.as!V;

  a += 1.5.as!V;
  assert_eq(a, 4.5.as!V);

  a -= 1.5.as!V;
  assert_eq(a, 3.0.as!V);

  a += 1_500.0.as!mV;
  assert_eq(a, 4.5.as!V);

  a -= 1_500.0.as!mV;
  assert_eq(a, 3.0.as!V);

  a += 0.001_5.as!MV;
  assert_eq(a, 4.5.as!V);

  a -= 0.001_5.as!MV;
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
  /// Units class
  alias Class = Class_;
  /// Units name
  enum string name = name_;

  /// Units multiplier factor
  enum real factor = factor_;
  /// Units value offset
  enum real offset = offset_;
}

/// Checks if somethig is measurement units
template isUnits(X...) if (X.length == 1 || X.length == 2) {
  static if (X.length == 1) {
    enum bool isUnits = isInstanceOf!(Units, X[0]);
  } else static if (isUnits!(X[0]) && isUnitsClass!(X[1])) {
    enum bool isUnits = is(X[0].Class == X[1]);
  } else {
    enum bool isUnits = false;
  }
}

/// Defines new measurement units class
struct UnitsClass(string name_) {
  /// Units class name
  enum string name = name_;
}

/// Checks if something is measurement units class
template isUnitsClass(X...) if (X.length == 1) {
  enum bool isUnitsClass = isInstanceOf!(UnitsClass, X[0]);
}

/// Checks that units is time or frequency
template isTimingUnits(X...) if (X.length == 1) {
  enum bool isTimingUnits = isUnits!(X[0], Time) || isUnits!(X[0], Frequency);
}

/// Test `isTimingUnits`
nothrow @nogc unittest {
  assert(isTimingUnits!usec);
  assert(isTimingUnits!MHz);
  assert(!isTimingUnits!deg);
}

/// Checks that value is time or frequency
template isTiming(X...) if (X.length == 1) {
  enum bool isTiming = hasUnits!(X[0], Time) || hasUnits!(X[0], Frequency);
}

/// Test `isTiming`
nothrow @nogc unittest {
  assert(isTiming!(1.0.as!usec));
  assert(isTiming!(0.5.as!MHz));
  assert(!isTiming!(45.0.as!deg));
}

/// Convert timing units
pure nothrow @nogc @safe
auto to(U, T)(const T val) if ((isUnits!(U, Time) && hasUnits!(T, Frequency)) ||
                               (isUnits!(U, Frequency) && hasUnits!(T, Time))) {
  static if (hasUnits!(T, Time)) {
    return (asnum!(1, T.raw_t) / val.to!sec.raw).as!Hz.to!U;
  } else {
    return (asnum!(1, T.raw_t) / val.to!Hz.raw).as!sec.to!U;
  }
}

/// Test convert sampling units
nothrow @nogc unittest {
  assert_eq(50.0.as!Hz.to!sec, 20e-3.as!sec);
  assert_eq(20e-3.as!sec.to!Hz, 50.0.as!Hz);

  assert_eq(1.0.as!KHz.to!msec, 1.0.as!msec);
  assert_eq(1.0.as!msec.to!KHz, 1.0.as!KHz);

  assert_eq(250.0f.as!MHz.to!nsec, 4.0f.as!nsec);
  assert_eq(4.0f.as!nsec.to!MHz, 250.0f.as!MHz);
}

/// Generate timing constants
template asTiming(alias s, U, T) if (!is(s) && isTiming!s && isTimingUnits!U && (isNumer!T || hasUnits!T)) {
  enum raw = s.to!U.raw;

  enum asTiming = asnum!(raw, rawTypeOf!T).as!U;
}

/// Test `asTiming`
nothrow @nogc unittest {
  enum s = 1.0.as!msec;
  alias dt = asTiming!(s, sec, float);
  alias f = asTiming!(s, Hz, float);

  assert(dt == 1.0f.as!msec);
  assert(f == 1.0f.as!KHz);
}

/// Test `asTiming`
nothrow @nogc unittest {
  enum s = 1.0.as!KHz;
  alias dt = asTiming!(s, sec, float);
  alias f = asTiming!(s, Hz, float);

  assert(dt == 1.0f.as!msec);
  assert(f == 1.0f.as!KHz);
}
