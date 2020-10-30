/**
   ## Heater model

   Simple heater model for realtime simulation.

   Model input:
   $(LIST
   * $(MATH P) - applied heater power, $(I W)
   )

   Model output:
   $(LIST
   * $(MATH \dot{T}) - current heating block temperature, $(I °)
   )

   Model parameters:
   $(LIST
   * $(MATH R) - thermal resistance between heater and ambient, $(I °/W)
   * $(MATH C) - thermal capacity of heating block, $(I J/°) or $(I Kg/m$(SUPERSCRIPT 2)S$(SUPERSCRIPT -2)°)
   * $(MATH m) - mass of heating block, $(I Kg)
   * $(MATH T_a) - ambient temperature, $(I °)
   * $(MATH dt) - simulation step period, $(I S)
   )

   Model state:
   $(LIST
   * $(MATH T) - previous heating block temperature, $(I °)
   )

   Model definition:

   $(MATH P = P_a + P_d) (1)

   where:
   $(LIST
   * $(MATH P) - total power, $(I W)
   * $(MATH P_a) - accumulating power, $(I W)
   * $(MATH P_d) - diffusing power, $(I W)
   )

   $(MATH P_a = C m \frac{\dot{T} - T}{dt}) (2)

   $(MATH P_d = \frac{T - T_a}{R}) (3)

   $(MATH P = C m \frac{\dot{T} - T}{dt} + \frac{T - T_a}{R})

   $(MATH \dot{T} = \frac{C m R \times T + (T_a + P R) \times dt}{C m R + dt})

   $(MATH \dot{T} = \frac{T_a dt}{dt + C m R} + T \frac{CmR}{dt + C m R} + P \frac{R dt}{dt + C m R}) (4)

   Let
   $(MATH a = \frac{T_a dt}{dt + C m R})
   $(MATH b = \frac{C m R}{dt + C m R})
   $(MATH c = \frac{R dt}{dt + C m R})

   So $(MATH \dot{T} = a + T \times b + P \times c) (5)

   Check for initial off-state conditions when $(MATH P = 0) and $(MATH T = T_a):

   $(MATH \dot{T} = T_a \frac{dt}{dt + C m R} + T_a \frac{ C m R}{dt + C m R})

   $(MATH \dot{T} = T_a \frac{dt + C m R}{dt + C m R})

   $(MATH \dot{T} = T_a)

   Check for off-state condition when $(MATH P = 0):

   $(MATH \dot{T} = T_a \frac{dt}{dt + C m R} + T \frac{C m R}{dt + C m R})

   Let $(MATH T = T_a + T_d)

   where $(MATH T_d) - temperature delta for single simulation step.

   $(MATH \dot{T} = T_a \frac{dt}{dt + C m R} + T_a \frac{C m R}{dt + C m R} + T_d \frac{C m R}{dt + C m R})

   $(MATH \dot{T} = T_a + T_d \frac{C m R}{dt + C m R})

   Because $(MATH \frac{C m R}{dt + C m R} < 1)
   so $(MATH T_d \frac{C m R}{dt + C m R} \rightarrow 0)
   and then $(MATH \dot{T} \rightarrow T_a)

   ![Hotend simulation example](sim_htr.svg)
*/
module uctl.simul.htr;

import std.traits: isInstanceOf, Unqual;
import uctl.unit: isTiming, asTiming, sec, hasUnits, as, to, rawTypeOf, rawof, Temperature, degK, degC, ThermalResistance, degK_W, ThermalCapacity, J_degK, Mass, Kg, Power, W;
import uctl.num: isNumer, asnum, typeOf;

version(unittest) {
  import uctl.num: asfix, fix;
  import uctl.unit: msec, g;
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/**
   Heater parameters

   Params:
   s_ = Simulation step period
   C_ = Thermal capacity of heating block
   m_ = Mass of heating block
   R_ = Thermal resistance of heating block
 */
struct Param(alias s_, C_, M_, R_) if (!is(s_) && isTiming!s_ &&
                                       hasUnits!(C_, ThermalCapacity) &&
                                       hasUnits!(M_, Mass) &&
                                       hasUnits!(R_, ThermalResistance) &&
                                       isNumer!(rawTypeOf!C_, rawTypeOf!M_, rawTypeOf!R_)) {
  alias C = C_;
  alias M = M_;
  alias R = R_;

  alias Cnorm = typeof(C().to!J_degK);
  alias Mnorm = typeof(M().to!Kg);
  alias Rnorm = typeof(R().to!degK_W);

  alias Craw = rawTypeOf!Cnorm;
  alias Mraw = rawTypeOf!Mnorm;
  alias Rraw = rawTypeOf!Rnorm;

  /// Sampling time
  enum s = asTiming!(s_, sec, Craw);
  enum dt = s.raw;

  alias CmR = typeof(Craw() * Mraw() * Rraw());
  alias InvCmRdt = typeof(asnum!(1, Craw) / (CmR() + dt));

  alias PA = typeof(dt * InvCmRdt());
  alias PB = typeof(CmR() * InvCmRdt());
  alias PC = typeof(Rraw() * dt * InvCmRdt());

  /// Term `a` value
  PA a;
  /// Term `b` value
  PB b;
  /// Term `c` value
  PC c;

  /**
     Initialize heater parameters

     Params:
     dt_ = Simulation step period
     C_ = Thermal capacity of heating block
     m_ = Mass of heating block
     R_ = Thermal resistance of heating block

     Example (typical FDM-printer aluminium hotend):
     ```
     import uctl.simul.htr;

     static immutable auto p = mk!(Param, 0.1.as!sec)(990.0.as!J_degK, 6.75.as!g, 8.4.as!degK_W);
     ```
   */
  const pure nothrow @nogc @safe
  this(C C_, M m_, R R_) {
    const Rraw = R_.to!degK_W.raw;
    const CmR = C_.to!J_degK.raw * m_.to!Kg.raw * Rraw;
    const inv_CmR_dt = asnum!(1, typeof(CmR)) / (dt + CmR);

    // A = dt / (dt + CmR)
    a = dt * inv_CmR_dt;
    // B = CmR / (dt + CmR)
    b = CmR * inv_CmR_dt;
    // C = R * dt / (dt + CmR)
    c = Rraw * dt * inv_CmR_dt;
  }
}

/// Create heater parameters
pure nothrow @nogc @safe auto
mk(alias P, alias s, C, M, R)(C C_, M m_, R R_) if (__traits(isSame, P, Param) &&
                                                    !is(s) && isTiming!s &&
                                                    hasUnits!(C, ThermalCapacity) &&
                                                    hasUnits!(M, Mass) &&
                                                    hasUnits!(R, ThermalResistance) &&
                                                    isNumer!(rawTypeOf!C, rawTypeOf!M, rawTypeOf!R)) {
  return Param!(s, C, M, R)(C_, m_, R_);
}

/// Test heater parameters (floating-point)
nothrow @nogc unittest {
  enum dt = 100.0.as!msec;
  static immutable p = mk!(Param, dt)(990.0.as!J_degK, 6.75.as!g, 8.4.as!degK_W);

  assert_eq(p.dt, 0.1);
  assert_eq(p.a, 0.001778315223, 1e-10);
  assert_eq(p.b, 0.9982216838, 1e-9);
  assert_eq(p.c, 0.01493784787, 1e-10);
}

/// Test heater parameters (fixed-point)
nothrow @nogc unittest {
  enum dt = 100.0.as!msec;
  auto p = mk!(Param, dt)(asfix!990.0.as!J_degK, asfix!6.75.as!g, asfix!8.4.as!degK_W);

  assert_eq(p.a, asfix!0.001778315223);
  assert_eq(p.b, asfix!0.9982216838);
  assert_eq(p.c, asfix!0.014937847875);
}

/**
   Heater model state
 */
struct State(alias P_, T_) if (isInstanceOf!(Param, typeOf!P_) && hasUnits!(T_, Temperature) && isNumer!(P_.Craw, rawTypeOf!T_)) {
  alias P = Unqual!(typeOf!P_);
  alias T = Unqual!T_;

  static if (is(T.units == degK)) {
    alias Tint_units = degK;
  } else {
    // Avoid Fahrenheit degrees
    alias Tint_units = degC;
  }
  alias Tint_raw = rawTypeOf!(typeof(T().to!Tint_units));

  /// Current temperature of heating block
  Tint_raw _t = 0.0;

  /// Get current temperature
  pure nothrow @nogc @safe
  T t() const {
    return cast(T) _t.as!Tint_units.to!(T.units);
  }

  /// Initialize state using initial temperature
  pure nothrow @nogc @safe
  this(const T t0) const {
    _t = t0.to!Tint_units.raw;
  }

  /**
     Evaluate simulation step

     Params:
     W = Applied power type
     power = Applied power
     env_temp = Ambient temperature
  */
  pure nothrow @nogc @safe
  T opCall(PW)(const ref P param, const PW power, const T env_temp) if (hasUnits!(PW, Power)) {
    _t = cast(Tint_raw) (param.a * env_temp.to!Tint_units.raw + param.b * _t + param.c * power.to!W.raw);
    return t;
  }
}

/// Create header state
pure nothrow @nogc @safe
auto mk(alias P, T)(const T t0) if (isInstanceOf!(Param, typeOf!P) && hasUnits!(T, Temperature) && isNumer!(P.Craw, rawTypeOf!T)) {
  return State!(P, T)(t0);
}

/// Test heater simulation (floating-point)
nothrow @nogc unittest {
  enum dt = 100.0.as!msec;

  static immutable p = mk!(Param, dt)(990.0.as!J_degK, 6.75.as!g, 8.4.as!degK_W);
  static s = mk!p(22.5.as!degC);

  assert_eq(s(p, 40.0.as!W, 25.0.as!degC), 23.10195947.as!degC, 1e-6);
  assert_eq(s(p, 40.0.as!W, 25.0.as!degC), 23.70284843.as!degC, 1e-6);
  assert_eq(s(p, 30.0.as!W, 25.0.as!degC), 24.15329027.as!degC, 1e-6);
}

/// Test heater simulation (fixed-point)
nothrow @nogc unittest {
  alias T = fix!(-30, 400);
  enum dt = 100.0.as!msec;

  static immutable p = mk!(Param, dt)(asfix!990.0.as!J_degK, asfix!6.75.as!g, asfix!8.4.as!degK_W);
  static s = mk!p(T(22.5).as!degC);

  assert_eq(s(p, asfix!40.0.as!W, T(25.0).as!degC), T(23.10195947).as!degC);
  assert_eq(s(p, asfix!40.0.as!W, T(25.0).as!degC), T(23.70284843).as!degC);
  assert_eq(s(p, asfix!30.0.as!W, T(25.0).as!degC), T(24.15329027).as!degC);
}
