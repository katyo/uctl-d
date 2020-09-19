import uctl.simul: DCM;
import uctl: mk;

nothrow @nogc void entry() {
  immutable auto mot_param = mk!(DCM.Param, dt)(124e-3f, 42e-6f, 8.5e-3f, 8.71e-6f);
  auto mot_state = DCM.State!(mot_param, float, float)();

  foreach (i; 0 .. cast(int)(tend / dt)) {
    float t = i * dt;
    float Ur = t >= 0.15 && t < 0.35 ? 13.56 : t < 0.5 ? 12.0 : 0.0;
    float Tl = t >= 0.1 && t < 0.3 ? 124e-3 : 13.6e-3;

    mot_state(mot_param, Ur, Tl);
    printf("%f %f %f %f %f\n", t, Ur, Tl, mot_state.wr, mot_state.Ir);
  }
}
