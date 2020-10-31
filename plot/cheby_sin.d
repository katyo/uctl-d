import uctl.math;
import std.math: sin, PI;

private nothrow @nogc void entry() {
  alias xsin = mk!(Cheby, sin, a, b, order, double);

  enum double step = (b - a) / size;
  foreach (i; 0 .. size + 1) {
    immutable x = step * i + a;
    immutable y = xsin(x);
    immutable yr = sin(x);
    printf("%g %g %g\n", x, y, yr);
  }
}
