/**
  ## α-β (Clarke) transformations

  The implementation of α-β transformations which also known as the Clarke transformations.

  See_Also: [αβ transformation](https://en.wikipedia.org/wiki/Alpha-beta_transformation) wikipedia article.
*/
module uctl.trans.clarke;

import std.traits: isInstanceOf;
import std.math: sqrt;
import uctl.num: isNumer, asnum;
import uctl.unit: hasUnits, Angle, as, to, qrev, rawTypeOf, rawof;
import uctl.math.trig: isSinOrCos;
import uctl.util.vec: sliceof, isVec, VecType, isGenVec, GenVec;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.num: fix;
  import uctl.unit: V;
  import std.array: staticArray;

  mixin unittests;
}

/**
   Transform ABC to α-β

   The direct Clarke transformation

   $(MATH α = A),
   $(MATH β = \frac{A + 2 B}{\sqrt{3}})
*/
pure nothrow @nogc @safe
void clarke(R, T)(ref R ab, const ref T abc)
if (isVec!(R, 2) && (isVec!(T, 2) || isVec!(T, 3)) &&
    isNumer!(rawTypeOf!(VecType!T), rawTypeOf!(VecType!R)) &&
    (!hasUnits!(VecType!T) && !hasUnits!(VecType!R) ||
     hasUnits!(VecType!R, VecType!T.units))) {
  alias Tt = rawTypeOf!(VecType!T);
  alias Rt = rawTypeOf!(VecType!R);

  const a = abc.sliceof[0].rawof;
  const b = abc.sliceof[1].rawof;

  /* α = a */
  const alpha = a;

  /* β = (a + 2 * b) / sqrt(3) */
  const beta = (a + b * asnum!(2.0, Tt)) * asnum!(1.0 / sqrt(3.0), Tt);

  ab.sliceof[0].rawof = cast(Rt) alpha;
  ab.sliceof[1].rawof = cast(Rt) beta;
}

/**
   Transform ABC to α-β

   The direct Clarke transformation

   $(MATH α = A),
   $(MATH β = \frac{A + 2 B}{\sqrt{3}})
*/
pure nothrow @nogc @safe
auto clarke(alias R, T)(const ref T abc)
if (isGenVec!(R, 2) && (isVec!(T, 2) || isVec!(T, 3)) &&
    isNumer!(rawTypeOf!(VecType!T))) {
  GenVec!(R, VecType!T) ab;

  clarke(ab, abc);

  return ab;
}

// Test direct Clarke transformation (floating-point)
nothrow @nogc unittest {
  auto a = [1.25, -1.361121595, 0.1111215949].staticArray;

  auto b = a.clarke!([2]);

  assert_eq(b.sliceof[0], 1.25);
  assert_eq(b.sliceof[1], -0.85, 1e-8);

  auto a_ = [1.25, -1.361121595].staticArray;

  auto b_ = a_.clarke!([2]);

  assert_eq(b_.sliceof[0], 1.25);
  assert_eq(b_.sliceof[1], -0.85, 1e-8);
}

// Test direct Clarke transformation (floating-point with units)
nothrow @nogc unittest {
  auto a = [1.25.as!V, -1.361121595.as!V, 0.1111215949.as!V].staticArray;

  auto b = a.clarke!([2]);

  assert_eq(b.sliceof[0], 1.25.as!V);
  assert_eq(b.sliceof[1], -0.85.as!V, 1e-8);

  auto a_ = [1.25.as!V, -1.361121595.as!V].staticArray;

  auto b_ = a_.clarke!([2]);

  assert_eq(b_.sliceof[0], 1.25.as!V);
  assert_eq(b_.sliceof[1], -0.85.as!V, 1e-8);
}

// Test direct Clarke transformation (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(-5, 5);

  auto a = [X(1.25), X(-1.361121595), X(0.1111215949)].staticArray;

  auto b = a.clarke!([2]);

  assert_eq(b.sliceof[0], X(1.25));
  assert_eq(b.sliceof[1], X(-0.85), X(1e-8));
}

/**
   Transform α-β vector to ABC vector

   The inverted Clarke transformation

   $(MATH A = α),
   $(MATH B = \frac{- α + \sqrt{3} β}{2}),
   $(MATH C = \frac{- α -\sqrt{3} β}{2})
*/
pure nothrow @nogc @safe
void iclarke(R, T)(ref R abc, const ref T ab)
if ((isVec!(R, 2) || isVec!(R, 3)) && isVec!(T, 2) &&
    isNumer!(rawTypeOf!(VecType!T), rawTypeOf!(VecType!R)) &&
    (!hasUnits!(VecType!T) && !hasUnits!(VecType!R) ||
     hasUnits!(VecType!R, VecType!T.units))) {
  alias Tt = rawTypeOf!(VecType!T);
  alias Rt = rawTypeOf!(VecType!R);

  const alpha = ab.sliceof[0].rawof;
  const beta = ab.sliceof[1].rawof;

  // a = α
  const a = alpha;

  // t1 = -α / 2
  const t1 = -a / asnum!(2, Tt);

  // t2 = β * sqrt(3) / 2
  const t2 = beta * asnum!(sqrt(3.0) / 2, Tt);

  // b = t1 + t2
  const b = t1 + t2;

  abc.sliceof[0].rawof = cast(Rt) a;
  abc.sliceof[1].rawof = cast(Rt) b;

  static if (isVec!(R, 3)) {
    // c = t1 - t2
    const c = t1 - t2;

    abc.sliceof[2].rawof = cast(Rt) c;
  }
}

/**
   Transform α-β vector to ABC vector

   The inverted Clarke transformation

   $(MATH A = α),
   $(MATH B = \frac{- α + \sqrt{3} β}{2}),
   $(MATH C = \frac{- α -\sqrt{3} β}{2})
*/
pure nothrow @nogc @safe
auto iclarke(alias R, T)(const ref T ab)
if ((isGenVec!(R, 2) || isGenVec!(R, 3)) && isVec!(T, 2) &&
    isNumer!(rawTypeOf!(VecType!T))) {
  GenVec!(R, VecType!T) abc;

  iclarke(abc, ab);

  return abc;
}

/// Test inverted Clarke transformation (floating-point)
nothrow @nogc unittest {
  auto a = [1.25, -0.85].staticArray;

  auto b = a.iclarke!([3]);

  assert_eq(b.sliceof[0], 1.25);
  assert_eq(b.sliceof[1], -1.361121595, 1e-8);
  assert_eq(b.sliceof[2], 0.1111215949, 1e-8);

  auto c = a.iclarke!([2]);

  assert_eq(c.sliceof[0], 1.25);
  assert_eq(c.sliceof[1], -1.361121595, 1e-8);
}

/// Test inverted Clarke transformation (floating-point with units)
nothrow @nogc unittest {
  auto a = [1.25.as!V, -0.85.as!V].staticArray;

  auto b = a.iclarke!([3]);

  assert_eq(b.sliceof[0], 1.25.as!V);
  assert_eq(b.sliceof[1], -1.361121595.as!V, 1e-8);
  assert_eq(b.sliceof[2], 0.1111215949.as!V, 1e-8);

  auto c = a.iclarke!([2]);

  assert_eq(c.sliceof[0], 1.25.as!V);
  assert_eq(c.sliceof[1], -1.361121595.as!V, 1e-8);
}

/// Test inverted Clarke transformation (fixed-point)
nothrow @nogc unittest {
  alias X = fix!(-5, 5);

  auto a = [X(1.25), X(-0.85)].staticArray;

  auto b = a.iclarke!([3]);

  assert_eq(b.sliceof[0], X(1.25));
  assert_eq(b.sliceof[1], X(-1.361121595));
  assert_eq(b.sliceof[2], X(0.1111215949));

  auto c = a.iclarke!([2]);

  assert_eq(c.sliceof[0], X(1.25));
  assert_eq(c.sliceof[1], X(-1.361121595));
}
