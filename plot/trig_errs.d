import uctl.math;
import uctl.unit;
import std.math: PI;

private nothrow @nogc void entry() {
  enum double step = PI / (2 * size);
  foreach (i; 0 .. size+1) {
    immutable auto x = (cast(double)i * step).as!rad;
    immutable auto y = sin!order(x);
    immutable auto yr = sin(x);
    printf("%g %g %g\n", x.raw, y, yr);
  }
}
