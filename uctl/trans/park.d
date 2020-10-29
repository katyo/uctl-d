/**
  ## DQZ (Park) transformation

  The implementation of Direct-Quadrature-Zero (DQZ) transformations which also known as Park transformations.

  See_Also: [DQZ transformation](https://en.wikipedia.org/wiki/Direct-quadrature-zero_transformation) wikipedia article.
*/
module uctl.trans.park;

import std.traits: isInstanceOf;
import std.math: sqrt;
import uctl.num: isNumer, asnum;
import uctl.unit: hasUnits, Angle, as, to, qrev, rawTypeOf, rawof;
import uctl.math.trig: isSinOrCos, pi;
import uctl.util.vec: sliceof, isVec, VecType, isGenVec, GenVec;

version(unittest) {
  import std.array: staticArray;
  import uctl.test: assert_eq, unittests;
  import uctl.num: fix;
  import uctl.unit: deg, V;
  import uctl.math.trig: sin, cos;

  mixin unittests;
}

/**
   Transform stationary α-β coordinates to rotating DQ

   The direct Park transformation

   $(MATH d = α cos(θ) + β sin(θ)),
   $(MATH q = β cos(θ) - α sin(θ))
*/
pure nothrow @nogc @safe
void park(alias S, R, T, A)(ref R dq, const ref T ab, const A theta)
if (isVec!(T, 2) && isVec!(R, 2) &&
    hasUnits!(A, Angle) && isSinOrCos!(S, A) &&
    isNumer!(rawTypeOf!(VecType!T), rawTypeOf!(VecType!R)) &&
    (!hasUnits!(VecType!T) && !hasUnits!(VecType!R) ||
     hasUnits!(VecType!R, VecType!T.units)) &&
    isNumer!(rawTypeOf!(VecType!T), rawTypeOf!A)) {
  alias Rt = rawTypeOf!(VecType!R);

  const sin_theta = S(theta);
  const cos_theta = S(pi!(0.5, A) - theta); // cos(a) == sin(pi/2-a)

  const alpha = ab.sliceof[0].rawof;
  const beta = ab.sliceof[1].rawof;

  const d = alpha * cos_theta + beta * sin_theta;
  const q = beta * cos_theta - alpha * sin_theta;

  dq.sliceof[0].rawof = cast(Rt) d;
  dq.sliceof[1].rawof = cast(Rt) q;
}

/**
   Transform stationary α-β coordinates to rotating DQ

   The direct Park transformation

   $(MATH d = α cos(θ) + β sin(θ)),
   $(MATH q = β cos(θ) - α sin(θ))
*/
pure nothrow @nogc @safe
auto park(alias R, alias S, T, A)(const ref T ab, const A theta)
if (isVec!(T, 2) &&
    hasUnits!(A, Angle) && isSinOrCos!(S, A) &&
    isNumer!(rawTypeOf!(VecType!T), rawTypeOf!A)) {
  GenVec!(R, VecType!T) dq;

  park!S(dq, ab, theta);

  return dq;
}

// Test direct Park transformation (floating-point)
nothrow @nogc unittest {
  auto a = [2.5, -1.25].staticArray;
  auto t = 30.0.as!deg;

  auto b = a.park!([2], sin!5)(t);

  assert_eq(b.sliceof[0], 1.540688649, 1e-6);
  assert_eq(b.sliceof[1], -2.33235538, 1e-6);
}

// Test direct Park transformation (floating-point with units)
nothrow @nogc unittest {
  auto a = [2.5.as!V, -1.25.as!V].staticArray;
  auto t = 30.0.as!deg;

  auto b = a.park!([2], sin!5)(t);

  assert_eq(b.sliceof[0], 1.540688649.as!V, 1e-6);
  assert_eq(b.sliceof[1], -2.33235538.as!V, 1e-6);
}

// Test direct Park transformation (fixed-point)
nothrow @nogc unittest {
  alias A = fix!(-200, 200);
  alias X = fix!(-5, 5);

  auto a = [X(2.5), X(-1.25)].staticArray;
  auto t = A(30.0).as!deg;

  auto b = a.park!([2], sin!5)(t);

  assert_eq(b.sliceof[0], X(1.540688649), X(1e-8));
  assert_eq(b.sliceof[1], X(-2.33235538), X(1e-8));
}

/**
   Transform rotating DQ coordinates to stationary α-β coordinates

   The inverted Park transformation

   $(MATH α = d cos(θ) - q sin(θ)),
   $(MATH β = q cos(θ) + d sin(θ))
*/
pure nothrow @nogc @safe
void ipark(alias S, R, T, A)(ref R ab, const ref T dq, const A theta)
if (isVec!(R, 2) && isVec!(T, 2) &&
    hasUnits!(A, Angle) && isSinOrCos!(S, A) &&
    isNumer!(rawTypeOf!(VecType!T), rawTypeOf!(VecType!R)) &&
    (!hasUnits!(VecType!T) && !hasUnits!(VecType!R) ||
     hasUnits!(VecType!R, VecType!T.units)) &&
    isNumer!(rawTypeOf!(VecType!T), rawTypeOf!A)) {
  alias Rt = rawTypeOf!(VecType!R);

  const sin_theta = S(theta);
  const cos_theta = S(pi!(0.5, A) - theta); // cos(a) == sin(pi/2-a)

  const d = dq.sliceof[0].rawof;
  const q = dq.sliceof[1].rawof;

  const alpha = d * cos_theta - q * sin_theta;
  const beta = q * cos_theta + d * sin_theta;

  ab.sliceof[0].rawof = cast(Rt) alpha;
  ab.sliceof[1].rawof = cast(Rt) beta;
}

/**
   Transform rotating DQ coordinates to stationary α-β coordinates

   The inverted Park transformation

   $(MATH α = d cos(θ) - q sin(θ)),
   $(MATH β = q cos(θ) + d sin(θ))
*/
pure nothrow @nogc @safe
auto ipark(alias R, alias S, T, A)(const ref T dq, const A theta)
if (isGenVec!(R, 2) && isVec!(T, 2) &&
    hasUnits!(A, Angle) && isSinOrCos!(S, A) &&
    isNumer!(rawTypeOf!(VecType!T), rawTypeOf!A)) {
  GenVec!(R, VecType!T) ab;

  ipark!S(ab, dq, theta);

  return ab;
}

// Test inverted Park transformation (floating-point)
nothrow @nogc unittest {
  auto a = [1.540688649, -2.33235538].staticArray;
  auto t = 30.0.as!deg;

  auto b = a.ipark!([2], sin!5)(t);

  assert_eq(b.sliceof[0], 2.500353001, 1e-6);
  assert_eq(b.sliceof[1], -1.250176512, 1e-6);
}

// Test inverted Park transformation (floating-point with units)
nothrow @nogc unittest {
  auto a = [1.540688649.as!V, -2.33235538.as!V].staticArray;
  auto t = 30.0.as!deg;

  auto b = a.ipark!([2], sin!5)(t);

  assert_eq(b.sliceof[0], 2.500353001.as!V, 1e-6);
  assert_eq(b.sliceof[1], -1.250176512.as!V, 1e-6);
}

// Test inverted Park transformation (fixed-point)
nothrow @nogc unittest {
  alias A = fix!(-200, 200);
  alias X = fix!(-5, 5);

  auto a = [X(1.540688649), X(-2.33235538)].staticArray;
  auto t = A(30.0).as!deg;

  auto b = a.ipark!([2], sin!5)(t);

  assert_eq(b.sliceof[0], X(2.500353001), X(1e-8));
  assert_eq(b.sliceof[1], X(-1.250176512), X(1e-8));
}
