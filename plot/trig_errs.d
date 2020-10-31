import uctl.math;
import uctl.unit;
import std.math: PI;

private nothrow @nogc void entry() {
  enum double step = (b - a) / size;
  foreach (i; 0 .. size+1) {
    immutable auto x = (step * i + a).as!rad;
    immutable auto y = sin!order(x);
    immutable auto yr = sin(x);
    printf("%g %g %g\n", x.raw, y, yr);
  }
}
