import std.array: staticArray;
import uctl.filt;

nothrow @nogc
void entry() {
  immutable auto p1 = mk!EmaAlpha(0.9);
  auto s1 = EmaState!(p1, float)();

  immutable auto p2 = mk!EmaAlpha(0.6);
  auto s2 = EmaState!(p2, float)();

  immutable auto p3 = mk!EmaAlpha(0.3);
  auto s3 = EmaState!(p3, float)();

  immutable auto p4 = mk!EmaSamples(1.0);
  auto s4 = EmaState!(p4, float)();

  immutable auto p5 = mk!EmaSamples(3.0);
  auto s5 = EmaState!(p5, float)();

  immutable auto p6 = mk!EmaSamples(7.0);
  auto s6 = EmaState!(p6, float)();

  immutable auto p7 = mk!(EmaTime, dt)(0.02);
  auto s7 = EmaState!(p7, float)();

  immutable auto p8 = mk!(EmaTime, dt)(0.05);
  auto s8 = EmaState!(p8, float)();

  immutable auto p9 = mk!(EmaTime, dt)(0.1);
  auto s9 = EmaState!(p9, float)();

  immutable auto p10 = mk!(EmaPT1, dt)(0.01);
  auto s10 = EmaState!(p10, float)();

  immutable auto p11 = mk!(EmaPT1, dt)(0.03);
  auto s11 = EmaState!(p11, float)();

  immutable auto p12 = mk!(EmaPT1, dt)(0.06);
  auto s12 = EmaState!(p12, float)();

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
