dt = 10.0; # delta time
tend = 400.0; # end time

Tenv = 25.0;
Pmax = 40.0;
Pset = 26.0;
Ttgt = 240.0;

data = str2num(eval_d(fileread('sim_pid_htr.d'),
                      'dt', dt,
                      'tend', tend,
                      'Tenv', Tenv,
                      'Ttgt', Ttgt,
                      'Pset', Pset,
                      'Pmax', Pmax));
len = length(data);

t = data(:,1);
Tcp = data(:,2);
Pcp = ones(len, 1) * Pset;
Tpid = data(:,3);
Ppid = data(:,4);

Tpid_target = ones(len, 1) * Ttgt;
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
ylabel("T, *C");

print -dsvg -color '-S640,400' sim_pid_htr.svg
