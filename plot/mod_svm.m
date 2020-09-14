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
v1 = max(a1, max(b1, c1)) .- min(a1, min(b1, c1));
w1 = v1 .^ 2;

subplot(3,1,1);
plot(t, p, '-;phase;',
     t, a1, '-;channel a;',
     t, b1, '-;channel b;',
     t, c1, '-;channel c;');
xlabel("t, S");
ylabel("U, V");
title("Space-vector modulation");

a2 = data(:,6);
b2 = data(:,7);
c2 = data(:,8);
v2 = max(a2, max(b2, c2)) .- min(a2, min(b2, c2));
w2 = v2 .^ 2;

subplot(3,1,2);
plot(t, p, '-;phase;',
     t, a2, '-;channel a;',
     t, b2, '-;channel b;',
     t, c2, '-;channel c;');
xlabel("t, S");
ylabel("U, V");
title("Sine-wave modulation");

subplot(3,1,3);
plot(t, p, '-;phase;',
     t, w1, '-;SVM;',
     t, w2, '-;SINE;');
xlabel("t, S");
ylabel("P, W");
title("Amount power of machine");

print -dsvg -color '-S640,800' mod_svm.svg
