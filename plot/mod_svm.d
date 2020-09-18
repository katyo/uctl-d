import uctl.util.osc: Param, State;
import uctl.modul: svm, swm;
import uctl.math: sin;
import uctl.unit: as, Hz, rev;
import uctl: mk;

alias sine = sin!5;

nothrow @nogc void entry() {
  auto param = mk!(Param, rev, dt)(float(freq).as!Hz);
  auto state = State!(param, float)();

  foreach (i; 0 .. cast(int)(tend/dt)) {
    float t = i * dt;
    auto phase = state(param);
    auto output1 = svm!(sine, [3])(phase);
    auto output2 = swm!(sine, [3])(phase);

    printf("%f %f %f %f %f %f %f %f\n", t, phase.raw, output1[0], output1[1], output1[2], output2[0], output2[1], output2[2]);
  }
}
