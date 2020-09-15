dt = 0.0002; # delta time
tend = 0.05; # end time
freq = 50.0; # frequency

data = str2num(eval_d(fileread('mod_swm.d'),
                      'dt', dt,
                      'tend', tend,
                      'freq', freq));

t = data(:,1);
p = data(:,2);
a = data(:,3);
w = a .^ 2;

subplot(3,1,1);
plot(t, p, ':;phase;',
     t, a, '-;Va;',
     t, w, '-.;P, W;', 'linewidth', 1.5);
xlabel("t, S");
ylabel("U, V");
title("One phase");

t = data(:,1);
p = data(:,2);
a = data(:,4);
b = data(:,5);
ab = b - a;
w = ab .^ 2 / 2;

subplot(3,1,2);
plot(t, p, ':;phase;',
     t, a, '-;Va;',
     t, b, '-;Vb;',
     t, ab, '--;Vab;',
     t, w, '-.;P, W;', 'linewidth', 1.5);
xlabel("t, S");
ylabel("U, V");
title("Two phase");

t = data(:,1);
p = data(:,2);
a = data(:,6);
b = data(:,7);
c = data(:,8);
ab = b - a;
bc = c - b;
ca = a - c;
w = (ab .^ 2 + bc .^ 2 + ca .^ 2) / 3;

subplot(3,1,3);
plot(t, p, ':;phase;',
     t, a, '-;Va;',
     t, b, '-;Vb;',
     t, c, '-;Vc;',
     t, ab, '--;Vab;',
     t, bc, '--;Vbc;',
     t, ca, '--;Vca;',
     t, w, '-.;P, W;', 'linewidth', 1.5);
xlabel("t, S");
ylabel("U, V");
title("Three phase");

print -dsvg -color '-S640,600' mod_swm.svg
