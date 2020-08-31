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

import std.traits: isInstanceOf;
import uctl.num: isNumer, asnum;

version(unittest) {
  import uctl.num: asfix, fix;
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/**
   Heater parameters
 */
struct Param(real dt_, C_, M_, R_) if (isNumer!(C_, M_, R_)) {
  alias C = C_;
  alias M = M_;
  alias R = R_;

  enum rdt = dt_;
  enum dt = asnum!(dt_, C);

  alias CmR = typeof(C() * M() * R());
  alias InvCmRdt = typeof(asnum!(1, C) / (CmR() + dt));

  alias PA = typeof(dt * InvCmRdt());
  alias PB = typeof(CmR() * InvCmRdt());
  alias PC = typeof(R() * dt * InvCmRdt());

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

     static immutable auto p = mk!(Param, 0.1)(990.0, 6.75e-3, 8.4);
     ```
   */
  const pure nothrow @nogc @safe
  this(C C_, M m_, R R_) {
    auto CmR = C_ * m_ * R_;
    auto inv_CmR_dt = asnum!(1, C) / (dt + CmR);

    // A = dt / (dt + CmR)
    a = dt * inv_CmR_dt;
    // B = CmR / (dt + CmR)
    b = CmR * inv_CmR_dt;
    // C = R * dt / (dt + CmR)
    c = R_ * dt * inv_CmR_dt;
  }
}

/// Check for parameters
template isParam(X...) if (X.length == 1) {
  static if (is(X[0])) {
    enum bool isParam = isInstanceOf!(Param, X[0]);
  } else {
    enum bool isParam = isParam!(typeof(X[0]));
  }
}

/// Create heater parameters
pure nothrow @nogc @safe
Param!(dt, C, M, R) mk(alias P, real dt, C, M, R)(C C_, M m_, R R_) if (isNumer!(C, M, R) && __traits(isSame, P, Param)) {
  return Param!(dt, C, M, R)(C_, m_, R_);
}

/// Test heater parameters (floating-point)
nothrow @nogc unittest {
  enum auto dt = 0.1;
  static immutable auto p = mk!(Param, dt)(990.0, 6.75e-3, 8.4);

  assert_eq(p.a, 0.001778315223, 1e-10);
  assert_eq(p.b, 0.9982216838, 1e-9);
  assert_eq(p.c, 0.01493784787, 1e-10);
}

/// Test heater parameters (fixed-point)
nothrow @nogc unittest {
  enum auto dt = 0.1;
  static immutable auto p = mk!(Param, dt)(asfix!990.0, asfix!6.75e-3, asfix!8.4);

  assert_eq(p.a, asfix!0.001778315223);
  assert_eq(p.b, asfix!0.9982216838);
  assert_eq(p.c, asfix!0.014937847875);
}

/**
   Heater model state
 */
struct State(alias P_, T_) if (isParam!P_ && isNumer!(P_.C, T_)) {
  static if (is(P_)) {
    alias P = P_;
  } else {
    alias P = typeof(P_);
  }
  alias T = T_;

  /// Current temperature of heating block
  T temp = 0.0;

  /// Initialize state using initial temperature
  const pure nothrow @nogc @safe this(const T t0) {
    temp = t0;
  }

  /**
     Evaluate simulation step

     Params:
     W = Applied power type
     power = Applied power
     env_temp = Ambient temperature
  */
  pure nothrow @nogc @safe
  T apply(W)(const ref P param, const W power, const T env_temp) {
    return temp = cast(T) (param.a * env_temp + param.b * temp + param.c * power);
  }
}

/// Test heater simulation (floating-point)
nothrow @nogc unittest {
  enum auto dt = 0.1;

  static immutable auto p = mk!(Param, dt)(990.0, 6.75e-3, 8.4);
  static auto s = State!(typeof(p), double)(22.5);

  assert_eq(s.apply(p, 40.0, 25.0), 23.10195947, 1e-6);
  assert_eq(s.apply(p, 40.0, 25.0), 23.70284843, 1e-6);
  assert_eq(s.apply(p, 30.0, 25.0), 24.15329027, 1e-6);
}

/// Test heater simulation (fixed-point)
nothrow @nogc unittest {
  alias T = fix!(-30, 400);
  enum auto dt = 0.1;

  static immutable auto p = mk!(Param, dt)(asfix!990.0, asfix!6.75e-3, asfix!8.4);
  static auto s = State!(p, T)(T(22.5));

  assert_eq(s.apply(p, asfix!40.0, T(25.0)), T(23.10195947));
  assert_eq(s.apply(p, asfix!40.0, T(25.0)), T(23.70284843));
  assert_eq(s.apply(p, asfix!30.0, T(25.0)), T(24.15329027));
}
