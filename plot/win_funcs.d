import uctl.util.win;

nothrow @nogc void entry() {
  static immutable win = func!(size, double);

  foreach (i; 0 .. size+1) {
    auto x = cast(double)i / cast(double)size;
    auto y = win[i];
    printf("%g %g\n", x, y);
  }
}
