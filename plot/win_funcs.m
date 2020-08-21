size = 100;

funcs = {'dirichlet'
         'bartlett'
         'bartlett_hann'
         'parzen'
         'welch'
         'sine'
         'hann'
         'hamming'
         'blackman'
         'nuttall'
         'blackman_nuttall'
         'blackman_harris'
         'flat_top'
         'rife_vincent1'
         'rife_vincent2'
         'lanczos'};

cols = 5;
rows = ceil(length(funcs) / cols);

for i = 1:length(funcs)
  func = funcs{i};
  data = str2num(eval_d('import uctl.util.win;',
                        'enum uint N = ', size, ';',
                        'static immutable w = ', func, '!(N, double);',
                        'foreach (i; 0 .. N+1) {',
                        '  printf("%g %g\n", cast(double)i / cast(double)N, w[i]);',
                        '}'));
  x = data(:,1);
  y = data(:,2);

  subplot(rows, cols, i);
  plot(x, y);
  axis("labely");
  ##set(gca, 'xticklabel', []);
  ##set(gca, 'xtick', []);
  title(strrep(func, '_', '-'));
endfor

print -dsvg -color '-S640,480' win_funcs.svg
