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

import std.traits: isInstanceOf, Unqual;
import uctl.unit: isTiming, asTiming, sec, hasUnits, as, to, rawTypeOf, rawof, Resistance, Ohm, Inductance, H, MagneticFlux, Wb, InertiaMoment, Kgm2, Torque, Nm, AngularVel, rad_sec, Voltage, V, Current, A;
import uctl.num: isNumer, asnum, typeOf;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.unit: usec, mOhm, uH, mWb, gcm2, mNm;
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
struct Param(alias s_, R_, L_, F_, J_) if (isTiming!s_ &&
                                           hasUnits!(R_, Resistance) &&
                                           hasUnits!(L_, Inductance) &&
                                           hasUnits!(F_, MagneticFlux) &&
                                           hasUnits!(J_, InertiaMoment) &&
                                           isNumer!(rawTypeOf!R_, rawTypeOf!L_,
                                                    rawTypeOf!F_, rawTypeOf!J_)) {
  alias R = Unqual!R_;
  alias L = Unqual!L_;
  alias F = Unqual!F_;
  alias J = Unqual!J_;

  alias R_Ohm = typeof(R().to!Ohm.raw);
  alias L_H = typeof(L().to!H.raw);
  alias F_Wb = typeof(F().to!Wb.raw);
  alias J_Kgm2 = typeof(J().to!Kgm2.raw);

  /// Sampling time
  enum dt_sec = asTiming!(s_, sec, R_Ohm).raw;

  alias Dt_sec_L_H = typeof(dt_sec / L_H());
  alias Dt_sec_J_Kgm2 = typeof(dt_sec / J_Kgm2());

  /// Rotor resistance, $(I Ohm)
  R_Ohm rotor_R_Ohm;
  /// dt/Lr, $(I S/H)
  Dt_sec_L_H dt_rotor_L_H;
  /// Stator flux, $(I Wb)
  F_Wb stator_F_Wb;
  /// d/Jr, $(I S/(Kg⋅m$(SUPERSCRIPT 2)))
  Dt_sec_J_Kgm2 dt_rotor_J_Kgm2;

  /**
     Initialize motor parameters

     Params:
     rotor_R = Rotor resistance, $(I Ohm)
     rotor_L = Rotor inductance, $(I H)
     stator_F = Stator flux, $(I Wb)
     rotor_J = Rotor inertia, $(I Kg⋅m$(SUPERSCRIPT 2))
  */
  const pure nothrow @nogc @safe
  this(const R rotor_R, const L rotor_L, const F stator_F, const J rotor_J) {
    rotor_R_Ohm = rotor_R.to!Ohm.raw;
    dt_rotor_L_H = dt_sec / rotor_L.to!H.raw;
    stator_F_Wb = stator_F.to!Wb.raw;
    dt_rotor_J_Kgm2 = dt_sec / rotor_J.to!Kgm2.raw;
  }
}

/**
   Create motor parameters

   Params:
   s = Sampling time or frequency
   R = Rotor resistance type
   L = Rotor inductance type
   F = Stator flux type
   J = Rotor inertia type
   rotor_R = Rotor resistance
   rotor_L = Rotor inductance
   stator_F = Stator flux
   rotor_J = Rotor inertia
*/
pure nothrow @nogc @safe Param!(s, R, L, F, J)
mk(alias P, alias s, R, L, F, J)(R rotor_R, L rotor_L, F stator_F, J rotor_J)
if (__traits(isSame, Param, P) && isTiming!s &&
    hasUnits!(R, Resistance) &&
    hasUnits!(L, Inductance) &&
    hasUnits!(F, MagneticFlux) &&
    hasUnits!(J, InertiaMoment) &&
    isNumer!(rawTypeOf!R, rawTypeOf!L,
             rawTypeOf!F, rawTypeOf!J)) {
  return Param!(s, R, L, F, J)(rotor_R, rotor_L, stator_F, rotor_J);
}

/// Test motor parameters (floating-point)
nothrow @nogc unittest {
  enum dt = 100f.as!usec;

  static immutable param = mk!(Param, dt)(124f.as!mOhm, 42f.as!uH, 8.5f.as!mWb, 87.1f.as!gcm2);

  assert_eq(param.rotor_R_Ohm, 124e-3f);
  assert_eq(param.dt_rotor_L_H, 2.38095238f);
  assert_eq(param.stator_F_Wb, 8.5e-3f);
  assert_eq(param.dt_rotor_J_Kgm2, 11.481056f);
}

/// Test motor parameters (fixed-point)
nothrow @nogc unittest {
  enum dt = 100f.as!usec;

  static immutable param = mk!(Param, dt)(asfix!124.as!mOhm, asfix!42.as!uH, asfix!8.5.as!mWb, asfix!87.1.as!gcm2);

  assert_eq(param.rotor_R_Ohm, asfix!124e-3);
  assert_eq(param.dt_rotor_L_H, asfix!2.380952381);
  assert_eq(param.stator_F_Wb, asfix!8.5e-3);
  assert_eq(param.dt_rotor_J_Kgm2, asfix!11.48105626);
}

/// Test motor parameters (fixed-point)
nothrow @nogc unittest {
  alias R = fix!(0, 200);
  alias L = fix!(1e-3, 100);
  alias F = fix!(0, 20);
  alias J = fix!(1e-3, 200);

  enum dt = 100f.as!usec;

  static immutable param = mk!(Param, dt)(124f.as!mOhm.to!R, 42f.as!uH.to!L, 8.5f.as!mWb.to!F, 87.1f.as!gcm2.to!J);

  assert_eq(param.rotor_R_Ohm, param.R_Ohm(124e-3));
  assert_eq(param.dt_rotor_L_H, param.Dt_sec_L_H(2.38092041));
  assert_eq(param.stator_F_Wb, param.F_Wb(8.5e-3));
  assert_eq(param.dt_rotor_J_Kgm2, param.Dt_sec_J_Kgm2(11.48101807));
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
struct State(alias P_, U_, W_) if (isParam!P_ &&
                                   hasUnits!(U_, Voltage) &&
                                   hasUnits!(W_, AngularVel) &&
                                   isNumer!(P_.R_Ohm, rawTypeOf!U_, rawTypeOf!W_)) {
  alias P = typeOf!P_;

  alias U = Unqual!U_;
  alias W = Unqual!W_;

  alias U_V = Unqual!(typeof(U().to!V.raw));
  alias W_rad_sec = Unqual!(typeof(W().to!rad_sec.raw));

  alias I_A = typeof(U_V() / P.R_Ohm());
  alias T_Nm = typeof(I_A() * P.F_Wb());
  alias E_V = typeof(W_rad_sec() * P.F_Wb());

  alias I = typeof(I_A().as!A);
  alias T = typeof(T_Nm().as!Nm);
  alias E = typeof(E_V().as!V);

  /// Rotor current, $(I A)
  I_A rotor_I_A = 0.0;
  /// Electro-magnetic torque, $(I Kg⋅m$(SUPERSCRIPT 2))
  T_Nm rotor_T_Nm = 0.0;
  /// Back EMF, $(I V)
  E_V back_E_V = 0.0;
  /// Rotor speed, $(I rad/S)
  W_rad_sec rotor_W_rad_sec = 0.0;

  /// Get rotor current
  pure nothrow @nogc @safe
  auto rotor_I() const {
    return rotor_I_A.as!A;
  }

  /// Get rotor torque
  pure nothrow @nogc @safe
  auto rotor_T() const {
    return rotor_T_Nm.as!Nm;
  }

  /// Get back EMF
  pure nothrow @nogc @safe
  auto back_E() const {
    return back_E_V.as!V;
  }

  /// Get rotor speed
  pure nothrow @nogc @safe
  auto rotor_W() const {
    return rotor_W_rad_sec.as!rad_sec;
  }

  /**
     Initialize state
  */
  pure nothrow @nogc @safe
  this(const I rotor_I, const T rotor_T, const E back_E, const W rotor_W) const {
    rotor_I_A = rotor_I.to!A.raw;
    rotor_T_Nm = rotor_T.to!Nm.raw;
    back_E_V = back_E.to!V.raw;
    rotor_W_rad_sec = rotor_W.to!rad_sec.raw;
  }

  /**
     Apply simulation step
  */
  pure nothrow @nogc @safe
  W opCall(Us, Tl)(ref const P param, const Us supply_U, const Tl load_T)
  if (hasUnits!(Us, Voltage) && hasUnits!(Tl, Torque) &&
      isNumer!(U_V, rawTypeOf!Us, rawTypeOf!Tl)) {
    const supply_U_V = supply_U.to!V.raw;
    const load_T_Nm = load_T.to!Nm.raw;

    rotor_I_A += (supply_U_V - back_E_V - param.rotor_R_Ohm * rotor_I_A) * param.dt_rotor_L_H;
    rotor_T_Nm = rotor_I_A * param.stator_F_Wb;
    rotor_W_rad_sec += (rotor_T_Nm - load_T_Nm) * param.dt_rotor_J_Kgm2; // [N m S Kg^-1 m^-2] => [Kg S^-2 m^2 S Kg^-1 m^-2] => [S^-1]
    if (rotor_W_rad_sec < cast(W_rad_sec) 0.0) {
      rotor_W_rad_sec = cast(W_rad_sec) 0.0;
    }
    back_E_V = rotor_W_rad_sec * param.stator_F_Wb;
    return rotor_W_rad_sec.as!rad_sec.to!(W.units);
  }
}

/// Test motor state (floating-point)
nothrow @nogc unittest {
  alias U = typeof(0f.as!V);
  alias W = typeof(0f.as!rad_sec);

  enum dt = 100f.as!usec;

  static immutable param = mk!(Param, dt)(124f.as!mOhm, 42f.as!uH, 8.5f.as!mWb, 87.1f.as!gcm2);
  static state = State!(param, U, W)();

  assert_eq(state(param, 0.0.as!V, 12.4.as!mNm), 0.0.as!rad_sec);
  assert_eq(state(param, 13.56.as!V, 12.4.as!mNm), 3.008364737.as!rad_sec, 1e-6);
  assert_eq(state(param, 13.56.as!V, 12.4.as!mNm), 8.231302261.as!rad_sec, 1e-6);
  assert_eq(state(param, 13.56.as!V, 13.6.as!mNm), 14.99089372.as!rad_sec, 1e-5);
  assert_eq(state(param, 12.0.as!V, 13.6.as!mNm), 22.46734637.as!rad_sec, 1e-5);
}

/// Test motor state (fixed-point)
nothrow @nogc unittest {
  alias U = typeof(fix!(0, 20)().as!V);
  alias W = typeof(fix!(0, 100)().as!rad_sec);
  alias T = typeof(fix!(0, 20)().as!mNm);

  enum dt = 100f.as!usec;

  static immutable param = mk!(Param, dt)(asfix!124.as!mOhm, asfix!42.as!uH, asfix!8.5.as!mWb, asfix!87.1.as!gcm2);
  static state = State!(param, U, W)();

  assert_eq(state(param, 0.0.as!V.to!U, 12.4.as!mNm.to!T), 0.0.as!rad_sec.to!W);
  assert_eq(state(param, 13.56.as!V.to!U, 12.4.as!mNm.to!T), 3.008364737.as!rad_sec.to!W);
  assert_eq(state(param, 13.56.as!V.to!U, 12.4.as!mNm.to!T), 8.231302261.as!rad_sec.to!W);
  assert_eq(state(param, 13.56.as!V.to!U, 13.6.as!mNm.to!T), 14.99089372.as!rad_sec.to!W);
  assert_eq(state(param, 12.0.as!V.to!U, 13.6.as!mNm.to!T), 22.46734637.as!rad_sec.to!W);
}
