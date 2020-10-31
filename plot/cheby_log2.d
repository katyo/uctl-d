import uctl.math;
import std.math: log2;

private nothrow @nogc void entry() {
  alias xlog2 = mk!(Cheby, log2, a, b, order, double);

  enum step = (b - a) / size;
  static foreach (i; 0 .. size+1) {
    {
      enum x = step * i + a;
      enum y = xlog2(x);
      enum yr = cast(double) log2(x);
      printf("%g %g %g\n", x, y, yr);
    }
  }
}
