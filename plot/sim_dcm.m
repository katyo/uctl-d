dt = 10e-6;
tend = 0.7;

data = str2num(eval_d(fileread('sim_dcm.d'),
                      'dt', dt,
                      'tend', tend));

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
plot(t, w);
##xlabel("t, S");
ylabel("w, RPM");
##title("Rotation speed");

subplot(3,1,3);
plot(t, I);
xlabel("t, S");
ylabel("I, A");
##title("Supply current");

print -dsvg -color '-S640,700' sim_dcm.svg
