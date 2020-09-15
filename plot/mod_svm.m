dt = 0.0001; # delta time
tend = 0.05; # end time
freq = 50.0; # frequency

data = str2num(eval_d(fileread('mod_svm.d'),
                      'dt', dt,
                      'tend', tend,
                      'freq', freq));

t = data(:,1);
p = data(:,2);

a1 = data(:,3);
b1 = data(:,4);
c1 = data(:,5);
ab1 = b1 - a1;
bc1 = c1 - b1;
ca1 = a1 - c1;
w1 = (ab1 .^ 2 + bc1 .^ 2 + ca1 .^ 2) / 3;

subplot(2,1,1);
plot(t, p, ':;phase;',
     t, a1, '-;Va;',
     t, b1, '-;Vb;',
     t, c1, '-;Vc;',
     t, ab1, '--;Vab;',
     t, bc1, '--;Vbc;',
     t, ca1, '--;Vca;',
     t, w1, '-.;P, W;', 'linewidth', 1.5);
xlabel("t, S");
ylabel("U, V");
title("Space-vector modulation");

a2 = data(:,6);
b2 = data(:,7);
c2 = data(:,8);
ab2 = b2 - a2;
bc2 = c2 - b2;
ca2 = a2 - c2;
w2 = (ab2 .^ 2 + bc2 .^ 2 + ca2 .^ 2) / 3;

subplot(2,1,2);
plot(t, p, ':;phase;',
     t, a2, '-;Va;',
     t, b2, '-;Vb;',
     t, c2, '-;Vc;',
     t, ab2, '--;Vab;',
     t, bc2, '--;Vbc;',
     t, ca2, '--;Vca;',
     t, w2, '-.;P, W;', 'linewidth', 1.5);
xlabel("t, S");
ylabel("U, V");
title("Sine-wave modulation");

print -dsvg -color '-S640,600' mod_svm.svg
