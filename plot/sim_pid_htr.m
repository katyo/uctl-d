dt = 10.0; # delta time
tend = 400.0; # end time

Tenv = 25.0;
Pmax = 40.0;
Pset = 26.0;
Ttgt = 240.0;

data = str2num(eval_d('import uctl.simul.htr: mk, HtrParam = Param, HtrState = State;', "\n",
                      'enum real dt = ', dt, ';', "\n",
                      'enum float tend = ', tend, ';', "\n",
                      'enum float Tenv = ', Tenv, ';', "\n",
                      'enum float Pwr = ', Pset, ';', "\n",
                      'immutable auto htr_param = mk!(HtrParam, dt)(990.0f, 6.75e-3f, 8.4f);', "\n",
                      'auto htr_state = HtrState!(typeof(htr_param), float)(Tenv);', "\n",
                      'foreach (i; 0 .. cast(int)(tend/dt)) {', "\n",
                      '  float Thtr = htr_state.apply(htr_param, Pwr, Tenv);', "\n",
                      '  float t = i * dt;', "\n",
                      '  printf("%f %f %f\n", t, Thtr, Pwr);', "\n",
                      '}', "\n"));

t = data(:,1);
Tcp = data(:,2);
Pcp = data(:,3);

data = str2num(eval_d('import uctl.regul.pid: mk, PO, CoupleP, PidParam = Param, PidState = State;', "\n",
                      'import uctl.simul.htr: mkHtr = mk, HtrParam = Param, HtrState = State;', "\n",
                      'import uctl.util.val: clamp;', "\n",
                      'enum real dt = ', dt, ';', "\n",
                      'enum float tend = ', tend, ';', "\n",
                      'enum float Tenv = ', Tenv, ';', "\n",
                      'enum float Ttgt = ', Ttgt, ';', "\n",
                      'enum float Pmax = ', Pmax, ';', "\n",
                      'immutable auto pid_param = mk!(CoupleP!PO)(0.5f).with_I!(dt, float)(0.005f).with_D!dt(0.75f);', "\n",
                      'immutable auto htr_param = mkHtr!(HtrParam, dt)(990.0f, 6.75e-3f, 8.4f);', "\n",
                      'auto pid_state = PidState!(typeof(pid_param), float)();', "\n",
                      'auto htr_state = HtrState!(typeof(htr_param), float)(Tenv);', "\n",
                      'auto Thtr = Tenv;', "\n",
                      'foreach (i; 0 .. cast(int)(tend/dt)) {', "\n",
                      '  float Pwr = pid_state.apply(pid_param, Ttgt - Thtr).clamp(0.0, Pmax);', "\n",
                      '  Thtr = htr_state.apply(htr_param, Pwr, Tenv);', "\n",
                      '  float t = i * dt;', "\n",
                      '  printf("%f %f %f %f\n", t, Thtr, Pwr, Ttgt);', "\n",
                      '}', "\n"));

Tpid = data(:,2);
Ppid = data(:,3);
Tpid_target = data(:,4);
Tpid_error = Tpid_target - Tpid;

subplot(1,2,1);
plot(t, Tcp, "-;Tcp;",
     t, Tpid, "-;Tpid;");
xlabel("t, S");
ylabel("T, *C");
title("Constant power vs PID controlled heating");

subplot(2,2,2);
plot(t, Pcp, '-;Pcp;',
     t, Ppid, '-;Ppid;');
xlabel("t, S");
ylabel("P, W");

subplot(2,2,4);
plot(t, Tpid_error, '-;Tpid error;');
xlabel("t, S");
ylabel("T error, *C");

print -dsvg -color '-S640,400' sim_pid_htr.svg
