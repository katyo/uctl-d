import uctl.math;
import std.math: sqrt;

private nothrow @nogc void entry() {
  alias xsqrt = mk!(Cheby, sqrt, a, b, order, double);

  enum step = (b - a) / size;
  static foreach (i; 0 .. size+1) {
    {
      enum x = step * i + a;
      enum y = xsqrt(x);
      enum yr = sqrt(x);
      printf("%g %g %g\n", x, y, yr);
    }
  }
}
