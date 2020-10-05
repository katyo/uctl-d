import uctl.util: OSC;
import uctl.modul: swm;
import uctl.math.trig: sin;
import uctl.unit: as, Hz, rev, sec;
import uctl: mk;

alias sine = sin!5;
enum dts = dt.as!sec;

private nothrow @nogc void entry() {
  immutable param = mk!(OSC.Param, rev, dts)(float(freq).as!Hz);
  auto state = OSC.State!(param, float)();

  foreach (i; 0 .. cast(int)(tend/dt)) {
    immutable float t = i * dt;
    immutable auto phase = state(param);

    immutable auto a = swm!(sine, [1])(phase);
    immutable auto ab = swm!(sine, [2])(phase);
    immutable auto abc = swm!(sine, [3])(phase);

    printf("%f %f %f %f %f %f %f %f\n", t, phase.raw, a[0], ab[0], ab[1], abc[0], abc[1], abc[2]);
  }
}
