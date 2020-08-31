dt = 1.0; # delta time
tend = 500.0; # end time

Tenv = 25.0;

data = str2num(eval_d('import uctl.simul.htr;', "\n",
                      'enum real dt = ', dt, ';', "\n",
                      'enum float tend = ', tend, ';', "\n",
                      'enum float Tenv = ', Tenv, ';', "\n",
                      'immutable auto htr_param = mk!(Param, dt)(990.0f, 6.75e-3f, 8.4f);', "\n",
                      'auto htr_state = State!(htr_param, float)(Tenv);', "\n",
                      'foreach (i; 0 .. cast(int)(tend/dt)) {', "\n",
                      '  float t = i * dt;', "\n",
                      '  float Pwr = t < 100 ? 18 : t < 200 ? 26 : t < 300 ? 40 : 0;', "\n",
                      '  float Thtr = htr_state.apply(htr_param, Pwr, Tenv);', "\n",
                      '  printf("%f %f %f %f\n", t, Pwr, Thtr, Tenv);', "\n",
                      '}', "\n"));

t = data(:,1);
Phtr = data(:,2);
Thtr = data(:,3);
Tenv = data(:,4);

subplot(2,1,1);
plot(t, Phtr, '-;Applied power;');
xlabel("t, S");
ylabel("P, W");

subplot(2,1,2);
plot(t, Thtr, '-;Heater temp.;',
     t, Tenv, '-;Environ. temp.;');
xlabel("t, S");
ylabel("T, *C");

print -dsvg -color '-S640,400' sim_htr.svg
