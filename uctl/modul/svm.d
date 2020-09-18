/**
   ### 3-phase space-vector modulation

   ![Space-vector modulation for 3 phases](mod_svm.svg)

   See_Also:
   [Space-vector modulation](https://en.wikipedia.org/wiki/Space_vector_modulation).
 */
module uctl.modul.svm;

import std.traits: isInstanceOf, isArray;
import uctl.num: isNumer, asnum, isInt;
import uctl.math.trig: isSinOrCos, pi;
import uctl.unit: hasUnits, as, Angle, asval;
import uctl.util.vec: isGenVec, genVecSize, GenVec, sliceof;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.unit: qrev;

  mixin unittests;
}

private uint sectorize(A)(ref A phase) if (hasUnits!(A, Angle)) {
  if (phase < cast(A) asval!(0, A)) {
    phase += pi!(2.0, A);
  }

  uint sector = 0;

  if (phase >= cast(A) pi!A) {
    sector = 3;
    phase -= pi!(1.0, A);
  }

  if (phase >= cast(A) pi!(2.0/3.0, A)) {
    sector += 2;
    phase -= pi!(2.0/3.0, A);
  } else if (phase >= cast(A) pi!(1.0/3.0, A)) {
    sector += 1;
    phase -= pi!(1.0/3.0, A);
  }

  return sector;
}

nothrow @nogc unittest {
  // 0
  auto phase = 0.0.as!qrev;

  alias A = typeof(phase);

  assert_eq(sectorize(phase), 0);
  assert_eq(phase.raw, 0.0);

  phase = pi!(1.0/3.0, A);

  assert_eq(sectorize(phase), 1);
  assert_eq(phase.raw, 0.0);

  // 2/3 PI
  phase = pi!(2.0/3.0, A);

  assert_eq(sectorize(phase), 2);
  assert_eq(phase.raw, 0.0);

  // 3/3 PI
  phase = pi!(1.0, A);

  assert_eq(sectorize(phase), 3);
  assert_eq(phase.raw, 0.0);

  // 4/3 PI
  phase = pi!(4.0/3.0, A);

  assert_eq(sectorize(phase), 3);
  assert_eq(phase.raw, 0.666666666666666519);

  // 5/3 PI
  phase = pi!(5.0/3.0, A);

  assert_eq(sectorize(phase), 5);
  assert_eq(phase.raw, 2.22044604925031308e-16);

  // 6/3 PI
  phase = pi!(2.0, A);

  assert_eq(sectorize(phase), 5);
  assert_eq(phase.raw, 0.666666666666666741);

  phase = 0.5.as!qrev;

  assert_eq(sectorize(phase), 0);
  assert_eq(phase.raw, 0.5);

  phase = 1.0.as!qrev;

  assert_eq(sectorize(phase), 1);
  assert_eq(phase.raw, 0.33333333333333337);

  phase = 3.0.as!qrev;

  assert_eq(sectorize(phase), 4);
  assert_eq(phase.raw, 0.33333333333333337);
}

/// Generate wave(s)
auto svm(alias S, alias R = [3], T)(const T phase) if (isSinOrCos!(S, T) && isGenVec!R && genVecSize!R == 3) {
  alias O = typeof(S(phase));

  GenVec!(R, O) res;

  auto sphase = cast(T) phase;
  auto sector = sectorize(sphase);

  auto dx = S(pi!(1.0/3.0, T) - sphase);
  auto dy = S(sphase);

  version(always) {
    template P3(ubyte a, ubyte b, ubyte c) {
      enum ubyte P3 = (a << 4) | (b << 2) | (c << 0);
    }

    static immutable char[6] ps = [P3!(0, 1, 2),
                                   P3!(1, 0, 2),
                                   P3!(1, 2, 0),
                                   P3!(2, 1, 0),
                                   P3!(2, 0, 1),
                                   P3!(0, 2, 1)];

    auto p = ps[sector];
    auto p0 = p >> 4;
    auto p1 = (p >> 2) & 3;
    auto p2 = p & 3;
  } else {
    auto p0 = ((sector + 1) / 2) % 3;
    auto p1 = 2 - ((sector + 1) % 3);
    auto p2 = ((sector + 4) / 2) % 3;
  }

  auto a = cast(O) (dx + dy);
  auto b = cast(O) (-a);
  auto c = cast(O) (b + asnum!(2, O) * (sector & 1 ? dy : dx));

  res.sliceof[p2] = a;
  res.sliceof[p0] = b;
  res.sliceof[p1] = c;

  return res;
}

/// Test modulation (floating-point)
nothrow @nogc unittest {
  import uctl: mk;
  import uctl.util.osc: Param, State;
  import uctl.math.trig: sin;
  import uctl.unit: as, qrev, Hz;

  alias sine = sin!5;
  enum auto dt = 0.001;

  auto param = mk!(Param, qrev, dt)(50.0.as!Hz);
  auto state = State!(param, double)();

  // Step 0
  auto phase = state.phase;

  auto abc = svm!(sine, [3])(phase);
  assert_eq(abc[0], -0.866197249836520133);
  assert_eq(abc[1], 0.86619724983652);
  assert_eq(abc[2], 0.866197249836520133);

  /// Step 1
  auto phase2 = state.apply(param);

  auto abc2 = svm!(sine, [3])(phase2);
  assert_eq(abc2[0], -0.977943188391134921);
  assert_eq(abc2[1], 0.360242111077623717);
  assert_eq(abc2[2], 0.977943188391134921);
}

/// Test modulation (fixed-point)
nothrow @nogc unittest {
  import uctl: mk;
  import uctl.util.osc: Param, State;
  import uctl.math.trig: sin;
  import uctl.unit: as, qrev, Hz;
  import uctl.num: fix;

  alias sine = sin!5;
  enum auto dt = 0.001;
  alias F = fix!(0, 200);
  alias A = fix!(-5, 5);
  alias P = fix!(-1, 1);

  auto param = mk!(Param, qrev, dt)(F(50.0).as!Hz);
  auto state = State!(param, A)();

  /// Step 0
  auto phase = state.phase;

  auto abc = svm!(sine, [3])(phase);
  assert_eq(abc[0], P(-0.8661972284));
  assert_eq(abc[1], P(0.8661972284));
  assert_eq(abc[2], P(0.8661972284));

  /// Step 1
  auto phase2 = state.apply(param);

  auto abc2 = svm!(sine, [3])(phase2);
  assert_eq(abc2[0], P(-0.9779431224));
  assert_eq(abc2[1], P(0.3602420688));
  assert_eq(abc2[2], P(0.9779431224));
}
