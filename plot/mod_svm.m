dt = 0.0001; # delta time
tend = 0.05; # end time
freq = 50.0; # frequency

data = str2num(eval_d('import uctl.util.osc: Param, State;', "\n",
                      'import uctl.modul.svm: svm;', "\n",
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
                      '  auto output = svm!(sine, [3])(phase);', "\n",
                      '  printf("%f %f %f %f %f\n", t, phase.raw, output[0], output[1], output[2]);', "\n",
                      '}', "\n"));

t1 = data(:,1);
p1 = data(:,2);
a1 = data(:,3);
b1 = data(:,4);
c1 = data(:,5);
v1 = max(a1, max(b1, c1)) .- min(a1, min(b1, c1));
w1 = v1 .^ 2;

subplot(3,1,1);
plot(t1, p1, '-;phase;',
     t1, a1, '-;channel a;',
     t1, b1, '-;channel b;',
     t1, c1, '-;channel c;');
xlabel("t, S");
ylabel("U, V");
title("Space-vector modulation");

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

t2 = data(:,1);
p2 = data(:,2);
a2 = data(:,3);
b2 = data(:,4);
c2 = data(:,5);
v2 = max(a2, max(b2, c2)) .- min(a2, min(b2, c2));
w2 = v2 .^ 2;

subplot(3,1,2);
plot(t2, p2, '-;phase;',
     t2, a2, '-;channel a;',
     t2, b2, '-;channel b;',
     t2, c2, '-;channel c;');
xlabel("t, S");
ylabel("U, V");
title("Sine-wave modulation");

subplot(3,1,3);
plot(t1, p1, '-;phase;',
     t1, w1, '-;SVM;',
     t2, w2, '-;SINE;');
xlabel("t, S");
ylabel("P, W");
title("Amount power of machine");

print -dsvg -color '-S640,800' mod_svm.svg
