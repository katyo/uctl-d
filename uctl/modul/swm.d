/**
   ### Multiphase sine-wave modulation

   ![Sine-wave modulation for 1, 2 and 3 phases](mod_swm.svg)
 */
module uctl.modul.swm;

import std.traits: isInstanceOf, isArray;
import uctl.num: isNumer, isInt;
import uctl.math.trig: isSinOrCos, half_pi, two_third_pi;

version(unittest) {
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/// Generate wave(s)
auto swm(alias S, alias R, T)(const T phase) if (isSinOrCos!(S, T) && ((!is(R) && isArray!(typeof(R)) && R.length == 1 && isInt!(R[0]) && R[0] >= 1 && R[0] <= 3))) {
  alias O = typeof(S(phase));

  static if (!is(R) && isArray!(typeof(R))) {
    enum uint N = R[0];
    O[N] res;

    static if (N == 1) {
      res[0] = S(phase);
    } else static if (N == 2) {
      res[0] = S(phase);
      res[1] = S(phase + half_pi!T);
    } else static if (N == 3) {
      res[0] = S(phase);
      res[1] = S(phase + two_third_pi!T);
      res[2] = S(phase - two_third_pi!T);
    }
  }

  return res;
}

/// Test modulation (floating-point)
nothrow @nogc unittest {
  import uctl: mk;
  import uctl.util.osc: Param, State;
  import uctl.math.trig: sin;
  import uctl.unit: as, hpi, Hz;

  alias sine = sin!5;
  enum auto dt = 0.001;

  auto param = mk!(Param, hpi, dt)(50.0.as!Hz);
  auto state = State!(param, double)();

  // Step 0
  auto phase = state.phase;

  auto a = swm!(sine, [1])(phase);
  assert_eq(a[0], 0.0);

  auto ab = swm!(sine, [2])(phase);
  assert_eq(ab[0], 0.0);
  assert_eq(ab[1], 1.0);

  auto abc = swm!(sine, [3])(phase);
  assert_eq(abc[0], 0.0);
  assert_eq(abc[1], 0.86619724983652);
  assert_eq(abc[2], -0.86619724983652);

  /// Step 1
  auto phase2 = state.apply(param);

  auto a2 = swm!(sine, [1])(phase2);
  assert_eq(a2[0], 0.3088505386567556);

  auto ab2 = swm!(sine, [2])(phase2);
  assert_eq(ab2[0], 0.3088505386567556);
  assert_eq(ab2[1], 0.951228427994425);

  auto abc2 = swm!(sine, [3])(phase2);
  assert_eq(abc2[0], 0.3088505386567556);
  assert_eq(abc2[1], 0.669092649734379541);
  assert_eq(abc2[2], -0.978261450902767948);
}

/// Test modulation (floating-point)
nothrow @nogc unittest {
  import uctl: mk;
  import uctl.util.osc: Param, State;
  import uctl.math.trig: sin;
  import uctl.unit: as, hpi, Hz;
  import uctl.num: fix;

  alias sine = sin!5;
  enum auto dt = 0.001;
  alias F = fix!(0, 200);
  alias A = fix!(-5, 5);
  alias P = fix!(-1, 1);

  auto param = mk!(Param, hpi, dt)(F(50.0).as!Hz);
  auto state = State!(param, A)();

  /// Step 0
  auto phase = state.phase;

  auto a = swm!(sine, [1])(phase);
  assert_eq(a[0], P(0.0));

  auto ab = swm!(sine, [2])(phase);
  assert_eq(ab[0], P(0.0));
  assert_eq(ab[1], P(1.0));

  auto abc = swm!(sine, [3])(phase);
  assert_eq(abc[0], P(0.0));
  assert_eq(abc[1], P(0.8661972284));
  assert_eq(abc[2], P(-0.866197288));

  /// Step 1
  auto phase2 = state.apply(param);

  auto a2 = swm!(sine, [1])(phase2);
  assert_eq(a2[0], P(0.3088505268));

  auto ab2 = swm!(sine, [2])(phase2);
  assert_eq(ab2[0], P(0.3088505268));
  assert_eq(ab2[1], P(0.9512283802));

  auto abc2 = swm!(sine, [3])(phase2);
  assert_eq(abc2[0], P(0.3088505268));
  assert_eq(abc2[1], P(0.6690926552));
  assert_eq(abc2[2], P(-0.9782614708));
}
