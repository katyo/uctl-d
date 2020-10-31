size = 100;
orders = [2 3 4 5];
range = [0 pi/2];

cols = 2;
rows = length(orders);
place = [1 3 5 7
         2 4 6 8];

for i = 1:length(orders)
  order = orders(i);
  data = str2num(eval_d(fileread('cheby_sin.d'),
                        'uint size', size,
                        'uint order', order,
                        'double a', range(1),
                        'double b', range(2)));
  x = data(:,1);
  y = data(:,2);
  yr = data(:,3);
  e = y - yr;

  subplot(rows, cols, place(1, i));
  plot(x, y, '-; approx.;',
       x, yr, '-; refer.;');
  axis(range);
  title(['Polynomial ' int2str(order) '-order sinus']);

  subplot(rows, cols, place(2, i));
  plot(x, e);
  axis(range);
  title(['Error for ' int2str(order) '-order sinus']);
endfor

print -dsvg -color '-S640,800' cheby_sin.svg
