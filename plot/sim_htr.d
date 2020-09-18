import uctl: mk;
import Htr = uctl.simul.htr;

nothrow @nogc void entry() {
  immutable auto htr_param = mk!(Htr.Param, dt)(990.0f, 6.75e-3f, 8.4f);
  auto htr_state = Htr.State!(htr_param, float)(Tenv);

  foreach (i; 0 .. cast(int)(tend/dt)) {
    float t = i * dt;
    float Pwr = t < 100 ? 18 : t < 200 ? 26 : t < 300 ? 40 : 0;

    float Thtr = htr_state(htr_param, Pwr, Tenv);

    printf("%f %f %f %f\n", t, Pwr, Thtr, float(Tenv));
  }
}
