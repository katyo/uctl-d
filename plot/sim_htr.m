dt = 1.0; # delta time
tend = 500.0; # end time

Tenv = 25.0;

data = str2num(eval_d(fileread('sim_htr.d'),
                      'dt', dt,
                      'tend', tend,
                      'Tenv', Tenv));

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
