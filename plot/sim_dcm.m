dt = 10e-6;
tend = 0.7;

data = str2num(eval_d('import uctl.simul.dcm;', "\n",
                      'enum auto dt = ', dt, ';', "\n",
                      'enum auto tend = ', tend, ';', "\n",
                      'immutable auto mot_param = mk!(Param, dt)(124e-3f, 42e-6f, 8.5e-3f, 8.71e-6f);', "\n",
                      'auto mot_state = State!(mot_param, float, float)();', "\n",
                      'foreach (i; 0 .. cast(int)(tend / dt)) {', "\n",
                      '  float t = i * dt;', "\n",
                      '  float Ur = t >= 0.15 && t < 0.35 ? 13.56 : t < 0.5 ? 12.0 : 0.0;', "\n",
                      '  float Tl = t >= 0.1 && t < 0.3 ? 124e-3 : 13.6e-3;', "\n",
                      '  mot_state.apply(mot_param, Ur, Tl);', "\n",
                      '  printf("%f %f %f %f %f\n", t, Ur, Tl, mot_state.wr, mot_state.Ir);', "\n",
                      '}', "\n"));

t = data(:,1);
U = data(:,2);
T = data(:,3);
w = data(:,4);
I = data(:,5);

subplot(6,1,1);
plot(t, U);
set(gca, 'ytick', 0:5:15);
##xlabel("t, S");
ylabel("U, V");
##title("Supply voltage");

subplot(6,1,2);
plot(t, T);
set(gca, 'ytick', 0:0.05:0.2);
##xlabel("t, S");
ylabel("T, Nm");
##title("Load torque");

subplot(3,1,2);
plot(t, w*30/pi);
##xlabel("t, S");
ylabel("w, RPM");
##title("Rotation speed");

subplot(3,1,3);
plot(t, I);
xlabel("t, S");
ylabel("I, A");
##title("Supply current");

print -dsvg -color '-S640,700' sim_dcm.svg
