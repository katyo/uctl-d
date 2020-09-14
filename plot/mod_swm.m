dt = 0.0001; # delta time
tend = 0.05; # end time
freq = 50.0; # frequency

data = str2num(eval_d(fileread('mod_swm.d'),
                      'dt', dt,
                      'tend', tend,
                      'freq', freq));

t = data(:,1);
p = data(:,2);
a = data(:,3);

subplot(3,1,1);
plot(t, p, '-;phase;',
     t, a, '-;channel a;');
xlabel("t, S");

t = data(:,1);
p = data(:,2);
a = data(:,4);
b = data(:,5);

subplot(3,1,2);
plot(t, p, '-;phase;',
     t, a, '-;channel a;',
     t, b, '-;channel b;');
xlabel("t, S");

t = data(:,1);
p = data(:,2);
a = data(:,6);
b = data(:,7);
c = data(:,8);

subplot(3,1,3);
plot(t, p, '-;phase;',
     t, a, '-;channel a;',
     t, b, '-;channel b;',
     t, c, '-;channel c;');
xlabel("t, S");

print -dsvg -color '-S640,800' mod_swm.svg
