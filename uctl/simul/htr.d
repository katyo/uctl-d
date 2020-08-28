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
struct Param(C_, M_, R_, T_, D_) if (isNumer!(C_, M_, R_, T_, D_)) {
  alias C = C_;
  alias M = M_;
  alias R = R_;
  alias T = T_;
  alias D = D_;

  alias CmR = typeof(C() * M() * R());
  alias InvCmRdt = typeof(asnum!(1, T) / (CmR() + D()));

  alias PA = typeof(T() * D() * InvCmRdt());
  alias PB = typeof(CmR() * InvCmRdt());
  alias PC = typeof(R() * D() * InvCmRdt());

  /// Term `a` value
  PA a;
  /// Term `b` value
  PB b;
  /// Term `c` value
  PC c;

  /**
     Initialize heater parameters

     Params:
     C_ = Thermal capacity of heating block
     m_ = Mass of heating block
     R_ = Thermal resistance of heating block
     Ta = Ambient temperature
     dt = Simulation step period

     Example (typical FDM-printer aluminium hotend):
     ```
     import uctl.simul.htr;

     static immutable auto p = mk!Param(990.0, 6.75e-3, 8.4, 25.0, 0.1);
     ```
   */
  const pure nothrow @nogc @safe
  this(C C_, M m_, R R_, T Ta, D dt) {
    auto CmR = C_ * m_ * R_;
    auto inv_CmR_dt = asnum!(1, T) / (dt + CmR);

    // A = Ta * dt / (dt + CmR)
    a = Ta * dt * inv_CmR_dt;
    // B = CmR / (dt + CmR)
    b = CmR * inv_CmR_dt;
    // C = R * dt / (dt + CmR)
    c = R_ * dt * inv_CmR_dt;
  }
}

/// Create heater parameters
pure nothrow @nogc @safe
Param!(C, M, R, T, D) mk(alias P, C, M, R, T, D)(C C_, M m_, R R_, T Ta, D dt) if (isNumer!(C, M, R, T, D) && __traits(isSame, P, Param)) {
  return Param!(C, M, R, T, D)(C_, m_, R_, Ta, dt);
}

/// Test heater parameters (floating-point)
nothrow @nogc unittest {
  static immutable auto p = mk!Param(990.0, 6.75e-3, 8.4, 25.0, 0.1);

  assert_eq(p.a, 0.04445788058, 1e-10);
  assert_eq(p.b, 0.9982216838, 1e-9);
  assert_eq(p.c, 0.01493784787, 1e-10);
}

/// Test heater parameters (fixed-point)
nothrow @nogc unittest {
  static immutable auto p = mk!Param(asfix!990.0, asfix!6.75e-3, asfix!8.4, asfix!25.0, asfix!0.1);

  assert_eq(p.a, asfix!0.04445788058, fix!(0.04445788058)(1e-10));
  assert_eq(p.b, asfix!0.9982216838, fix!(0.9982216838)(1e-10));
  assert_eq(p.c, asfix!0.01493784787, fix!(0.01493784787)(1e-10));
}

/**
   Heater model state
 */
struct State(P_, T_) if (isInstanceOf!(Param, P_) && isNumer!(P_.T, T_)) {
  alias P = P_;
  alias T = T_;

  /// Current temperature of heating block
  T temp = 0.0;

  /// Initialize state using initial temperature
  const pure nothrow @nogc @safe this(const T t0) {
    temp = t0;
  }

  // Evaluate simulation step
  pure nothrow @nogc @safe
  T apply(W)(const ref P param, const W power) {
    return temp = cast(T) (param.a + param.b * temp + param.c * power);
  }
}

/// Test heater simulation (floating-point)
nothrow @nogc unittest {
  static immutable auto p = mk!Param(990.0, 6.75e-3, 8.4, 25.0, 0.1);
  static auto s = State!(typeof(p), double)(22.5);

  assert_eq(s.apply(p, 40.0), 23.10195947, 1e-6);
  assert_eq(s.apply(p, 40.0), 23.70284843, 1e-6);
  assert_eq(s.apply(p, 30.0), 24.15329027, 1e-6);
}

/// Test heater simulation (fixed-point)
nothrow @nogc unittest {
  alias T = fix!(-30, 400);

  static immutable auto p = mk!Param(asfix!990.0, asfix!6.75e-3, asfix!8.4, asfix!25.0, asfix!0.1);
  static auto s = State!(typeof(p), T)(T(22.5));

  assert_eq(s.apply(p, asfix!40.0), T(23.10195947));
  assert_eq(s.apply(p, asfix!40.0), T(23.70284843));
  assert_eq(s.apply(p, asfix!30.0), T(24.15329027));
}
