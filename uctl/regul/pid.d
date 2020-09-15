/**
   ## PID controller

   Proportional Integral Derivative (PID) regulator.

   The Proportional (P), Proportional Integral (PI) and Proportional Derivative (PD) variants are also supported.

   ![PID Control of heater block vs contant power](sim_pid_htr.svg)

   See_Also:
   [PID controller](https://en.wikipedia.org/wiki/PID_controller) wikipedia article.
 */
module uctl.regul.pid;

import std.traits: isInstanceOf;
import uctl.num: isNumer, asnum;

// TODO: Tests for coupled P
// TODO: Tests for limited I

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.num: fix;

  mixin unittests;
}

/**
   Regulator class

   Params:
   name_ = symbolic class name (for debugging purposes)
   hasP_ = class has proportional term
   hasI_ = class has integral term
   hasD_ = class has derivative term
   coupledP_ = class has decoupled proportional term
   limitedI_ = class has integral error limiting
*/
struct Class(string name_, bool hasP_ = true, bool hasI_ = false, bool hasD_ = false, bool coupledP_ = false, bool limitedI_ = false) {
  /// Class name
  enum string name = name_;

  /// Class has Proportional factor
  enum bool hasP = hasP_;

  /// Class has Integral factor
  enum bool hasI = hasI_;

  /// Class has Derivative factor
  enum bool hasD = hasD_;

  /// Coupled Proportional term
  enum bool coupledP = coupledP_;

  /// Integral error limiting
  enum bool limitedI = limitedI_;
}

/// Couple Proportional term
template CoupleP(C) if (isClass!C) {
  alias CoupleP = Class!(C.name ~ " (coupled Proportional term)", C.hasP, C.hasI, C.hasD, true, C.limitedI);
}

/// Limit Integral error
template LimitI(C) if (isClass!C && C.hasI) {
  alias LimitI = Class!(C.name ~ " (limited Integral error)", C.hasP, C.hasI, C.hasD, C.coupledP, true);
}

/// Proportional-only regulator class
alias PO = Class!("Proportional only");

/// Proportional Integral regulator class
alias PI = Class!("Proportional Integral", true, true);

/// Proportional Derivative regulator class
alias PD = Class!("Proportional Derivative", true, false, true);

/// Proportional Integral Derivative regulator class
alias PID = Class!("Proportional Integral Derivative", true, true, true);

/// Check for regulator class
template isClass(X...) {
  static if (X.length == 1) {
    enum bool isClass = isInstanceOf!(Class, X[0]);
  } else static if (X.length == 2) {
    static if (isClass!(X[0])) {
      enum bool isClass = X[0].hasP == X[1].hasP && X[0].hasI == X[1].hasI && X[0].hasD == X[1].hasD;
    } else {
      enum bool isClass = false;
    }
  }
}

/// Test `isClass`
nothrow @nogc unittest {
  assert(isClass!PO);
  assert(isClass!PI);
  assert(isClass!PD);
  assert(isClass!PID);

  alias P_ = CoupleP!PO;
  assert(isClass!(P_, PO));
  alias PI_ = LimitI!PI;
  assert(isClass!(PI_, PI));

  assert(!isClass!float);
  assert(!isClass!bool);
  struct NonClass {}
  assert(!isClass!NonClass);

  alias PD_ = PD;
  assert(!isClass!(PD_, PO));
  alias PID_ = PID;
  assert(!isClass!(PID_, PI));
}

/// Check for regulator params
template isParam(X...) {
  static if (X.length == 1) {
    static if (is(X[0])) {
      enum bool isParam = isInstanceOf!(Param, X[0]);
    } else {
      enum bool isParam = isParam!(typeof(X[0]));
    }
  } else static if (X.length == 2) {
    enum bool isParam = isParam!(X[0]) && isClass!(X[1]) && is(X[0].Class == X[1]);
  }
}

/// Test `isParam`
nothrow @nogc unittest {
  assert(isParam!(Param!(PO, float)));
  assert(isParam!(Param!(PI, float, float, float)));
  assert(isParam!(Param!(PD, float, float)));
  assert(isParam!(Param!(PID, float, float, float, float)));

  assert(isParam!(Param!(PO, float), PO));
  assert(isParam!(Param!(PI, float, float, float), PI));
  assert(isParam!(Param!(PD, float, float), PD));
  assert(isParam!(Param!(PID, float, float, float, float), PID));

  assert(!isParam!(float));
  struct NoParam {}
  assert(!isParam!(NoParam));
  assert(!isParam!(Param!(PO, float), PI));
  assert(!isParam!(Param!(PI, float, float, float), PD));
  assert(!isParam!(Param!(PD, float, float), PID));
  assert(!isParam!(Param!(PID, float, float, float, float), PO));
}

/**
   Proportional regulator parameters

   This structure supports builder pattern, so you can construct it and call `.with_<property>(<value>)` functions in chain.
   By default all parameter fields is out because it has zero-size. This is important optimization, because it helps save memory.
   For example, in case of Proportional-Integral (PI) regulator we do not need derivative parameter, so we hide according field from parameters structure by applying `none` type to it.

   Params:
   C = Regulator class
   P_ = Proportional factor type
*/
struct Param(C, P_) if (isClass!(C, PO) && isNumer!P_) {
  /// Regulator class
  alias Class = C;

  /// Proportional factor type
  alias P = P_;

  /// Proportional factor
  P p;

  /// Create Proportional regulator parameters
  this(const P p_) {
    p = p_;
  }

  /**
     Convert to PI parameters by adding integral factor

     Params:
     E = Integral error type
     I = Integral factor type
     i = Integral factor
  */
  const pure nothrow @nogc @safe
  Param!(PI, P, I, E) with_I(E, I)(const I i) if (isNumer!(P, E, I)) {
    return Param!(PI, P, I, E)(p, i);
  }

  /**
     Convert to PI parameters by adding integral factor in time units

     Params:
     dt = Sampling (or control step) period
     E = Integral error type
     I = Integral time type
     i = Integral time
  */
  const pure nothrow @nogc @safe
  Param!(PI, P, typeof(I() * asnum!(dt, I)), E) with_I(real dt, E, I)(const I i) if (isNumer!(P, I, E)) {
    return with_I!E(i * asnum!(dt, I));
  }

  /**
     Convert to PD parameters by adding derivative factor

     Params:
     D = Derivative factor type
     d = Derivative factor
  */
  const pure nothrow @nogc @safe
  Param!(PD, P, D) with_D(D)(const D d) if (isNumer!(P, D)) {
    return Param!(PD, P, D)(p, d);
  }

  /**
     Convert to PD parameters by adding derivative factor in time units

     Params:
     dt = Sampling (or control step) period
     D = Derivative time type
     d = Derivative time
  */
  const pure nothrow @nogc @safe
  Param!(PI, P, typeof(D() * asnum!(1.0 / dt, D))) with_D(real dt, D)(const D d) if (isNumer!(P, D)) {
    return with_D(d * asnum!(1.0 / dt, D));
  }
}

/// Test Proportional regulator parameters
nothrow @nogc unittest {
  auto po = Param!(PO, double)(0.36);
  assert(is(typeof(po) == Param!(PO, double)));
  assert_eq(po.p, 0.36);

  auto pi = po.with_I!double(0.16);
  assert(is(typeof(pi) == Param!(PI, double, double, double)));
  assert_eq(pi.p, 0.36);
  assert_eq(pi.i, 0.16);

  auto pd = po.with_D(0.46);
  assert(is(typeof(pd) == Param!(PD, double, double)));
  assert_eq(pd.p, 0.36);
  assert_eq(pd.d, 0.46);
}

/// Test Proportional regulator parameters (fixed-point)
nothrow @nogc unittest {
  alias P = fix!(-1, 1);
  alias I = fix!(0, 1);
  alias D = fix!(0, 1);
  alias E = fix!(-10, 10);

  auto po = mk!PO(P(0.36));
  assert(is(typeof(po) == Param!(PO, P)));
  assert_eq(po.p, I(0.36));

  auto pi = po.with_I!E(I(0.16));
  assert(is(typeof(pi) == Param!(PI, P, I, E)));
  assert_eq(pi.p, P(0.36));
  assert_eq(pi.i, I(0.16));

  auto pd = po.with_D(D(0.46));
  assert(is(typeof(pd) == Param!(PD, P, D)));
  assert_eq(pd.p, P(0.36));
  assert_eq(pd.d, D(0.46));
}

/// Create Proportional regulator parameters
Param!(PO, P) mk(alias C, P)(const P p = 0.0) if (isClass!(C, PO) && isNumer!P) {
  return Param!(PO, P)(p);
}

/// Test Proportional regulator parameters
nothrow @nogc unittest {
  static immutable auto po = mk!PO(0.36f);
  assert(is(typeof(po) == immutable Param!(PO, float)));
  assert_eq(po.p, 0.36f);

  enum auto dt = 0.1;

  static immutable auto pi = po.with_I!(dt, float)(12.0f);
  assert(is(typeof(pi) == immutable Param!(PI, float, float, float)));
  assert_eq(pi.p, 0.36f);
  assert_eq(pi.i, 1.2f);
}

/**
   Proportional Integral regulator parameters with integral error limiting

   This structure supports builder pattern, so you can construct it and call `.with_<property>(<value>)` functions in chain.
   By default all parameter fields is out because it has zero-size. This is important optimization, because it helps save memory.
   For example, in case of Proportional-Integral (PI) regulator we do not need derivative parameter, so we hide according field from parameters structure by applying `none` type to it.

   Params:
   C = Regulator class
   P_ = Proportional factor type
   I_ = Integral factor type
   E_ = Integral error type
*/
struct Param(C, P_, I_, E_) if (isClass!(C, PI) && isNumer!(P_, I_, E_)) {
  /// Regulator class
  alias Class = C;

  /// Proportional factor type
  alias P = P_;

  /// Integral factor type
  alias I = I_;

  /// Integral error type
  alias E = E_;

  /// Proportional factor
  P p;

  /// Integral factor
  I i;

  static if (C.limitedI) {
    /// Integral error limit
    E e;

    /// Create Proportional Integral regulator parameters
    this(const P p_, const I i_, const E e_) {
      p = p_;
      i = i_;
      e = e_;
    }
  } else {
    /// Create Proportional Integral regulator parameters
    this(const P p_, const I i_) {
      p = p_;
      i = i_;
    }

    /// Add abolute integral error limit
    const pure nothrow @nogc @safe
    Param!(LimitI!(PI), P, I, E) with_I_limit(const E e) {
      return Param!(LimitI!(PI), P, I, E)(p, i, e);
    }
  }

  /**
     Set integral factor in time units

     Params:
     dt = Sampling (or control step) period
     i_ = Integral time
  */
  pure nothrow @nogc @safe
  void set_I(real dt)(const typeof(I() * asnum!(1.0 / dt, I)) i_) {
    i = cast(I) (i_ * asmum!(dt, I));
  }

  /**
     Convert to PID parameters by adding derivative factor

     Params:
     D = Derivative factor type
     d = Derivative factor
  */
  const pure nothrow @nogc @safe
  Param!(PID, P, I, D, E) with_D(D)(const D d) if (isNumer!(P, I, D, E)) {
    return Param!(PID, P, I, D, E)(p, i, d);
  }

  /**
     Convert to PID parameters by adding derivative factor in time units

     Params:
     dt = Sampling (or control step) period
     D = Derivative time type
     d = Derivative time
  */
  const pure nothrow @nogc @safe
  Param!(PID, P, I, typeof(D() * asnum!(1.0 / dt, D)), E) with_D(real dt, D)(const D d) if (isNumer!(P, I, D, E)) {
    return with_D(d * asnum!(1.0 / dt, D));
  }
}

/// Test Proportional Integral regulator parameters
nothrow @nogc unittest {
  auto pi = Param!(PI, double, double, double)(0.28, 0.18);
  assert(is(typeof(pi) == Param!(PI, double, double, double)));
  assert_eq(pi.p, 0.28);
  assert_eq(pi.i, 0.18);

  auto pid = pi.with_D(0.38);
  assert(is(typeof(pid) == Param!(PID, double, double, double, double)));
  assert_eq(pid.p, 0.28);
  assert_eq(pid.i, 0.18);
  assert_eq(pid.d, 0.38);

  enum auto dt = 0.125;

  auto pid2 = pi.with_D!dt(0.25);
  assert(is(typeof(pid2) == Param!(PID, double, double, double, double)));
  assert_eq(pid2.d, 2.0);

  pid2.set_D!dt(0.5);
  assert_eq(pid2.d, 4.0);
}

/// Test Proportional Integral regulator parameters (fixed-point)
nothrow @nogc unittest {
  alias P = fix!(-1, 1);
  alias I = fix!(0, 1);
  alias D = fix!(0, 1);
  alias E = fix!(-10, 10);

  auto pi = mk!(PI, E)(P(0.28), I(0.18));
  assert(is(typeof(pi) == Param!(PI, P, I, E)));
  assert_eq(pi.p, P(0.28));
  assert_eq(pi.i, I(0.18));

  auto pid = pi.with_D(D(0.38));
  assert(is(typeof(pid) == Param!(PID, P, I, D, E)));
  assert_eq(pid.p, P(0.28));
  assert_eq(pid.i, I(0.18));
  assert_eq(pid.d, D(0.38));

  enum auto dt = 0.125;
  alias D_ = fix!(0, 0.125);

  auto pid2 = pi.with_D!dt(D_(0.0625));
  assert(is(typeof(pid2) == Param!(PID, P, I, D, E)));
  assert_eq(pid2.d, D(0.5));

  pid2.set_D!dt(D_(0.03125));
  assert_eq(pid2.d, D(0.25));
}

/// Create Proportional Integral regulator parameters
Param!(PI, P, I, E) mk(alias C, E, P, I)(const P p = 0.0, const I i = 0.0) if (isClass!(C, PI) && isNumer!(P, I, E) && !C.limitedI) {
  return Param!(PI, P, I, E)(p, i);
}

/// Create Proportional Integral regulator parameters with error limit
Param!(PI, P, I, E) mk(alias C, E, P, I)(const P p = 0.0, const I i = 0.0, const E e = 0.0) if (isClass!(C, PI) && isNumer!(P, I, E) && C.limitedI) {
  return Param!(PI, P, I, E)(p, i, e);
}

/// Test Proportional Integral regulator parameters
nothrow @nogc unittest {
  auto pi = mk!(PI, double)(0.28, 0.18);
  assert(is(typeof(pi) == Param!(PI, double, double, double)));
  assert_eq(pi.p, 0.28);
  assert_eq(pi.i, 0.18);
}

/**
   Proportional Derivative regulator parameters

   This structure supports builder pattern, so you can construct it and call `.with_<property>(<value>)` functions in chain.
   By default all parameter fields is out because it has zero-size. This is important optimization, because it helps save memory.
   For example, in case of Proportional-Integral (PI) regulator we do not need derivative parameter,
   so we hide according field from parameters structure by applying `none` type to it.
*/
struct Param(C, P_, D_) if (isClass!(C, PD) && isNumer!(P_, D_)) {
  /// Regulator class
  alias Class = C;

  /// Proportional factor type
  alias P = P_;

  /// Derivative factor type
  alias D = D_;

  /// Proportional factor
  P p;

  /// Derivative factor
  D d;

  /// Create Proportional Derivative regulator parameters
  this(const P p_, const D d_) {
    p = p_;
    d = d_;
  }

  /**
     Set derivative factor in time units

     Params:
     dt = Sampling (or control step) period
     d_ = Derivative time
  */
  pure nothrow @nogc @safe
  void set_D(real dt)(const typeof(D() * asnum!(dt, D)) d_) {
    d = cast(D) (d_ * asnum!(1.0 / dt, D));
  }

  /**
     Convert to PID parameters by adding integral factor

     Params:
     E = Integral error type
     I = Integral factor type
     i = Integral factor
  */
  const pure nothrow @nogc @safe
  Param!(PID, P, I, D, E) with_I(E, I)(const I i) if (isNumer!(P, I, D, E)) {
    return Param!(PID, P, I, D, E)(p, i, d);
  }

  /**
     Convert to PID parameters by adding integral factor in time units

     Params:
     dt = Sampling (or control step) period
     E = Integral error type
     I = Integral factor type
     i = Integral time
  */
  const pure nothrow @nogc @safe
  Param!(PID, P, typeof(I() * asnum!(dt, I)), D, E) with_I(real dt, E, I)(const I i) if (isNumer!(P, I, D, E)) {
    return with_I!E(i * asnum!(dt, I));
  }
}

/// Test Proportional Derivative regulator parameters
nothrow @nogc unittest {
  auto pd = Param!(PD, double, double)(0.24, 0.42);
  assert(is(typeof(pd) == Param!(PD, double, double)));
  assert_eq(pd.p, 0.24);
  assert_eq(pd.d, 0.42);

  auto pid = pd.with_I!double(0.14);
  assert(is(typeof(pid) == Param!(PID, double, double, double, double)));
  assert_eq(pid.p, 0.24);
  assert_eq(pid.i, 0.14);
  assert_eq(pid.d, 0.42);

  enum auto dt = 0.125;

  auto pid2 = pd.with_I!(dt, double)(0.5);
  assert(is(typeof(pid2) == Param!(PID, double, double, double, double)));
  assert_eq(pid2.i, 0.0625);

  pid2.set_I!dt(0.25);
  assert_eq(pid2.i, 0.03125);
}

/// Test Proportional Derivative regulator parameters (fixed-point)
nothrow @nogc unittest {
  alias P = fix!(-1, 1);
  alias I = fix!(0, 1);
  alias D = fix!(0, 1);
  alias E = fix!(-10, 10);

  auto pd = mk!PD(P(0.24), D(0.42));
  assert(is(typeof(pd) == Param!(PD, P, D)));
  assert_eq(pd.p, P(0.24));
  assert_eq(pd.d, D(0.42));

  auto pid = pd.with_I!E(I(0.14));
  assert(is(typeof(pid) == Param!(PID, P, I, D, E)));
  assert_eq(pid.p, P(0.24));
  assert_eq(pid.i, I(0.14));
  assert_eq(pid.d, D(0.42));

  enum auto dt = 0.125;
  alias I_ = fix!(0.0, 8.0);

  auto pid2 = pd.with_I!(dt, E)(I_(0.5));
  assert(is(typeof(pid2) == Param!(PID, P, I, D, E)));
  assert_eq(pid2.i, I(0.0625));

  pid2.set_I!dt(I_(0.25));
  assert_eq(pid2.i, I(0.03125));
}

/// Create Proportional Derivative regulator parameters
Param!(PD, P, D) mk(alias C, P, D)(const P p = 0.0, const D d = 0.0) if (isClass!(C, PD) && isNumer!(P, D)) {
  return Param!(PD, P, D)(p, d);
}

/// Test Proportional Derivative regulator parameters
nothrow @nogc unittest {
  auto pd = mk!PD(0.24, 0.42);
  assert(is(typeof(pd) == Param!(PD, double, double)));
  assert_eq(pd.p, 0.24);
  assert_eq(pd.d, 0.42);
}

/**
   Proportional Integral Derivative regulator parameters with integral error limiting
*/
struct Param(C, P_, I_, D_, E_) if (isClass!(C, PID) && isNumer!(P_, I_, D_, E_)) {
  /// Regulator class
  alias Class = C;

  /// Proportional factor type
  alias P = P_;

  /// Integral factor type
  alias I = I_;

  /// Derivative factor type
  alias D = D_;

  /// Integral error type
  alias E = E_;

  /// Proportional factor
  P p;

  /// Integral factor
  I i;

  /// Derivative factor
  D d;

  static if (C.limitedI) {
    /// Integral error limit
    E e;

    /// Create Proportional Integral Derivative regulator parameters
    this(const P p_, const I i_, const D d_, const E e_) {
      p = p_;
      i = i_;
      d = d_;
      e = e_;
    }
  } else {
    /// Create Proportional Integral Derivative regulator parameters
    this(const P p_, const I i_, const D d_) {
      p = p_;
      i = i_;
      d = d_;
    }

    /// Add abolute integral error limit
    const pure nothrow @nogc @safe
    Param!(LimitI!(PID), P, I, D, E) with_I_limit(const E e) {
      return Param!(LimitI!(PID), P, I, D, E)(p, i, d, e);
    }
  }

  /**
     Set integral factor in time units

     Params:
     dt = Sampling (or control step) period
     i_ = Integral time
  */
  pure nothrow @nogc @safe
  void set_I(real dt)(const typeof(I() * asnum!(1.0 / dt, I)) i_) {
    i = cast(I) (i_ * asnum!(dt, I));
  }

  /**
     Set derivative factor in time units

     Params:
     dt = Sampling (or control step) period
     d_ = Derivative time
  */
  pure nothrow @nogc @safe
  void set_D(real dt)(const typeof(D() * asnum!(dt, D)) d_) {
    d = cast(D) (d_ * asnum!(1.0 / dt, D));
  }
}

/// Test Proportional Integral Derivative regulator parameters
nothrow @nogc unittest {
  auto pid = Param!(PID, double, double, double, double)(0.15, 0.25, 0.11);
  assert(is(typeof(pid) == Param!(PID, double, double, double, double)));
  assert_eq(pid.p, 0.15);
  assert_eq(pid.i, 0.25);
  assert_eq(pid.d, 0.11);

  enum auto dt = 0.125;

  pid.set_I!dt(0.5);
  assert_eq(pid.i, 0.0625);

  pid.set_D!dt(0.25);
  assert_eq(pid.d, 2.0);
}

/// Create Proportional Integral Derivative regulator parameters
Param!(PID, P, I, D, E) mk(alias C, E, P, I, D)(const P p = 0.0, const I i = 0.0, const D d = 0.0) if (isClass!(C, PID) && isNumer!(P, I, D, E) && !C.limitedI) {
  return Param!(PID, I, P, D, E)(p, i, d);
}

/// Create Proportional Integral Derivative regulator parameters with Integral error limit
Param!(PID, P, I, D, E) mk(alias C, E, P, I, D)(const P p = 0.0, const I i = 0.0, const D d = 0.0, const E e = 0.0) if (isClass!(C, PID) && isNumer!(P, I, D, E) && C.limitedI) {
  return Param!(PID, I, P, D, E)(p, i, d, e);
}

/// Test Proportional Integral Derivative regulator parameters
nothrow @nogc unittest {
  auto pid = mk!(PID, double)(0.15, 0.25, 0.11);
  assert(is(typeof(pid) == Param!(PID, double, double, double, double)));
  assert_eq(pid.p, 0.15);
  assert_eq(pid.i, 0.25);
  assert_eq(pid.d, 0.11);
}

/// The state of regulator
struct State(alias P_, E_) if (isParam!P_ && isNumer!(P_.P, E_)) {
  static if (is(P_)) {
    /// Parameters type
    alias P = P_;
  } else {
    /// Parameters type
    alias P = typeof(P_);
  }

  /// Class of regulator
  alias C = P.Class;

  /// Error value type
  alias E = E_;

  static if (C.hasD) { // Has derivative term
    /// Last error value
    E e = 0.0;
  }

  static if (C.hasI) { // Has integral term
    /// Integral error value
    P.E e_i = 0.0;
  }

  /**
     Apply regulator

     Evaluate regulation step

     Params:
     param = Parameters
     error = Error value

     Error value is a difference between setpoint and measured value or vice-versa depending from regulator design.

     Depending from parameters type this function implements corresponding control mechanism:
     $(LIST
     * Proportional (PO)
     * Proportional-Integral (PI)
     * Proportional-Derivative (PD)
     * Proportional-Integral-Derivative (PID)
     )

     Proportional factor can be applied to error value only in case when proportional term is decoupled or to entire regulator output in case when it is coupled (of course, for proportional-only controller without integral and derivative terms this is not matter).

     Integral error can be optionally limited by some absolute value.

     See_Also: [CoupleP], [LimitI].
   */
  pure nothrow @nogc @safe
  auto apply(const ref P param, const E error) {
    static if (C.hasI) { // Has integral term
      // Update integral error
      e_i += error;

      static if (C.limitedI) {
        if (e_i > param.e) {
          e_i = param.e;
        }
      }
    }

    static if (C.hasD) { // Has derivative term
      // Calculate derivative error
      auto e_d = error - e;

      // Update error value
      e = error;
    }

    static if (C.coupledP) { // Coupled proportional term
      static if (C.hasI && C.hasD) { // Proportional Integral Derivative
        return (error + e_i * param.i + e_d * param.d) * param.p;
      } else static if (C.hasD) { // Proportional Derivative
        return (error + e_d * param.d) * param.p;
      } else static if (C.hasI) { // Proportional Integral
        return (error + e_i * param.i) * param.p;
      } else { // Proportional-only
        return error * param.p;
      }
    } else { // Decoupled proportional term
      static if (C.hasI && C.hasD) { // Proportional Integral Derivative
        return error * param.p + e_i * param.i + e_d * param.d;
      } else static if (C.hasD) { // Proportional Derivative
        return error * param.p + e_d * param.d;
      } else static if (C.hasI) { // Proportional Integral
        return error * param.p + e_i * param.i;
      } else { // Proportional-only
        return error * param.p;
      }
    }
  }
}

/// Test Proportional regulator
nothrow @nogc unittest {
  static immutable auto p = mk!PO(0.125);
  static auto s = State!(p, double)();

  assert_eq(s.apply(p, 1.0), 0.125);
  assert_eq(s.apply(p, 1.0), 0.125);
  assert_eq(s.apply(p, 0.5), 0.0625);
  assert_eq(s.apply(p, -0.5), -0.0625);
}

/// Test Proportional regulator (fixed-point)
nothrow @nogc unittest {
  alias P = fix!(0, 1);
  alias T = fix!(-10, 10);
  alias R = fix!(-10, 10);

  static immutable auto p = mk!PO(P(0.125));
  static auto s = State!(p, T)();

  assert_eq(s.apply(p, T(1.0)), R(0.125));
  assert_eq(s.apply(p, T(1.0)), R(0.125));
  assert_eq(s.apply(p, T(0.5)), R(0.0625));
  assert_eq(s.apply(p, T(-0.5)), R(-0.0625));
}

/// Test Proportional Integral regulator
nothrow @nogc unittest {
  static immutable auto p = mk!(PI, double)(0.125, 0.03125);
  static auto s = State!(typeof(p), double)();

  assert_eq(s.apply(p, 1.0), 0.15625);
  assert_eq(s.apply(p, 1.0), 0.1875);
  assert_eq(s.apply(p, 0.5), 0.140625);
  assert_eq(s.apply(p, -0.5), 0.0);
}

/// Test Proportional Integral regulator (fixed-point)
nothrow @nogc unittest {
  alias P = fix!(0, 1);
  alias I = fix!(0, 0.5);
  alias E = fix!(-10, 10);
  alias T = fix!(-10, 10);
  alias R = fix!(-15, 15);

  static immutable auto p = mk!(PI, E)(P(0.125), I(0.03125));
  static auto s = State!(typeof(p), T)();

  assert_eq(s.apply(p, T(1.0)), R(0.15625));
  assert_eq(s.apply(p, T(1.0)), R(0.1875));
  assert_eq(s.apply(p, T(0.5)), R(0.140625));
  assert_eq(s.apply(p, T(-0.5)), R(0.0));
}

/// Test Proportional Derivative regulator
nothrow @nogc unittest {
  static immutable auto p = mk!PD(0.125, 0.5);
  static auto s = State!(typeof(p), double)();

  assert_eq(s.apply(p, 1.0), 0.625);
  assert_eq(s.apply(p, 1.0), 0.125);
  assert_eq(s.apply(p, 0.5), -0.1875);
  assert_eq(s.apply(p, -0.5), -0.5625);
}

/// Test Proportional Derivative regulator (fixed-point)
nothrow @nogc unittest {
  alias P = fix!(0, 1);
  alias D = fix!(0, 1);
  alias T = fix!(-10, 10);
  alias R = fix!(-30, 30);

  static immutable auto p = mk!PD(P(0.125), D(0.5));
  static auto s = State!(typeof(p), T)();

  assert_eq(s.apply(p, T(1.0)), R(0.625));
  assert_eq(s.apply(p, T(1.0)), R(0.125));
  assert_eq(s.apply(p, T(0.5)), R(-0.1875));
  assert_eq(s.apply(p, T(-0.5)), R(-0.5625));
}

/// Test Proportional Integral Derivative regulator
nothrow @nogc unittest {
  static immutable auto p = mk!(PID, double)(0.125, 0.5, 0.03125);
  static auto s = State!(typeof(p), double)();

  assert_eq(s.apply(p, 1.0), 0.65625);
  assert_eq(s.apply(p, 1.0), 1.125);
  assert_eq(s.apply(p, 0.5), 1.296875);
  assert_eq(s.apply(p, -0.5), 0.90625);
}

/// Test Proportional Integral regulator (fixed-point)
nothrow @nogc unittest {
  alias P = fix!(0, 1);
  alias I = fix!(0, 0.5);
  alias D = fix!(0, 1);
  alias E = fix!(-10, 10);
  alias T = fix!(-10, 10);
  alias R = fix!(-30, 30);

  static immutable auto p = mk!(PID, E)(P(0.125), D(0.5), I(0.03125));
  static auto s = State!(typeof(p), T)();

  assert_eq(s.apply(p, T(1.0)), R(0.65625));
  assert_eq(s.apply(p, T(1.0)), R(1.125));
  assert_eq(s.apply(p, T(0.5)), R(1.296875));
  assert_eq(s.apply(p, T(-0.5)), R(0.90625));
}
