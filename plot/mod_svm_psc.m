dt = 100e-6; # delta time
tend = 25e-3; # end time
freq = 50; # frequency
mfreq = 4e3; # PWM frequency
tcrit = 30e-6; # min time for measurement

data = str2num(eval_d(fileread('mod_svm_psc.d'),
                      'dt', dt,
                      'tend', tend,
                      'freq', freq,
                      'mfreq', mfreq,
                      'tcrit', tcrit));

t = data(:,1);
p = data(:,2);

a1 = data(:,3);
b1 = data(:,4);
c1 = data(:,5);

ia = data(:,6);
ib = data(:,7);

a2 = data(:,8);
b2 = data(:,9);
c2 = data(:,10);

ab1 = b1 - a1;
bc1 = c1 - b1;
ca1 = a1 - c1;

ab2 = b2 - a2;
bc2 = c2 - b2;
ca2 = a2 - c2;

subplot(10,1,1:4);
plot(t, p, ':;phase;',
     t, a1, '-;Va;',
     t, b1, '-;Vb;',
     t, c1, '-;Vc;',
     t, ab1, '--;Vab;',
     t, bc1, '--;Vbc;',
     t, ca1, '--;Vca;');
xlabel("t, S");
ylabel("U, V");
title("Before phase correction");

subplot(10,1,5:6);
plot(t, ia, '-;Ia;',
     t, ib, '-;Ib;');
#xlabel("t, S");
title("Switch state");

subplot(10,1,7:10);
plot(t, p, ':;phase;',
     t, a2, '-;Va;',
     t, b2, '-;Vb;',
     t, c2, '-;Vc;',
     t, ab2, '--;Vab;',
     t, bc2, '--;Vbc;',
     t, ca2, '--;Vca;');
xlabel("t, S");
ylabel("U, V");
title("After phase correction");

print -dsvg -color '-S640,600' mod_svm_psc.svg
