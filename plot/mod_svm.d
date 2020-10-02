import uctl.util: OSC;
import uctl.modul: svm, swm;
import uctl.math: sin;
import uctl.unit: as, Hz, rev;
import uctl: mk;

alias sine = sin!5;

private nothrow @nogc void entry() {
  immutable param = mk!(OSC.Param, rev, dt)(freq.as!Hz);
  auto state = OSC.State!(param, float)();

  foreach (i; 0 .. cast(int)(tend/dt)) {
    immutable float t = i * dt;
    immutable auto phase = state(param);
    immutable auto abc1 = svm!(sine, [3])(phase);
    immutable auto abc2 = swm!(sine, [3])(phase);

    printf("%f %f %f %f %f %f %f %f\n", t, phase.raw, abc1[0], abc1[1], abc1[2], abc2[0], abc2[1], abc2[2]);
  }
}
