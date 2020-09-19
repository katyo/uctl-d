dt = 1e-2;

data = [
       0.123456
       1.01246
       5.198
       4.0
       2.7643
       -0.0124
       -1.2984
       0.7633
];

data = str2num(eval_d(fileread('filt_ema.d'),
                      'float dt', dt,
                      'float data', data));

t = data(:,1);
x = data(:,2);

yAlpha = data(:,3:5);
ySamples = data(:,6:8);
yTime = data(:,9:11);
yPT1 = data(:,12:14);

subplot(2, 2, 1);
plot(t, x, '*;source;',
     t, yAlpha(:,1), '-;alpha=0.9;',
     t, yAlpha(:,2), '-;alpha=0.6;',
     t, yAlpha(:,3), '-;alpha=0.3;');
#xlabel('T, S');
title('EMA filter using alpha factor');

subplot(2, 2, 2);
plot(t, x, '*;source;',
     t, ySamples(:,1), '-;samples=1;',
     t, ySamples(:,2), '-;samples=3;',
     t, ySamples(:,3), '-;samples=7;');
#xlabel('T, S');
title('EMA filter using number of samples');

subplot(2, 2, 3);
plot(t, x, '*;source;',
     t, yTime(:,1), '-;time=0.02;',
     t, yTime(:,2), '-;time=0.05;',
     t, yTime(:,3), '-;time=0.1;');
#xlabel('T, S');
title('EMA filter using time window');

subplot(2, 2, 4);
plot(t, x, '*;source;',
     t, yPT1(:,1), '-;time=0.01;',
     t, yPT1(:,2), '-;time=0.03;',
     t, yPT1(:,3), '-;time=0.06;');
xlabel('T, S');
title('EMA filter as 1st order aperiodic behavior');

print -dsvg -color '-S640,500' filt_ema.svg
