import uctl.simul: DCM;
import uctl: mk, as, to, sec, mOhm, uH, mWb, gcm2, V, mNm, rad_sec, rev_min;

private nothrow @nogc void entry() {
  enum s = dt.as!sec;
  immutable mot_param = mk!(DCM.Param, s)(124f.as!mOhm, 42f.as!uH, 8.5f.as!mWb, 87.1f.as!gcm2);
  auto mot_state = DCM.State!(mot_param, typeof(0f.as!V), typeof(0f.as!rad_sec))();

  foreach (i; 0 .. cast(int)(tend / dt)) {
    immutable float t = i * dt;
    immutable supply_U = (t >= 0.15 && t < 0.35 ? 13.56 : t < 0.5 ? 12.0 : 0.0).as!V.to!float;
    immutable load_T = (t >= 0.1 && t < 0.3 ? 124.0 : 13.6).as!mNm.to!float;

    mot_state(mot_param, supply_U, load_T);
    printf("%f %f %f %f %f\n", t, supply_U.raw, load_T.raw, mot_state.rotor_W.to!rev_min.raw, mot_state.rotor_I.raw);
  }
}
