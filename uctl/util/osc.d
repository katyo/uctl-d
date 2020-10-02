/**
   ### Basic oscillator

   Generic implementation of basic oscillator.
 */
module uctl.util.osc;

import std.traits: isInstanceOf, Unqual;
import uctl.num: isNumer, asnum, typeOf;
import uctl.unit: Val, hasUnits, isUnits, Frequency, Time, Angle, Hz, sec, to, as, rev, qrev;
import uctl.math: pi;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.num: fix, asfix;

  mixin unittests;
}

/**
   Oscillator parameters
*/
struct Param(A_, U_) if (isNumer!(A_) && isUnits!(U_, Angle)) {
  /// Phase type
  alias A = Val!(Unqual!A_, U_);

  /// Phase increment for single step
  A delta;

  /// Init param with specified phase increment
  const pure nothrow @nogc @safe
  this(const A delta_) {
    delta = delta_;
  }
}

/**
   Init oscillator parameters using frequency
 */
pure nothrow @nogc @safe
auto mk(alias P, U, real dt, F)(const F freq) if (__traits(isSame, Param, P) &&
                                                  isUnits!(U, Angle) &&
                                                  hasUnits!(F, Frequency)) {
  auto delta = (freq.to!Hz.raw * asnum!(dt, F.raw_t)).as!rev.to!U;
  return Param!(typeof(delta.raw), U)(delta);
}

/// Test oscillator parameters (floating-point)
nothrow @nogc unittest {
  enum dt = 0.001;
  auto param = mk!(Param, rev, dt)(50.0.as!Hz);

  assert_eq(param.delta, 50e-3.as!rev);
}

/// Test oscillator parameters (fixed-point)
nothrow @nogc unittest {
  enum dt = 0.001;
  auto param = mk!(Param, rev, dt)(asfix!50.0.as!Hz);

  assert_eq(param.delta, asfix!50e-3.as!rev);
}

/// Test oscillator parameters (fixed-point)
nothrow @nogc unittest {
  enum dt = 0.001;
  alias F = fix!(0.0, 500.0);
  alias P = fix!(1e-3, 0.5);
  auto param = mk!(Param, rev, dt)(F(50.0).as!Hz);

  assert_eq(param.delta, P(50e-3).as!rev);
}

/// Test oscillator parameters (fixed-point)
nothrow @nogc unittest {
  enum dt = 0.001;
  alias F = fix!(0.0, 500.0);
  alias P = fix!(1e-3, 0.5);
  auto param = mk!(Param, qrev, dt)(F(50.0).as!Hz);

  assert_eq(param.delta, P(200e-3).as!qrev);
}

/**
   Init oscillator parameters using period
*/
auto mk(alias P, U, real dt, T)(const T period) if (__traits(isSame, Param, P) &&
                                                    isUnits!(U, Angle) &&
                                                    hasUnits!(T, Time)) {
  auto delta = (asnum!(dt, T.raw_t) / period.to!sec.raw).as!rev.to!U;
  return Param!(typeof(delta.raw), U)(delta);
}

/// Test oscillator parameters (floating-point)
nothrow @nogc unittest {
  enum dt = 0.001;
  auto param = mk!(Param, rev, dt)(20e-3.as!sec);

  assert_eq(param.delta, 50e-3.as!rev);
}

/// Test oscillator parameters (fixed-point)
nothrow @nogc unittest {
  enum dt = 0.001;
  auto param = mk!(Param, rev, dt)(asfix!20e-3.as!sec);

  assert_eq(param.delta, asfix!49.99999997e-3.as!rev);
}

/// Test oscillator parameters (fixed-point)
nothrow @nogc unittest {
  enum dt = 0.001;
  alias T = fix!(1e-6, 1.0);
  alias P = fix!(1e-3, 1e3);
  auto param = mk!(Param, rev, dt)(T(20e-3).as!sec);

  assert_eq(param.delta, P(49.9997139e-3).as!rev);
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
  void set(T)(const T angle) if (hasUnits!(T, Angle)) {
    phase = cast(A) angle.to!(A.units)._unwind();
  }

  /// Set phase from time
  pure nothrow @nogc @safe
  void set(real dt, T)(const T time) if (hasUnits!(T, Time)) {
    phase = cast(A) (time.to!sec.raw * asnum!(1.0 / dt, T.raw_t)).as!rev.to!(A.units)._unwind();
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
  enum dt = 0.001;

  auto param = mk!(Param, rev, dt)(50.0.as!Hz);
  auto state = State!(param, double)();

  assert_eq(state.phase, 0.0.as!rev);

  state.set(2.0.as!qrev);
  assert_eq(state.phase, 0.5.as!rev);

  state.set(5.0.as!qrev);
  assert_eq(state.phase, 0.25.as!rev);

  assert_eq(state(param), 0.3.as!rev);
  assert_eq(state(param), 0.35.as!rev);
}

/// Test oscillator (fixed-point)
nothrow @nogc unittest {
  alias A = fix!(-10, 10);
  enum dt = 0.001;

  auto param = mk!(Param, rev, dt)(asfix!50.0.as!Hz);
  auto state = State!(param, A)();

  assert_eq(state.phase, A(0.0).as!rev);

  state.set(A(2.0).as!qrev);
  assert_eq(state.phase, A(0.5).as!rev);

  state.set(A(5.0).as!qrev);
  assert_eq(state.phase, A(0.25).as!rev);

  assert_eq(state(param), A(0.3).as!rev);
  assert_eq(state(param), A(0.35).as!rev);
}
