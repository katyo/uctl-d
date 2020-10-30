import std.traits: Unqual;
import uctl: mk, as, sec, J_degK, g, degK_W, W, degC, clamp;
import uctl.simul: HTR;
import uctl.regul: PID;

private nothrow @nogc void entry() {
  enum s = dt.as!sec;

  // heater perameters (FDM-printer hotend)
  immutable auto htr_param = mk!(HTR.Param, s)(990.0f.as!J_degK, 6.75f.as!g, 8.4f.as!degK_W);

  // PID controller parmeters
  immutable auto pid_param = mk!(PID.CoupleP!(PID.PO))(0.5f).with_I!(dt, float)(0.005f).with_D!dt(0.75f);

  const Tenv_C = float(Tenv).as!degC;

  // constant power heating state
  auto htr_state = mk!htr_param(Tenv_C);
  immutable float Pwr = Pset;
  immutable Pwr_W = Pwr.as!W;

  // PID-controller state
  auto pid_state = PID.State!(pid_param, float)();
  // PID-controlled heating state
  auto htr_state_pid = mk!htr_param(Tenv_C);

  // PID-controlled heater temperature
  Unqual!(typeof(Tenv_C)) Thtr_pid_C = Tenv_C;

  foreach (i; 0 .. cast(int)(tend/dt)) {
    immutable float t = i * dt;

    // constant power heating
    immutable Thtr_C = htr_state(htr_param, Pwr_W, Tenv_C);

    // PID-control
    immutable float Pwr_pid = pid_state(pid_param, Ttgt - Thtr_pid_C.raw).clamp!(0.0, Pmax);
    // PID-conttolled heating
    Thtr_pid_C = htr_state_pid(htr_param, Pwr_pid.as!W, Tenv_C);

    printf("%f %f %f %f\n", t, Thtr_C.raw, Thtr_pid_C.raw, Pwr_pid);
  }
}
