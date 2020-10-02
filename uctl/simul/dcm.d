/**
   ## DC motor model

   Simple model of brush direct current motor.

   Model input:
   $(LIST
   * $(MATH U_r) - supply voltage, $(I V)
   * $(MATH T_l) - load torque, $(I N⋅m)
   )

   Model output:
   $(LIST
   * $(MATH \omega_r) - rotor speed, $(I rad/S)
   )

   Model parameters:
   $(LIST
   * $(MATH R_r) - rotor resistance, $(I Ohm)
   * $(MATH L_r) - rotor inductance, $(I H)
   * $(MATH \Psi_s) - stator magnetic flux, $(I Wb)
   * $(MATH J_r) - rotor inertia, $(I Kg⋅m$(SUPERSCRIPT 2))
   )

   Model state:
   $(LIST
   * $(MATH i_r) - rotor current, $(I A)
   * $(MATH T_e) - electric torque, $(I N⋅m)
   * $(MATH \omega_r) - rotor speed, $(I rad/S)
   * $(MATH E_b) - back EMF, $(I V)
   )

   Basic model equations:

   $(MATH U_r - E_b = R_r i_r + L_r \frac{d i_r}{d t}) (1)

   $(MATH T_e - T_l = J_r \frac{d \omega_r}{d t} ) (2)

   $(MATH T_e = \Psi_s i_r) (3)

   $(MATH E_b = \Psi_s \omega_r) (4)

   where:
   $(LIST
   * $(MATH U_r) - rotor voltage, $(I V)
   * $(MATH E_b) - back EMF, $(I V)
   * $(MATH R_r) - full active resistance of rotor including brushes, $(I Ohm)
   * $(MATH L_r) - rotor coil inductance, $(I H)
   * $(MATH i_r) - rotor current, $(I A)
   * $(MATH T_e) - electrical torque of rotor, $(I N⋅m)
   * $(MATH T_l) - load torque at shaft, $(I N⋅m)
   * $(MATH J_r) - inertia of rotor, $(I Kg⋅m$(SUPERSCRIPT 2))
   * $(MATH \Psi_s) - nominal magnet flux of stator, $(I Wb)
   * $(MATH t) - time, $(I S)
   )

   Motor identification:

   $(MATH \Psi_s = \frac{U_r - R_r i_r}{\omega_r})

   ![Simulation example](sim_dcm.svg)
 */
module uctl.simul.dcm;

import std.traits: isInstanceOf;
import uctl.num: isNumer, asnum;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.num: fix, asfix;

  mixin unittests;
}

/**
   Motor parameters

   Params:
   dt_ = Sampling time
   R_ = Rotor resistance type
   L_ = Rotor inductance type
   F_ = Stator flux type
   J_ = Rotor inertia type

   $(TABLE_ROWS
   Example motor parameters
   * + Model
     + Rr, $(I mOhm)
     + Lr, $(I uH)
     + Fs, $(I mWb)
     + Jr, $(I mg⋅m$(SUPERSCRIPT 2))
   * - BaneBots RS-775 18V DC brush motor
     - 124
     - 42 (50?)
     - 8.5
     - 8.7
   )
*/
struct Param(real dt_, R_, L_, F_, J_) if (isNumer!(R_, L_, F_, J_)) {
  alias R = R_;
  alias L = L_;
  alias F = F_;
  alias J = J_;

  /// Sampling time
  enum rdt = dt_;
  /// Sampling time
  enum dt = asnum!(dt_, R);

  alias DtInvL = typeof(dt / L());
  alias DtInvJ = typeof(dt / J());

  /// Rotor resistance, $(I Ohm)
  R Rr;
  /// dt/Lr, $(I S/H)
  DtInvL dt_inv_Lr;
  /// Stator flux, $(I Wb)
  F Fs;
  /// d/Jr, $(I S/(Kg⋅m$(SUPERSCRIPT 2)))
  DtInvJ dt_inv_Jr;

  /**
     Initialize motor parameters

     Params:
     Rr_ = Rotor resistance, $(I Ohm)
     Lr_ = Rotor inductance, $(I H)
     Fs_ = Stator flux, $(I Wb)
     Jr_ = Rotor inertia, $(I Kg⋅m$(SUPERSCRIPT 2))
  */
  const pure nothrow @nogc @safe
  this(const R Rr_, const L Lr_, const F Fs_, const J Jr_) {
    Rr = Rr_;
    dt_inv_Lr = dt / Lr_;
    Fs = Fs_;
    dt_inv_Jr = dt / Jr_;
  }
}

/**
   Create motor parameters

   Params:
   dt = Sampling time
   R = Rotor resistance type
   L = Rotor inductance type
   F = Stator flux type
   J = Rotor inertia type
   Rr = Rotor resistance
   Lr = Rotor inductance
   Fs = Stator flux
   Jr = Rotor inertia
*/
pure nothrow @nogc @safe Param!(dt, R, L, F, J)
mk(alias P, real dt, R, L, F, J)(R Rr, L Lr, F Fs, J Jr) if (__traits(isSame, Param, P) && isNumer!(R, L, F, J)) {
  return Param!(dt, R, L, F, J)(Rr, Lr, Fs, Jr);
}

/// Test motor parameters (floating-point)
nothrow @nogc unittest {
  enum auto dt = 0.0001;

  static immutable auto param = mk!(Param, dt)(124e-3f, 42e-6f, 8.5e-3f, 8.71e-6f);
  assert(is(typeof(param) == immutable Param!(dt, float, float, float, float)));

  assert_eq(param.Rr, 124e-3f);
  assert_eq(param.dt_inv_Lr, 2.38095238f);
  assert_eq(param.Fs, 8.5e-3f);
  assert_eq(param.dt_inv_Jr, 11.481056f);
}

/// Test motor parameters (fixed-point)
nothrow @nogc unittest {
  enum auto dt = 0.0001;

  static immutable auto param = mk!(Param, dt)(asfix!124e-3, asfix!42e-6, asfix!8.5e-3, asfix!8.71e-6);
  //assert(is(typeof(param) == immutable Param!(dt, fix!124e-3, fix!(dt/42e-6), fix!8.5e-3, fix!(dt/8.71e-6))));

  assert_eq(param.Rr, asfix!124e-3);
  assert_eq(param.dt_inv_Lr, asfix!2.380952379);
  assert_eq(param.Fs, asfix!8.5e-3);
  assert_eq(param.dt_inv_Jr, asfix!11.48105624);
}

/// Test motor parameters (fixed-point)
nothrow @nogc unittest {
  alias R = fix!(0, 200e-3);
  alias L = fix!(1e-9, 100e-6);
  alias F = fix!(0, 20e-3);
  alias J = fix!(1e-9, 20e-6);

  enum auto dt = 0.0001;

  static immutable auto param = mk!(Param, dt)(R(124e-3), L(42e-6), F(8.5e-3), J(8.71e-6));
  assert(is(typeof(param) == immutable Param!(dt, R, L, F, J)));

  assert_eq(param.Rr, R(124e-3));
  assert_eq(param.dt_inv_Lr, param.DtInvL(2.38092041));
  assert_eq(param.Fs, F(8.5e-3));
  assert_eq(param.dt_inv_Jr, param.DtInvJ(11.48101807));
}

/// Check for parameters
template isParam(X...) if (X.length == 1) {
  static if (is(X[0])) {
    enum bool isParam = isInstanceOf!(Param, X[0]);
  } else {
    enum bool isParam = isParam!(typeof(X[0]));
  }
}

/**
   Motor state

   Params:
   P_ = Motor parameters type
   U_ = Rotor voltage type, $(I V)
   W_ = Rotor speed type, $(I rad/S)
*/
struct State(alias P_, U_, W_) if (isParam!P_ && isNumer!(P_.R, U_, W_)) {
  static if (is(P_)) {
    alias P = P_;
  } else {
    alias P = typeof(P_);
  }
  alias U = U_;
  alias W = W_;
  alias I = typeof(U() / P.R());
  alias T = typeof(I() * P.F());
  alias E = typeof(W() * P.F());

  /// Rotor current, $(I A)
  I Ir = 0.0;
  /// Electro-magnetic torque, $(I Kg⋅m$(SUPERSCRIPT 2))
  T Te = 0.0;
  /// Back EMF, $(I V)
  E Eb = 0.0;
  /// Rotor speed, $(I rad/S)
  W wr = 0.0;

  /**
     Initialize state
   */
  const pure nothrow @nogc @safe
  this(const I Ir_, const T Te_, const E Eb_, const W wr_) {
    Ir = Ir_;
    Te = Te_;
    Eb = Eb_;
    wr = wr_;
  }

  /**
     Apply simulation step
  */
  W opCall(ref const P param, const U Us, const T Tl) {
    Ir += (Us - Eb - param.Rr * Ir) * param.dt_inv_Lr;
    Te = Ir * param.Fs;
    wr += (Te - Tl) * param.dt_inv_Jr; // [N m S Kg^-1 m^-2] => [Kg S^-2 m^2 S Kg^-1 m^-2] => [S^-1]
    if (wr < cast(W) 0.0) {
      wr = cast(W) 0.0;
    }
    Eb = wr * param.Fs;
    return wr;
  }
}

/// Test motor state (floating-point)
nothrow @nogc unittest {
  enum auto dt = 0.0001;

  static immutable auto param = mk!(Param, dt)(124e-3f, 42e-6f, 8.5e-3f, 8.71e-6f);
  static auto state = State!(param, float, float)();

  assert_eq(state(param, 0.0, 124e-4), 0.0);
  assert_eq(state(param, 13.56, 124e-4), 3.008364737, 1e-6);
  assert_eq(state(param, 13.56, 124e-4), 8.231302261, 1e-6);
  assert_eq(state(param, 13.56, 13.6e-3), 14.99089372, 1e-5);
  assert_eq(state(param, 12.0, 13.6e-3), 22.46734637, 1e-5);
}

/// Test motor state (fixed-point)
nothrow @nogc unittest {
  alias U = fix!(0, 20);
  alias W = fix!(0, 100);

  enum auto dt = 0.0001;

  static immutable auto param = mk!(Param, dt)(asfix!124e-3, asfix!42e-6, asfix!8.5e-3, asfix!8.71e-6);
  static auto state = State!(param, U, W)();

  alias T = state.T;

  assert_eq(state(param, U(0.0), T(124e-3)), W(0.0));
  assert_eq(state(param, U(13.56), T(124e-4)), W(3.008364737));
  assert_eq(state(param, U(13.56), T(124e-4)), W(8.231302261));
  assert_eq(state(param, U(13.56), T(13.6e-3)), W(14.99089372));
  assert_eq(state(param, U(12.0), T(13.6e-3)), W(22.46734637));
}
