dt = 0.0001; # delta time
tend = 0.05; # end time
freq = 50.0; # frequency

data = str2num(eval_d('import uctl.util.osc: Param, State;', "\n",
                      'import uctl.modul.swm: swm;', "\n",
                      'import uctl.math.trig: sin;', "\n",
                      'import uctl.unit: as, Hz, rev;', "\n",
                      'import uctl: mk;', "\n",
                      'alias sine = sin!5;', "\n",
                      'enum real dt = ', dt, ';', "\n",
                      'enum float tend = ', tend, ';', "\n",
                      'enum float freq = ', freq, ';', "\n",
                      'auto param = mk!(Param, rev, dt)(freq.as!Hz);', "\n",
                      'auto state = State!(param, float)();', "\n",
                      'foreach (i; 0 .. cast(int)(tend/dt)) {', "\n",
                      '  float t = i * dt;', "\n",
                      '  auto phase = state.apply(param);', "\n",
                      '  auto output = swm!(sine, [1])(phase);', "\n",
                      '  printf("%f %f %f\n", t, phase.raw, output[0]);', "\n",
                      '}', "\n"));

t = data(:,1);
p = data(:,2);
a = data(:,3);

subplot(3,1,1);
plot(t, p, '-;phase;',
     t, a, '-;channel a;');
xlabel("t, S");

data = str2num(eval_d('import uctl.util.osc: Param, State;', "\n",
                      'import uctl.modul.swm: swm;', "\n",
                      'import uctl.math.trig: sin;', "\n",
                      'import uctl.unit: as, Hz, rev;', "\n",
                      'import uctl: mk;', "\n",
                      'alias sine = sin!5;', "\n",
                      'enum real dt = ', dt, ';', "\n",
                      'enum float tend = ', tend, ';', "\n",
                      'enum float freq = ', freq, ';', "\n",
                      'auto param = mk!(Param, rev, dt)(freq.as!Hz);', "\n",
                      'auto state = State!(param, float)();', "\n",
                      'foreach (i; 0 .. cast(int)(tend/dt)) {', "\n",
                      '  float t = i * dt;', "\n",
                      '  auto phase = state.apply(param);', "\n",
                      '  auto output = swm!(sine, [2])(phase);', "\n",
                      '  printf("%f %f %f %f\n", t, phase.raw, output[0], output[1]);', "\n",
                      '}', "\n"));

t = data(:,1);
p = data(:,2);
a = data(:,3);
b = data(:,4);

subplot(3,1,2);
plot(t, p, '-;phase;',
     t, a, '-;channel a;',
     t, b, '-;channel b;');
xlabel("t, S");

data = str2num(eval_d('import uctl.util.osc: Param, State;', "\n",
                      'import uctl.modul.swm: swm;', "\n",
                      'import uctl.math.trig: sin;', "\n",
                      'import uctl.unit: as, Hz, rev;', "\n",
                      'import uctl: mk;', "\n",
                      'alias sine = sin!5;', "\n",
                      'enum real dt = ', dt, ';', "\n",
                      'enum float tend = ', tend, ';', "\n",
                      'enum float freq = ', freq, ';', "\n",
                      'auto param = mk!(Param, rev, dt)(freq.as!Hz);', "\n",
                      'auto state = State!(param, float)();', "\n",
                      'foreach (i; 0 .. cast(int)(tend/dt)) {', "\n",
                      '  float t = i * dt;', "\n",
                      '  auto phase = state.apply(param);', "\n",
                      '  auto output = swm!(sine, [3])(phase);', "\n",
                      '  printf("%f %f %f %f %f\n", t, phase.raw, output[0], output[1], output[2]);', "\n",
                      '}', "\n"));

t = data(:,1);
p = data(:,2);
a = data(:,3);
b = data(:,4);
c = data(:,5);

subplot(3,1,3);
plot(t, p, '-;phase;',
     t, a, '-;channel a;',
     t, b, '-;channel b;',
     t, c, '-;channel c;');
xlabel("t, S");

print -dsvg -color '-S640,800' mod_swm.svg
