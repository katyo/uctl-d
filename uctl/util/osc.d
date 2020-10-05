/**
   ### Basic oscillator

   Generic implementation of basic oscillator.
 */
module uctl.util.osc;

import std.traits: isInstanceOf, Unqual;
import uctl.num: isNumer, asnum, typeOf;
import uctl.unit: Val, hasUnits, isUnits, isTiming, asTiming, rawTypeOf, Frequency, Time, Angle, Hz, sec, to, as, rev, qrev;
import uctl.math: pi;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.num: fix, asfix;
  import uctl.unit: msec;

  mixin unittests;
}

/**
   Oscillator parameters
*/
struct Param(A_, alias s_) if (hasUnits!(A_, Angle) &&
                               !is(s_) && isTiming!s_) {
  /// Sampling
  enum s = s_;

  /// Phase type
  alias A = Unqual!A_;

  /// Phase increment for single step
  A delta;

  /// Init param with specified phase increment
  const pure nothrow @nogc @safe
  this(const A delta_) {
    delta = delta_;
  }

  /// Set new oscillation frequency or period
  pure nothrow @nogc @safe
  void opAssign(T)(const T timing) if (isTiming!T &&
                                       isNumer!(rawTypeOf!A, rawTypeOf!T)) {
    delta = cast(A) timing_to_angle!(A.units, s)(timing);
  }
}

private auto timing_to_angle(U, alias s, T)(const T timing) if (isUnits!(U, Angle) &&
                                                                !is(s) && isTiming!(s) &&
                                                                isTiming!T) {
  enum dt = asTiming!(s, sec, T);
  static if (hasUnits!(T, Frequency)) {
    auto delta = dt.raw * timing.to!Hz.raw;
  } else {
    auto delta = dt.raw / timing.to!sec.raw;
  }
  return delta.as!rev.to!U;
}

/**
   Initialize oscillator parameters using oscillation frequency or period
 */
pure nothrow @nogc @safe
auto mk(alias P, U, alias s, T)(const T timing) if (__traits(isSame, Param, P) &&
                                                    isUnits!(U, Angle) &&
                                                    !is(s) && isTiming!s &&
                                                    isTiming!T) {
  auto delta = timing_to_angle!(U, s)(timing);
  return Param!(typeof(delta), s)(delta);
}

/// Test oscillator parameters (floating-point)
nothrow @nogc unittest {
  enum dt = 1.0.as!msec;
  auto param = mk!(Param, rev, dt)(50.0.as!Hz);

  assert_eq(param.delta, 50e-3.as!rev);

  param = 100.0.as!Hz;
  assert_eq(param.delta, 100e-3.as!rev);
}

/// Test oscillator parameters (fixed-point)
nothrow @nogc unittest {
  enum dt = 1.0.as!msec;
  auto param = mk!(Param, rev, dt)(asfix!50.0.as!Hz);

  assert_eq(param.delta, asfix!50e-3.as!rev);

  param = asfix!100.0.as!Hz;
  assert_eq(param.delta, asfix!100e-3.as!rev);
}

/// Test oscillator parameters (fixed-point)
nothrow @nogc unittest {
  enum dt = 1.0.as!msec;
  alias F = fix!(0.0, 500.0);
  alias P = fix!(1e-3, 0.5);
  auto param = mk!(Param, rev, dt)(F(50.0).as!Hz);

  assert_eq(param.delta, P(50e-3).as!rev);

  param = F(25.0).as!Hz;
  assert_eq(param.delta, P(25e-3).as!rev);
}

/// Test oscillator parameters (fixed-point)
nothrow @nogc unittest {
  enum dt = 1.0.as!msec;
  alias F = fix!(0.0, 500.0);
  alias P = fix!(1e-3, 0.5);
  auto param = mk!(Param, qrev, dt)(F(50.0).as!Hz);

  assert_eq(param.delta, P(200e-3).as!qrev);

  param = F(100.0).as!Hz;
  assert_eq(param.delta, P(400e-3).as!qrev);
}

/// Test oscillator parameters (floating-point)
nothrow @nogc unittest {
  enum dt = 1.0.as!msec;
  auto param = mk!(Param, rev, dt)(20e-3.as!sec);

  assert_eq(param.delta, 50e-3.as!rev);

  param = 10e-3.as!sec;
  assert_eq(param.delta, 100e-3.as!rev);
}

/// Test oscillator parameters (fixed-point)
nothrow @nogc unittest {
  enum dt = 1.0.as!msec;
  auto param = mk!(Param, rev, dt)(asfix!20.0.as!msec);

  assert_eq(param.delta, asfix!49.99999997e-3.as!rev);

  param = asfix!40.0.as!msec;
  assert_eq(param.delta, asfix!24.99999999e-3.as!rev);
}

/// Test oscillator parameters (fixed-point)
nothrow @nogc unittest {
  enum dt = 1.0.as!msec;
  alias T = fix!(1e-6, 1.0);
  alias P = fix!(1e-3, 1e3);
  auto param = mk!(Param, rev, dt)(T(20e-3).as!sec);

  assert_eq(param.delta, P(49.9997139e-3).as!rev);

  param = T(10e-3).as!sec;
  assert_eq(param.delta, P(99.99990463e-3).as!rev);
}

/**
   Oscillator state
*/
struct State(alias P_, A_) if (isInstanceOf!(Param, typeOf!P_) && isNumer!(P_.A.raw_t, A_)) {
  /// Parameters type
  alias P = typeOf!P_;

  /// Angle type
  alias A = Val!(A_, P.A.units);

  /// Current phase of modulator
  A phase = A_(0).as!(P.A.units);

  /// Init state with specified phase
  const pure nothrow @nogc @safe
  this(const A phase_) {
    phase = phase_;
  }

  /// Set phase from angle
  pure nothrow @nogc @safe
  void opAssign(T)(const T angle) if (hasUnits!(T, Angle) && isNumer!(rawTypeOf!A, rawTypeOf!T)) {
    phase = cast(A) angle.to!(A.units)._unwind();
  }

  /// Set phase from time
  pure nothrow @nogc @safe
  void opAssign(T)(const T time) if (hasUnits!(T, Time) && isNumer!(rawTypeOf!A, rawTypeOf!T)) {
    enum f = asTiming!(P.s, Hz, T);
    phase = cast(A) (time.to!sec.raw * f.raw).as!rev.to!(A.units)._unwind();
  }

  /// Apply oscillator step
  pure nothrow @nogc @safe
  A opCall(ref const P param) {
    phase = cast(A) (phase + param.delta)._unwind();
    return phase;
  }
}

private auto _unwind(A)(const A phase) if (hasUnits!(A, Angle)) {
  return (phase.raw % pi!(2, A).raw).as!(A.units);
}

/// Test oscillator (floating-point)
nothrow @nogc unittest {
  enum dt = 1.0.as!msec;

  auto param = mk!(Param, rev, dt)(50.0.as!Hz);
  auto state = State!(param, double)();

  assert_eq(state.phase, 0.0.as!rev);

  state = 2.0.as!qrev;
  assert_eq(state.phase, 0.5.as!rev);

  state = 5.0.as!qrev;
  assert_eq(state.phase, 0.25.as!rev);

  assert_eq(state(param), 0.3.as!rev);
  assert_eq(state(param), 0.35.as!rev);
}

/// Test oscillator (fixed-point)
nothrow @nogc unittest {
  alias A = fix!(-10, 10);
  enum dt = 1.0.as!msec;

  auto param = mk!(Param, rev, dt)(asfix!50.0.as!Hz);
  auto state = State!(param, A)();

  assert_eq(state.phase, A(0.0).as!rev);

  state = A(2.0).as!qrev;
  assert_eq(state.phase, A(0.5).as!rev);

  state = A(5.0).as!qrev;
  assert_eq(state.phase, A(0.25).as!rev);

  assert_eq(state(param), A(0.3).as!rev);
  assert_eq(state(param), A(0.35).as!rev);
}
