dt = 1.0; # delta time
tend = 500.0; # end time

Tenv = 25.0;

data = str2num(eval_d('import uctl.simul.htr;', "\n",
                      'enum real dt = ', dt, ';', "\n",
                      'enum float tend = ', tend, ';', "\n",
                      'enum float Tenv = ', Tenv, ';', "\n",
                      'immutable auto htr_param = mk!Param(990.0f, 6.75e-3f, 8.4f, Tenv, dt);', "\n",
                      'auto htr_state = State!(typeof(htr_param), float)(Tenv);', "\n",
                      'foreach (i; 0 .. cast(int)(tend/dt)) {', "\n",
                      '  float t = i * dt;', "\n",
                      '  float Pwr = t < 100 ? 18 : t < 200 ? 26 : t < 300 ? 40 : 0;', "\n",
                      '  float Thtr = htr_state.apply(htr_param, Pwr);', "\n",
                      '  printf("%f %f %f\n", t, Thtr, Pwr);', "\n",
                      '}', "\n"));

t = data(:,1);
T = data(:,2);
P = data(:,3);

subplot(2,1,1);
plot(t, P, '-;Power;');
xlabel("t, S");
ylabel("P, W");

subplot(2,1,2);
plot(t, T, "-;Temperature;");
xlabel("t, S");
ylabel("T, *C");

print -dsvg -color '-S640,400' sim_htr.svg
