/**
   ### 3-phase phase-shift correction.

   Phase-shift PWM correction (compensation) can help to improve final wave-form for phases current measurement using single current sensor.

   Invertor scheme:
   ```
   DC+ ----o-------o-------o
           |       |       |
           I        \       \
           |       |       |
        A (+)   B (-)   C (-)
           |       |       |
            \      I       I
           |       |       |
   DC- ----o-------o-------o
   ```

   $(SMALL_TABLE
   Switch table
   | Sa | Sb | Sc | Idc |
   |----|----|----|-----|
   | +  | -  | -  | +Ia |
   | -  | +  | +  | -Ia |
   |    |    |    |     |
   | -  | +  | -  | +Ib |
   | +  | -  | +  | -Ib |
   |    |    |    |     |
   | -  | -  | +  | +Ic |
   | +  | +  | -  | -Ic |
   |    |    |    |     |
   | -  | -  | -  | 0   |
   | +  | +  | +  | 0   |
   )

   ![SVM with phase correction](mod_svm_psc.svg)

   See_Also:
   [Single-Shunt Three-Phase Current Reconstruction Algorithm for Sensorless FOC of a PMSM](http://ww1.microchip.com/downloads/en/appnotes/01299a.pdf)
*/
module uctl.modul.psc;

import std.traits: isInstanceOf, Unqual;
import uctl.num: isNumer, typeOf, asnum;
import uctl.unit: to, hasUnits, Frequency, Time, sec, Hz;
import uctl.util.vec: isVec, VecType, sliceof, isGenVec, GenVec;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.unit: as, usec, msec;

  mixin unittests;
}

/**
   Corrector parameters type

   Params:
   T = The type to operate
 */
struct Param(T_) if (isNumer!T_) {
  alias T = Unqual!T_;

  /// Minimum relative time for compensation
  T delay;

  /// Initialize parameters uing minimum delay for measurement complete
  pure nothrow @nogc @safe
  this(const T delay_) const {
    delay = delay_;
  }
}

/**
   Configure corrector using critical time and PWM period

   Params:
   crit_time = Critical time to adjust to (Usually the minimum required time to measure current)
   period = Pulse-width modulation period
 */
auto mk(alias P, T, D)(const T crit_time, const D period) if (__traits(isSame, Param, P) &&
                                                              hasUnits!(T, Time) &&
                                                              hasUnits!(D, Time) &&
                                                              isNumer!(T.raw_t, D.raw_t)) {
  auto delay = crit_time.to!(D.units).raw / period.raw;
  return Param!(typeof(delay))(delay);
}

/// Test phase-shift corrector config
nothrow @nogc unittest {
  immutable auto param = mk!Param(16.0.as!usec, 10.0.as!msec);

  assert_eq(param.delay, 0.00159999999999999986);
}

/**
   Configure corrector using critical time and PWM frequency

   Params:
   crit_time = Critical time to adjust to (Usually the minimum required time to measure current)
   frequency = Pulse-width modulation frequency
*/
auto mk(alias P, T, F)(const T crit_time, const F frequency) if (__traits(isSame, Param, P) &&
                                                                 hasUnits!(T, Time) &&
                                                                 hasUnits!(F, Frequency) &&
                                                                 isNumer!(T.raw_t, F.raw_t)) {
  auto delay = crit_time.to!sec.raw * frequency.to!Hz.raw;
  return Param!(typeof(delay))(delay);
}

/// Test phase-shift corrector config
nothrow @nogc unittest {
  immutable auto param = mk!Param(16.0.as!usec, 100.0.as!Hz);

  assert_eq(param.delay, 0.00159999999999999986);
}

/**
   Corrector state type
 */
struct State(alias P_, V_) if (isInstanceOf!(Param, typeOf!P_) && isVec!(V_, 3) && isNumer!(VecType!V_, P_.T)) {
  alias P = Unqual!(typeOf!P_);
  alias V = Unqual!V_;
  alias T = VecType!V;

  /// Phase shifting
  V shift = 0.0;

  /// Initialize state
  pure nothrow @nogc @safe
  this(const V shift_) const {
    shift = shift_;
  }

  /**
     Run correction of duty cycle values

     Params:
     abc = Phases PWM values

     Return:
     Two phase indexes

     The `R` parameter can be `void`. In which case the correction won't be performed, but the effect of previous correction will be applied in any case.
   */
  pure nothrow @nogc @safe
  auto opCall(alias I = [2])(ref const P param, ref V abc) if (is(I == void) || isGenVec!(I, 2)) {
    foreach (k; 0..3) {
      auto Tp = &abc.sliceof[k];
      auto dTp = &shift.sliceof[k];

      *Tp += *dTp;
      if (*Tp < cast(T) 0) {
        *dTp = *Tp;
        *Tp = cast(T) 0;
      } else if (*Tp > cast(T) 1) {
        *dTp = *Tp - asnum!(1, T);
        *Tp = cast(T) 1;
      } else {
        *dTp = cast(T) 0;
      }
    }

    static if (!is(I == void)) {
      /*
        We may measure two phase currents:
        +I[max]
        -I[min]

        The time intervals for measurements:
        abc[max] - abc[mid]
        abc[mid] - abc[min]
      */

      GenVec!(I, uint) iab;
      uint mid;

      /* iab[0] as max, iab[1] as min */

      if (abc.sliceof[0] < abc.sliceof[1]) { /* Ta < Tb */
        if (abc.sliceof[0] < abc.sliceof[2]) { /* Ta < Tb,Tc */
          iab.sliceof[1] = 0;
          if (abc.sliceof[1] < abc.sliceof[2]) { /* Ta < Tb < Tc */
            mid = 1;
            iab.sliceof[0] = 2;
          } else { /* Ta < Tc < Tb */
            mid = 2;
            iab.sliceof[0] = 1;
          }
        } else { /* Tc < Ta < Tb */
          iab.sliceof[1] = 2;
          mid = 0;
          iab.sliceof[0] = 1;
        }
      } else { /* Tb < Ta */
        if (abc.sliceof[1] < abc.sliceof[2]) { /* Tb < Ta,Tc */
          iab.sliceof[1] = 1;
          if (abc.sliceof[0] < abc.sliceof[2]) { /* Tb < Ta < Tc */
            mid = 0;
            iab.sliceof[0] = 2;
          } else { /* Tb < Tc < Ta */
            mid = 2;
            iab.sliceof[0] = 0;
          }
        } else { /* Tc < Tb < Ta */
          iab.sliceof[1] = 2;
          mid = 1;
          iab.sliceof[0] = 0;
        }
      }

      /*
       :   ________:________   :
    A  :__|        :        |__:
   max :  .   _____:_____      :
    B  :_____|     :     |_____:
   mid :  .  .   __:__         :
    C  :________|  :  |________:
   min :  .  .  .  :           :
           T1 T2
      */

      immutable T1 = abc.sliceof[iab.sliceof[0]] - abc.sliceof[mid];
      immutable T2 = abc.sliceof[mid] - abc.sliceof[iab.sliceof[1]];

      auto dT = cast(T) 0;

      if (T1 < param.delay) {
        dT = param.delay - T1;
      } else if (T2 < param.delay) {
        dT = T2 - param.delay;
      }

      if (dT != cast(T) 0) {
        auto Tp = &abc.sliceof[mid];
        auto dTp = &shift.sliceof[mid];

        *Tp -= dT;
        *dTp += dT;
      }

      return iab;
    }
  }
}

/// Test phase-shift correction
nothrow @nogc unittest {
  import uctl: mk;
  import Osc = uctl.util.osc;
  import uctl.unit: rev;
  import uctl.modul: svm;
  import uctl.math: sin;

  enum auto dt = 1e-4;
  alias sine = sin!5;

  immutable auto osc_param = mk!(Osc.Param, rev, dt)(30.0.as!Hz);
  auto osc_state = Osc.State!(osc_param, double)();

  immutable auto param = mk!Param(16.0.as!usec, 100.0.as!Hz);
  auto state = State!(param, double[3])();

  auto abc = svm!(sine, [3])(osc_state(osc_param));

  assert_eq(abc[0], -0.875447009270978738);
  assert_eq(abc[1], 0.837775971910550199);
  assert_eq(abc[2], 0.875447009270978738);

  auto iab = state(param, abc);

  assert_eq(abc[0], 0.0);
  assert_eq(abc[1], 0.837775971910550199);
  assert_eq(abc[2], 0.875447009270978738);

  assert_eq(iab[0], 2);
  assert_eq(iab[1], 0);

  abc = svm!sine(osc_state(osc_param));

  assert_eq(abc[0], -0.884384800904018498);
  assert_eq(abc[1], 0.809055984513465498);
  assert_eq(abc[2], 0.884384800904018498);

  iab = state(param, abc);

  assert_eq(abc[0], 0.0);
  assert_eq(abc[1], 0.809055984513465498);
  assert_eq(abc[2], 0.884384800904018498);

  assert_eq(iab[0], 2);
  assert_eq(iab[1], 0);
}
