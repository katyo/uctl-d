import uctl: mk, as, sec, J_degK, degK_W, g, degC, W;
import uctl.simul: HTR;

private nothrow @nogc void entry() {
  enum s = dt.as!sec;
  immutable htr_param = mk!(HTR.Param, s)(990.0f.as!J_degK, 6.75f.as!g, 8.4f.as!degK_W);
  const Tenv_C = float(Tenv).as!degC;
  auto htr_state = mk!htr_param(Tenv_C);

  foreach (i; 0 .. cast(int)(tend/dt)) {
    immutable float t = i * dt;
    immutable float Pwr = t < 100 ? 18 : t < 200 ? 26 : t < 300 ? 40 : 0;
    immutable Pwr_W = Pwr.as!W;

    immutable Thtr_C = htr_state(htr_param, Pwr_W, Tenv_C);

    printf("%f %f %f %f\n", t, Pwr_W.raw, Thtr_C.raw, Tenv_C.raw);
  }
}
