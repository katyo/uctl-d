import uctl: mk;

import uctl.simul: HTR;
import uctl.regul: PID;
import uctl.util: clamp;

nothrow @nogc void entry() {
  // heater perameters (FDM-printer hotend)
  immutable auto htr_param = mk!(HTR.Param, dt)(990.0f, 6.75e-3f, 8.4f);

  // PID controller parmeters
  immutable auto pid_param = mk!(PID.CoupleP!(PID.PO))(0.5f).with_I!(dt, float)(0.005f).with_D!dt(0.75f);

  // constant power heating state
  auto htr_state = HTR.State!(htr_param, float)(Tenv);
  float Pwr = Pset;

  // PID-controller state
  auto pid_state = PID.State!(pid_param, float)();
  // PID-controlled heating state
  auto htr_state_pid = HTR.State!(htr_param, float)(Tenv);

  // PID-controlled heater temperature
  float Thtr_pid = Tenv;

  foreach (i; 0 .. cast(int)(tend/dt)) {
    float t = i * dt;

    // constant power heating
    float Thtr = htr_state(htr_param, Pwr, Tenv);

    // PID-control
    float Pwr_pid = pid_state(pid_param, Ttgt - Thtr_pid).clamp!(0.0, Pmax);
    // PID-conttolled heating
    Thtr_pid = htr_state_pid(htr_param, Pwr_pid, Tenv);

    printf("%f %f %f %f\n", t, Thtr, Thtr_pid, Pwr_pid);
  }
}
