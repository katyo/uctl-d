import std.array: staticArray;
import uctl.filt;

private nothrow @nogc void entry() {
  immutable auto p1 = mk!(EMA.Alpha)(0.9);
  auto s1 = EMA.State!(p1, float)();

  immutable auto p2 = mk!(EMA.Alpha)(0.6);
  auto s2 = EMA.State!(p2, float)();

  immutable auto p3 = mk!(EMA.Alpha)(0.3);
  auto s3 = EMA.State!(p3, float)();

  immutable auto p4 = mk!(EMA.Samples)(1.0);
  auto s4 = EMA.State!(p4, float)();

  immutable auto p5 = mk!(EMA.Samples)(3.0);
  auto s5 = EMA.State!(p5, float)();

  immutable auto p6 = mk!(EMA.Samples)(7.0);
  auto s6 = EMA.State!(p6, float)();

  immutable auto p7 = mk!(EMA.Time, dt)(0.02);
  auto s7 = EMA.State!(p7, float)();

  immutable auto p8 = mk!(EMA.Time, dt)(0.05);
  auto s8 = EMA.State!(p8, float)();

  immutable auto p9 = mk!(EMA.Time, dt)(0.1);
  auto s9 = EMA.State!(p9, float)();

  immutable auto p10 = mk!(EMA.PT1, dt)(0.01);
  auto s10 = EMA.State!(p10, float)();

  immutable auto p11 = mk!(EMA.PT1, dt)(0.03);
  auto s11 = EMA.State!(p11, float)();

  immutable auto p12 = mk!(EMA.PT1, dt)(0.06);
  auto s12 = EMA.State!(p12, float)();

  foreach (i; 0 .. data.length) {
    auto t = dt * i;
    auto x = data[i];

    printf("%f %f " ~
           "%f %f %f " ~
           "%f %f %f " ~
           "%f %f %f " ~
           "%f %f %f\n",
           t, x,
           s1(p1, x), s2(p2, x), s3(p3, x),
           s4(p4, x), s5(p5, x), s6(p6, x),
           s7(p7, x), s8(p8, x), s9(p9, x),
           s10(p10, x), s11(p11, x), s12(p12, x));
  }
}
