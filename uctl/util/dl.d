/**
   Simple delay lines
 */
module uctl.util.dl;

version(unittest) {
  import uctl.test: assert_eq, unittests;

  mixin unittests;
}

/**
 Delay line for filters.
 Generic pre-filled delay line of length `L` for values of type `T`.

 Internally the line is a simple ring buffer with constant length.
*/
struct PFDL(uint L, T) {
  /// The type of values
  alias val_t = T;

  /// The length of line
  enum uint len = L;

  /// Index of end value
  private uint end = len - 1;

  /// Line values
  private val_t[len] val;

  /// Initialize delay line using optional initial value
  const pure nothrow @nogc @safe
  this(const val_t initial) {
    val[0..$] = initial;
  }

  /// Put value to line by assign
  pure nothrow @nogc @safe
  opAssign(const val_t value) {
    push(value);
  }

  /// Get oldest value from line by cast
  const pure nothrow @nogc @safe @property
  val_t opCast() {
    return oldest;
  }

  /// Put value to line
  ///
  ///Puts the new value to end of line and drops the most old value from line.
  pure nothrow @nogc @safe
  push(const val_t value) {
    end = _next(end);
    val[end] = value;
  }

  /// Get latest value from line
  const pure nothrow @nogc @safe @property
  val_t latest() {
    return val[end];
  }

  /// Get oldest value from line
  const pure nothrow @nogc @safe @property
  val_t oldest() {
    return val[_next(end)];
  }

  /// Get nth value from line
  ///
  /// 0 means last pushed value
  /// 1 previous pushed value and so on
  const pure nothrow @nogc @safe
  val_t opIndex(uint idx) {
    return val[idx > end ? len + end - idx : end - idx];
  }

  private static pure nothrow @nogc @safe
  uint _next(uint idx) {
    idx ++;
    if (idx >= len) {
      idx = 0;
    }
    return idx;
  }
}

/// Test delay line
nothrow @nogc unittest {
  PFDL!(5, float) dl;

  assert_eq(dl.latest, 0);
  assert_eq(dl.oldest, 0);
  assert_eq(dl[0], 0);
  assert_eq(dl[1], 0);

  dl.push(1);

  assert_eq(dl.latest, 1);
  assert_eq(dl.oldest, 0);
  assert_eq(dl[0], 1);
  assert_eq(dl[1], 0);

  dl.push(0);

  assert_eq(dl.latest, 0);
  assert_eq(dl.oldest, 0);
  assert_eq(dl[0], 0);
  assert_eq(dl[1], 1);

  dl.push(0);

  assert_eq(dl.latest, 0);
  assert_eq(dl.oldest, 0);
  assert_eq(dl[0], 0);
  assert_eq(dl[1], 0);
  assert_eq(dl[2], 1);

  dl.push(0);

  assert_eq(dl.latest, 0);
  assert_eq(dl.oldest, 0);
  assert_eq(dl[0], 0);
  assert_eq(dl[1], 0);
  assert_eq(dl[2], 0);
  assert_eq(dl[3], 1);

  dl.push(0);

  assert_eq(dl.latest, 0);
  assert_eq(dl.oldest, 1);
  assert_eq(dl[0], 0);
  assert_eq(dl[1], 0);
  assert_eq(dl[2], 0);
  assert_eq(dl[3], 0);
  assert_eq(dl[4], 1);

  dl.push(0);

  assert_eq(dl.latest, 0);
  assert_eq(dl.oldest, 0);
  assert_eq(dl[0], 0);
  assert_eq(dl[1], 0);
  assert_eq(dl[2], 0);
  assert_eq(dl[3], 0);
  assert_eq(dl[4], 0);
}

/// Test delay line
nothrow @nogc unittest {
  PFDL!(3, float) dl = 1;

  assert_eq(dl.latest, 1);
  assert_eq(dl.oldest, 1);
  assert_eq(dl[0], 1);
  assert_eq(dl[1], 1);
  assert_eq(dl[2], 1);
  assert_eq(cast(float) dl, 1);

  dl = 0;

  assert_eq(dl.latest, 0);
  assert_eq(dl.oldest, 1);
  assert_eq(dl[0], 0);
  assert_eq(dl[1], 1);
  assert_eq(dl[2], 1);
  assert_eq(cast(float) dl, 1);

  dl = 1;

  assert_eq(dl.latest, 1);
  assert_eq(dl.oldest, 1);
  assert_eq(dl[0], 1);
  assert_eq(dl[1], 0);
  assert_eq(dl[2], 1);
  assert_eq(cast(float) dl, 1);

  dl = 1;

  assert_eq(dl.latest, 1);
  assert_eq(dl.oldest, 0);
  assert_eq(dl[0], 1);
  assert_eq(dl[1], 1);
  assert_eq(dl[2], 0);
  assert_eq(cast(float) dl, 0);

  dl = 0;

  assert_eq(dl.latest, 0);
  assert_eq(dl.oldest, 1);
  assert_eq(dl[0], 0);
  assert_eq(dl[1], 1);
  assert_eq(dl[2], 1);
  assert_eq(cast(float) dl, 1);
}
