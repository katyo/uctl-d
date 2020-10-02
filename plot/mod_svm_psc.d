import uctl.util: OSC;
import uctl.modul: svm, PSC;
import uctl.math: sin;
import uctl.unit: as, sec, Hz, qrev;
import uctl.util: scale;
import uctl: mk;

alias sine = sin!5;

private nothrow @nogc void entry() {
  immutable osc_param = mk!(OSC.Param, qrev, dt)(freq.as!Hz);
  auto osc_state = OSC.State!(osc_param, float)();

  immutable auto psc_param = mk!(PSC.Param)(tcrit.as!sec, mfreq.as!Hz);
  auto psc_state = PSC.State!(psc_param, float[3])();

  uint[2] iab;

  foreach (i; 0 .. cast(int)(tend/dt)) {
    immutable float t = i * dt;
    immutable auto phase = osc_state(osc_param);
    immutable auto abc = svm!(sine, [3])(phase);

    printf("%f %f %f %f %f ", t, phase.raw * 0.5, abc[0], abc[1], abc[2]);

    auto abc2 = abc.scale!(-1.0, 1.0, 0.0, 1.0);
    if ((i & 1) == 0) {
      iab = psc_state(psc_param, abc2);
    } else {
      psc_state.opCall!void(psc_param, abc2);
    }

    immutable auto abc3 = abc2.scale!(0.0, 1.0, -1.0, 1.0);

    printf("%u %u %f %f %f\n", iab[0], iab[1], abc3[0], abc3[1], abc3[2]);
  }
}
