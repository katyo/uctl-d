/**
   ### Steinhart-Hart model

   The most accurate math model of thermistor called Steinhart-Hart equation. It is the third-order approximation which looks like that:

   $(MATH \frac{1}{T} = a + b\,\ln(R) + c\,\ln(R)^3) (1)

   where $(I R) [$(I Ω)] — thermistor resistance on temperature $(I T) [$(I K)] (Here and below the temperature measured in Kelvins. For °C you can use formula $(MATH T = T_{^{o}C} + 273.15). For °F you can use formula $(MATH T = \left( T_{^{o}F} - 32 \right) \times \frac{5}{9} + 273.15)), $(I a), $(I b), $(I c) — Steinhart-Hart parameters.

   Find temperature $(I T) from (1):

   $(MATH T = \frac{1}{a + b\,\ln(R) + c\,\ln(R)^3}) (2)

   Typically this model allows achieve accuracy up to 0.02° in range over 200°C.

   Parameters can be found using Gauss method with set of experimental $(I T)-values and corresponding $(I R)-values. Select some three points $(MATH [R_i, T_i]) from experimental set and apply it to (1):

   $(MATH \frac{1}{T_0} = a + b\,\ln(R_0) + c\,\ln(R_0)^3) (3.1)

   $(MATH \frac{1}{T_1} = a + b\,\ln(R_1) + c\,\ln(R_1)^3) (3.2)

   $(MATH \frac{1}{T_2} = a + b\,\ln(R_2) + c\,\ln(R_2)^3) (3.3)

   We have a system of linear algebraic equations with three equations and variables $(I a), $(I b) and $(I c). Now we may use Gauss method and eliminate variables step-by-step. Subtract (3.2) from (3.1), and (3.3) from (3.1) in order to we eliminate variable $(I a).

   $(MATH \frac{1}{T_0} - \frac{1}{T_1} = b\,\left( \ln(R_0) - \ln(R_1) \right) + c\,\left( \ln(R_0)^3 - \ln(R_1)^3 \right)) (3.12)

   $(MATH \frac{1}{T_0} - \frac{1}{T_2} = b\,\left( \ln(R_0) - \ln(R_2) \right) + c\,\left( \ln(R_0)^3 - \ln(R_2)^3 \right)) (3.13)

   Now divide (3.12) by $(MATH \ln(R_0) - \ln(R_1)) and (3.13) by $(MATH \ln(R_0) - \ln(R_1)):

   $(MATH \frac{\frac{1}{T_0} - \frac{1}{T_1}}{\ln(R_0) - \ln(R_1)} = b + c\,\frac{\ln(R_0)^3 - \ln(R_1)^3}{\ln(R_0) - \ln(R_1)}) (3.12')

   $(MATH \frac{\frac{1}{T_0} - \frac{1}{T_1}}{\ln(R_0) - \ln(R_2)} = b + c\,\frac{\ln(R_0)^3 - \ln(R_2)^3}{\ln(R_0) - \ln(R_2)}) (3.13')

   Subtract (3.13') from (3.12') in order to eliminate variable $(I b):

   $(MATH \frac{\frac{1}{T_0} - \frac{1}{T_1}}{\ln(R_0) - \ln(R_1)} - \frac{\frac{1}{T_0} - \frac{1}{T_1}}{\ln(R_0) - \ln(R_2)} = c\,\left( \frac{\ln(R_0)^3 - \ln(R_1)^3}{\ln(R_0) - \ln(R_1)} - \frac{\ln(R_0)^3 - \ln(R_2)^3}{\ln(R_0) - \ln(R_2)} \right)) (3.123)

   Now we can find formula for direct computation of parameter $(I c):

   $(MATH c = \frac{\frac{\frac{1}{T_0} - \frac{1}{T_1}}{\ln(R_0) - \ln(R_1)} - \frac{\frac{1}{T_0} - \frac{1}{T_1}}{\ln(R_0) - \ln(R_2)}}{\frac{\ln(R_0)^3 - \ln(R_1)^3}{\ln(R_0) - \ln(R_1)} - \frac{\ln(R_0)^3 - \ln(R_2)^3}{\ln(R_0) - \ln(R_2)}}) (3.c)

   Find parameter $(I b) from (3.12') bearing in mind, that parameter $(I c) we can found using (3.c):

   $(MATH b = \frac{\frac{1}{T_0} - \frac{1}{T_1}}{\ln(R_0) - \ln(R_1)} - c\,\frac{\ln(R_0)^3 - \ln(R_1)^3}{\ln(R_0) - \ln(R_1)}) (3.b)

   Now, when we know parameters $(I c) and $(I b), we can find parameter $(I a) from (3.1):

   $(MATH a = \frac{1}{T_0} - b\,\ln(R_0) + c\,\ln(R_0)^3) (3.a)

   ### Simplified β-model

   Typically values of parameters of Steinhart-Hart model is too small, so practical using that model presents some difficulties. In order to simplify this model, we can represent this parameters by the following way:

   $(MATH a = \frac{1}{T_0} - \frac{1}{\beta} \ln(R_0) \vert b = \frac{1}{\beta} \vert c = 0) (4.1)

   After substituting (4.1) into (1) we have:

   $(MATH \frac{1}{T} = \frac{1}{T_0} + \frac{1}{\beta} \ln \left( \frac{R}{R_0} \right)) (4.2)

   Find $(I T) from (4.2):

   $(MATH T = \frac{1}{\frac{1}{T_0} + \frac{1}{\beta} \ln \left( \frac{R}{R_0} \right)}) (5.1)

   Or:

   $(MATH T = \frac{T_0 \beta}{T_0\,ln \left( \frac{R}{R_0} \right) + \beta}) (5.2)

   Parameter $(MATH \beta) can be found as following:

   $(MATH \beta = \frac{\ln \left( \frac{R}{R_0} \right)}{(\frac{1}{T}) - (\frac{1}{T_0})}) (6.1)

   Or:

   $(MATH \beta = \frac{T_0\,T\,ln\left( \frac{R}{R_0} \right)}{T_0-T}) (6.2)

   As you can see, this parameter can be found, when we have at least two experimental values of resistance $(I R) and corresponding temperature $(I T). But for some reasons model will be less-precise in this case.

   ![Comparison of thermistor models](thr_fit.svg)
 */
module uctl.simul.thr;

import std.traits: isInstanceOf;
import std.math: E;
import uctl.num: isNumer, asnum;
import uctl.unit: hasUnits, as, to, Resistance, Ohm, Temperature, degK, rawTypeOf;
import uctl.math.log: log;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.num: asfix, fix;
  import uctl.unit: degC, KOhm;

  mixin unittests;
}

/// Thermistor model
struct Model(string name_, bool calcT_ = false, bool calcR_ = false) {
  /// Model name
  enum string name = name_;

  /// Can calculate temperature from resistance
  enum bool calcT = calcT_;

  /// Can calculate resistance from temperature
  enum bool calcR = calcR_;
}

/// Check that type is thermistor model
template isModel(X...) if (X.length == 1 || X.length == 2) {
  static if (X.length == 1) {
    static if (is(X[0])) {
      enum bool isModel = isInstanceOf!(Model, X[0]);
    } else {
      enum bool isModel = isModel!(typeof(X[0]));
    }
  } else static if (X.length == 2 && isModel!(X[0]) && isModel!(X[1])) {
    enum bool isModel = X[0].name == X[1].name;
  } else {
    enum bool isModel = false;
  }
}

/// Enable temperature from resistance calculation
template calcT(alias M) if (isModel!M) {
  alias calcT = Model!(M.name, true, M.calcR);
}

/// Enable resistance from temperature calculation
template calcR(alias M) if (isModel!M) {
  alias calcR = Model!(M.name, M.calcT, true);
}

/// Steinhart-Hart thermistor model
alias SteinhartHart = Model!("Steinhart-Hart model");

/// Simplified β-model of thermistor
alias Beta = Model!("Simplified beta model");

/// Thermistor parameters for Steinhart-Hart model
struct Param(alias M, A, B, C) if (isModel!(M, SteinhartHart) && isNumer!(A, B, C)) {
  static assert(!M.calcR,
                "Calculation of resistance from temperature using Steinhart-Hart model is " ~
                "too computationally expensive and not supported. You can use simplified beta model.");

  static if (M.calcT) {
    /// The first coefficient of model
    A a;
    /// The second coefficient of model
    B b;
    /// The third coefficient of model
    C c;
  }

  /// Initialize thermistor parameters
  const pure nothrow @nogc @safe
  this(const A a_, const B b_, const C c_) {
    static if (M.calcT) {
      a = a_;
      b = b_;
      c = c_;
    }
  }

  static if (M.calcT) {
    /// Calculate temperature from resistance
    pure nothrow @nogc @safe
    auto opCall(R)(const R r) const
    if (hasUnits!(R, Resistance) && isNumer!(rawTypeOf!R, A)) {
      const rr = r.to!Ohm.raw;
      const lnR = log(rr);
      const tr = asnum!(1, rawTypeOf!R) / (a + b * lnR + c * lnR * lnR * lnR);
      return tr.as!degK;
    }
  }
}

/// Create parameters for Steinhart-Hart model of thermistor
pure nothrow @nogc @safe Param!(M, A, B, C)
mk(alias M, A, B, C)(const A a, const B b, const C c) if (isModel!(M, SteinhartHart) && isNumer!(A, B, C)) {
  return Param!(M, A, B, C)(a, b, c);
}

/// Test NTC 100K thermistor (floating-point)
nothrow @nogc unittest {
  // a = -0.00400110693, b = 0.00077306258, c = -0.00000099773
  static immutable ntc100k = mk!(calcT!SteinhartHart)(-0.00400110693, 0.00077306258, -0.00000099773);

  assert_eq(ntc100k(100.0.as!KOhm), 23.0094033.as!degC.to!degK, 1e-5);
  assert_eq(ntc100k(24.0.as!KOhm), 87.5718161.as!degC.to!degK, 1e-6);
  assert_eq(ntc100k(82.0.as!KOhm), 29.8317295.as!degC.to!degK, 1e-6);
}

/// Test NTC 100K thermistor (fixed-point)
nothrow @nogc unittest {
  // a = -0.00400110693, b = 0.00077306258, c = -0.00000099773
  static immutable ntc100k = mk!(calcT!SteinhartHart)(asfix!(-0.00400110693),
                                                      asfix!(0.00077306258),
                                                      asfix!(-0.00000099773));

  alias R = fix!(15, 150);
  alias T = fix!(230, 580);

  assert_eq(ntc100k(R(100).as!KOhm).to!degC, T(23.0094033).as!degC);
  assert_eq(ntc100k(R(24).as!KOhm).to!degC, T(87.5718161).as!degC);
  assert_eq(ntc100k(R(82).as!KOhm).to!degC, T(29.8317295).as!degC);
}

/// Thermistor parameters for simplified β-model
struct Param(alias M, R, T, B) if (isModel!(M, Beta) &&
                                   hasUnits!(R, Resistance) &&
                                   hasUnits!(T, Temperature) &&
                                   isNumer!(rawTypeOf!R, rawTypeOf!T, B)) {
  alias Rraw = typeof(R().to!Ohm.raw);
  alias Traw = typeof(T().to!degK.raw);

  static if (M.calcT) {
    alias InvR = typeof(asnum!(1, Rraw) / Rraw());
    alias InvT = typeof(asnum!(1, Traw) / Traw());
    alias InvB = typeof(asnum!(1, B) / B());

    /// $(MATH \frac{1}{R_0}) value
    InvR inv_r0;
    /// $(MATH \frac{1}{T_0}) value
    InvT inv_t0;
    /// $(MATH \frac{1}{\beta}) value
    InvB inv_beta;
  }

  static if (M.calcR) {
    alias BInvT = typeof(B() / Traw());

    /// $(MATH R_0) value
    Rraw r0;
    /// $(MATH \frac{\beta}{T_0}) value
    BInvT beta_inv_t0;
    /// $(MATH \frac{1}{\beta}) value
    B beta;
  }

  /// Initialize thermistor parameters
  const pure nothrow @nogc @safe
  this(const R r0_, const T t0_, const B beta_) {
    const _r0 = r0_.to!Ohm.raw;
    const _t0 = t0_.to!degK.raw;

    static if (M.calcT) {
      inv_r0 = asnum!(1, Rraw) / _r0;
      inv_t0 = asnum!(1, Traw) / _t0;
      inv_beta = asnum!(1, B) / beta_;
    }

    static if (M.calcR) {
      r0 = _r0;
      beta_inv_t0 = beta_ / _t0;
      beta = beta_;
    }
  }

  static if (M.calcT) {
    /// Calculate temperature from resistance
    pure nothrow @nogc @safe
    auto opCall(R_)(const R_ r) const
    if (hasUnits!(R_, Resistance) && isNumer!(rawTypeOf!R_, Rraw)) {
      const rr = r.to!Ohm.raw;
      const tr = asnum!(1, Traw) / (inv_t0 + inv_beta * log(rr * inv_r0));

      return tr.as!degK.to!(T.units);
    }
  }

  static if (M.calcR) {
    /// Calculate resistance from temperature
    pure nothrow @nogc @safe
    auto opCall(T_)(const T_ t) const
    if (hasUnits!(T_, Temperature) && isNumer!(rawTypeOf!T_, Traw)) {
      const tr = t.to!degK.raw;
      const rr = r0 * exp(beta / tr - beta_inv_t0);

      return rr.as!Ohm.to!(R.units);
    }
  }
}

/// Create parameters for simplified β-model of thermistor
pure nothrow @nogc @safe Param!(M, R, T, B)
mk(alias M, R, T, B)(const R r0, const T t0, const B beta)
if (isModel!(M, Beta) &&
    hasUnits!(R, Resistance) &&
    hasUnits!(T, Temperature) &&
    isNumer!(rawTypeOf!R, rawTypeOf!T, B)) {
  return Param!(M, R, T, B)(r0, t0, beta);
}

/// Test NTC 100K thermistor (floating-point)
nothrow @nogc unittest {
  // R0 = 100KΩ, T0 = 25°C, β = 3950
  static immutable ntc100k = mk!(calcT!Beta)(100.0.as!KOhm, 25.0.as!degC, 3950.0);

  assert_eq(ntc100k.inv_r0, 1.00000000000000008e-05);
  assert_eq(ntc100k.inv_t0, 0.00335401643468052988);
  assert_eq(ntc100k.inv_beta, 0.000253164556962025332);

  assert_eq(ntc100k(100.0.as!KOhm), 25.0.as!degC);
  assert_eq(ntc100k(24.0.as!KOhm), 60.9940609679212571.as!degC);
  assert_eq(ntc100k(82.0.as!KOhm), 29.5339875403824408.as!degC);
}

/// Test NTC 100K thermistor (floating-point)
nothrow @nogc unittest {
  // R0 = 100KΩ, T0 = 25°C, β = 3950
  static immutable ntc100k = mk!(calcT!Beta)(100f.as!KOhm, 25f.as!degC, 3950f);

  assert_eq(ntc100k.inv_r0, 9.999999996e-6f);
  assert_eq(ntc100k.inv_t0, 0.003354016433f);
  assert_eq(ntc100k.inv_beta, 0.0002531645569f);

  assert_eq(ntc100k(100f.as!KOhm), 25.0f.as!degC);
  assert_eq(ntc100k(24f.as!KOhm), 60.994049072f.as!degC);
  assert_eq(ntc100k(82f.as!KOhm), 29.533996582f.as!degC);
}

/// Test NTC 100K thermistor (fixed-point)
nothrow @nogc unittest {
  // R0 = 100KΩ, T0 = 25°C, β = 3950
  static immutable ntc100k = mk!(calcT!Beta)(asfix!100.as!KOhm, asfix!25.as!degC, asfix!3950);

  assert_eq(ntc100k.inv_r0, asfix!9.999999996e-6);
  assert_eq(ntc100k.inv_t0, asfix!0.003354016433);
  assert_eq(ntc100k.inv_beta, asfix!0.0002531645569);

  alias R = fix!(15, 150);
  alias T = fix!(10, 100);

  assert_eq(ntc100k(100.0.as!KOhm.to!R), 25.0.as!degC.to!T);
  assert_eq(ntc100k(24.0.as!KOhm.to!R), 60.99406123.as!degC.to!T);
  assert_eq(ntc100k(82.0.as!KOhm.to!R), 29.53398752.as!degC.to!T);
}

/// Create parameters for simplified β-model of thermistor using two points $(MATH [R_x, T_x])
template mk(alias M, R0, T0, R1, T1) if (isModel!(M, Beta) &&
                                         hasUnits!(R0, Resistance) && hasUnits!(R1, Resistance) &&
                                         hasUnits!(T0, Temperature) && hasUnits!(T1, Temperature) &&
                                         isNumer!(rawTypeOf!R0, rawTypeOf!T0, rawTypeOf!R1, rawTypeOf!T1)) {
  alias T0raw = typeof(T0().to!degK.raw);
  alias T1raw = typeof(T1().to!degK.raw);
  alias R0raw = typeof(R0().to!Ohm.raw);
  alias R1raw = typeof(R1().to!Ohm.raw);
  alias B = typeof(T0raw() * T1raw() * log(R1raw() / R0raw()) / (T0raw() - T1raw()));

  Param!(M, R0, T0, B) mk(const R0 r0, const T0 t0, const R1 r1, const T1 t1) {
    const t0_ = t0.to!degK.raw;
    const t1_ = t1.to!degK.raw;
    const r0_ = r0.to!Ohm.raw;
    const r1_ = r1.to!Ohm.raw;
    const beta = t0_ * t1_ * log(r1_ / r0_) / (t0_ - t1_);

    return Param!(M, R0, T0, B)(r0, t0, beta);
  }
}

/// Test NTC 100K thermistor (floating-point)
nothrow @nogc unittest {
  // Points: [100KΩ, 25°C], [24KΩ, 61°C]
  static immutable ntc100k = mk!(calcT!Beta)(100f.as!KOhm, 25f.as!degC, 24f.as!KOhm, 61f.as!degC);

  assert_eq(ntc100k.inv_r0, 1e-5f);
  assert_eq(ntc100k.inv_t0, 0.003354016, 1e-9);
  assert_eq(ntc100k.inv_beta, 0.000253202, 1e-9);

  assert_eq(ntc100k(100f.as!KOhm), 25f.as!degC);
  assert_eq(ntc100k(24f.as!KOhm), 61f.as!degC);
  assert_eq(ntc100k(82f.as!KOhm), 29.534667969f.as!degC);
}

/// Test NTC 100K thermistor (fixed-point)
nothrow @nogc unittest {
  // Points: [100KΩ, 24°C], [24KΩ, 80°C]
  static immutable ntc100k = mk!(calcT!Beta)(asfix!100.as!KOhm,
                                             asfix!25.as!degC,
                                             asfix!24.as!KOhm,
                                             asfix!61.as!degC);

  assert_eq(ntc100k.inv_r0, asfix!9.999999996e-6);
  assert_eq(ntc100k.inv_t0, asfix!0.003354016433);
  assert_eq(ntc100k.inv_beta, asfix!0.0002532018273);

  alias R = fix!(15, 150);
  alias T = fix!(10, 100);

  assert_eq(ntc100k(100.0.as!KOhm.to!R), 25.0.as!degC.to!T);
  assert_eq(ntc100k(24.0.as!KOhm.to!R), 61.as!degC.to!T);
  assert_eq(ntc100k(82.0.as!KOhm.to!R), 29.53466511.as!degC.to!T);
}
