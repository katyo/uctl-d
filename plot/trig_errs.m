size = 100;

orders = [2 3 4 5];

cols = 2;
rows = length(orders);
place = [1 3 5 7
         2 4 6 8];

for i = 1:length(orders)
  order = orders(i);
  data = str2num(eval_d(fileread('trig_errs.d'),
                        'uint size', size,
                        'uint order', order));
  x = data(:,1);
  y = data(:,2);
  yr = data(:,3);
  e = y - yr;

  subplot(rows, cols, place(1, i));
  plot(x, y, '-; approx.;',
       x, yr, '-; refer.;');
  axis([0, pi/2]);
  title(['Polynomial ' int2str(order) '-order sinus']);

  subplot(rows, cols, place(2, i));
  plot(x, e);
  axis([0, pi/2]);
  title(['Error for ' int2str(order) '-order sinus']);
endfor

print -dsvg -color '-S640,1280' trig_errs.svg
