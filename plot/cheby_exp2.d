import uctl.math;
import std.math: exp2;

private nothrow @nogc void entry() {
  alias xexp2 = mk!(Cheby, exp2, a, b, order, double);

  enum step = (b - a) / size;
  static foreach (i; 0 .. size+1) {
    {
      enum x = step * i + a;
      enum y = xexp2(x);
      enum yr = exp2(x);
      printf("%g %g %g\n", x, y, yr);
    }
  }
}
