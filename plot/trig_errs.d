import uctl.math.trig;
import uctl.unit;
import std.math: PI;

nothrow @nogc void entry() {
  enum double step = PI / (2 * size);
  foreach (i; 0 .. size+1) {
    auto x = (cast(double)i * step).as!rad;
    auto y = sin!order(x);
    auto yr = sin(x);
    printf("%g %g %g\n", x.raw, y, yr);
  }
}
