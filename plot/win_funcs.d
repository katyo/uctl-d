import uctl.util;

private nothrow @nogc void entry() {
  static immutable win = func!(size, double);

  foreach (i; 0 .. size+1) {
    immutable auto x = cast(double)i / cast(double)size;
    immutable auto y = win[i];
    printf("%g %g\n", x, y);
  }
}
