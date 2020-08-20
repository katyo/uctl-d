/**
   ## Window functions

   This module defines window function weights type and initializers for some well known widely used window functions.

   See_Also:
     [Window function](https://en.wikipedia.org/wiki/Window_function) wikipedia article.
 */
module uctl.util.win;

import std.traits: Unqual, Parameters, ReturnType;
import std.math: fabs, sin, cos, PI;
import uctl.num: isNum;
import uctl.fix: isNumer;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.fix: fix;

  mixin unittests;
}

/**
 * Window weights
 */
struct Window(uint N_, W_) if (isNumer!W_ && N_ > 0) {
  /// Weight type
  alias W = Unqual!W_;

  /// Window size
  enum uint N = N_;

  /// Number of weights
  enum uint L = N + 1;

  private W[L] weight;

  const pure nothrow @nogc @safe
  W opIndex(uint i) {
    return weight[i];
  }

  /// Set weight value by index
  pure nothrow @nogc @safe
  void opIndexAssign(W v, uint i) {
    weight[i] = v;
  }
}

/// Create window by generating weights
Window!(N, W) window_generate(uint N, W, alias F)() if (isNumer!W && N > 0 && Parameters!F.length == 1 && isNum!(ReturnType!F)) {
  Window!(N, W) window;
  foreach (i; 0..window.L) {
    window[i] = cast(W) F(i);
  }
  return window;
}

/// Rectangular window function
alias rectangular(uint N, W) = window_generate!(N, W, (uint n) => 1.0);

/// Boxcar window function (alias for [rectangular])
alias boxcar(uint N, W) = rectangular!(N, W);

/// Dirichlet window function (alias for [rectangular])
alias dirichlet(uint N, W) = rectangular!(N, W);

/// Test rectangular window function (float)
nothrow @nogc unittest {
  static immutable w = boxcar!(5, float);

  assert_eq(w.N, 5);
  assert_eq(w.L, 6);

  foreach (i; 0 .. w.L) {
    assert_eq(w[i], 1.0);
  }
}

/// Test rectangular window function (fixed)
nothrow @nogc unittest {
  alias X = fix!(0, 5);

  static immutable w = boxcar!(5, X);

  assert_eq(w.N, 5);
  assert_eq(w.L, 6);

  foreach (i; 0 .. w.L) {
    assert_eq(w[i], cast(X) 1.0);
  }
}

/// Triangular window function (2dn-order B-spline window)
template triangular(uint N, uint L, W) {
  enum real half_N = cast(real) N / cast(real) 2.0;
  enum real inv_half_L = cast(real) 2.0 / cast(real) L;
  alias func = (uint n) => 1.0 - fabs((cast(real) n - half_N) * inv_half_L);
  alias triangular = window_generate!(N, W, func);
}

/// Triangular window function with L = N
alias triangular0(uint N, W) = triangular!(N, N, W);

/// Bartlett window function (alias for [triangular0])
alias bartlett(uint N, W) = triangular0!(N, W);

/// Fejer window function (alias for [triangular0])
alias fejer(uint N, W) = triangular0!(N, W);

/// Triangular window function with L = N + 1
alias triangular1(uint N, W) = triangular!(N, N + 1, W);

/// Triangular window function with L = N + 2
alias triangular2(uint N, W) = triangular!(N, N + 2, W);

/// Test triangular window function (float)
nothrow @nogc unittest {
  static immutable w = bartlett!(5, float);

  assert_eq(w[0], 0.0);
  assert_eq(w[1], 0.4, 1e-8);
  assert_eq(w[2], 0.8, 1e-7);
  assert_eq(w[3], 0.8, 1e-7);
  assert_eq(w[4], 0.4, 1e-8);
  assert_eq(w[5], 0.0);
}

/// Test triangular window function (fixed)
nothrow @nogc unittest {
  alias X = fix!(-1, 1);

  static immutable w = bartlett!(5, X);

  assert_eq(w[0], cast(X) 0.0);
  assert_eq(w[1], cast(X) 0.4);
  assert_eq(w[2], cast(X) 0.8);
  assert_eq(w[3], cast(X) 0.8);
  assert_eq(w[4], cast(X) 0.4);
  assert_eq(w[5], cast(X) 0.0);
}

/// Parzen window function
template parzen(uint N, W) {
  enum uint L = N + 1;
  enum real half_L = cast(real) L / cast(real) 2.0;
  enum real quarter_L = cast(real) L / cast(real) 4.0;
  enum real half_N = cast(real) N / cast(real) 2.0;
  alias func = (uint n) {
    const auto biased_n = fabs(cast(real) n - half_N);
    const auto biased_n_div_half_L = biased_n / half_L;
    const auto one_sub_biased_n_div_half_L = 1.0 - biased_n_div_half_L;
    return biased_n > quarter_L ?
    (2.0 * one_sub_biased_n_div_half_L * one_sub_biased_n_div_half_L * one_sub_biased_n_div_half_L) :
    (1.0 - 6.0 * biased_n_div_half_L * biased_n_div_half_L * one_sub_biased_n_div_half_L);
  };
  alias parzen = window_generate!(N, W, func);
}

/// Welch window function
template welch(uint N, W) {
  enum real inv_half_N = cast(real) 2.0 / cast(real) N;
  alias func = (uint n) {
    const auto v = cast(real) n * inv_half_N - 1.0;
    return 1.0 - v * v;
  };
  alias welch = window_generate!(N, W, func);
}

/// Sine window function
template sine(uint N, W) {
  enum real f = cast(real) PI / cast(real) N;
  alias sine = window_generate!(N, W, (uint n) => sin(f * cast(real) n));
}

/// Hann window function
template hann(uint N, W) {
  enum real f = cast(real) PI / cast(real) N;
  alias func = (uint n) {
    const auto s = f * n;
    return sin(s * s);
  };
  alias hann = window_generate!(N, W, func);
}

/// Generic cosine window
template cosine(uint N, W, real a0 = 0, real a1 = 0, real a2 = 0, real a3 = 0, real a4 = 0) {
  enum real p0 = cast(real) PI / cast(real) N;
  enum real p1 = p0 * 2.0;
  enum real p2 = p1 * 2.0;
  enum real p3 = p2 * 2.0;
  enum real p4 = p3 * 2.0;
  alias func = (uint n) => a0 - a1 * cos(p1 * n) + a2 * cos(p2 * n) - a3 * cos(p3 * n) + a4 * cos(p4 * n);
  alias cosine = window_generate!(N, W, func);
}

/// Hamming window
template hamming(uint N, W) {
  enum real a0 = 25.0 / 46.0;
  enum real a1 = 1.0 - a0;
  alias hamming = cosine!(N, W, a0, a1);
}

/// Hamming window (zero-phase version)
template hamming(uint N, W) {
  enum real a0 = 25.0 / 46.0;
  enum real a1 = a0 - 1.0;
  alias hamming = cosine!(N, W, a0, a1);
}

/// Blackman window
template blackman(uint N, W) {
  enum real d = 18608.0;
  enum real a0 = 7938.0 / d;
  enum real a1 = 9240.0 / d;
  enum real a2 = 1430.0 / d;
  alias blackman = cosine!(N, W, a0, a1, a2);
}

/// Nuttall window function
template nuttall(uint N, W) {
  enum real a0 = 0.355768;
  enum real a1 = 0.487396;
  enum real a2 = 0.144232;
  enum real a3 = 0.012604;
  alias nuttall = cosine!(N, W, a0, a1, a2, a3);
}

/// Blackman-Nuttall window function
template blackman_nuttall(uint N, W) {
  enum real a0 = 0.3635819;
  enum real a1 = 0.4891775;
  enum real a2 = 0.1365995;
  enum real a3 = 0.0106411;
  alias blackman_nuttall = cosine!(N, W, a0, a1, a2, a3);
}

/// Blackman-Harris window function
template blackman_harris(uint N, W) {
  enum real a0 = 0.35875;
  enum real a1 = 0.48829;
  enum real a2 = 0.14128;
  enum real a3 = 0.01168;
  alias blackman_harris = cosine!(N, W, a0, a1, a2, a3);
}

/// Flat top window function
template flat_top(uint N, W) {
  enum real a0 = 1.0;
  enum real a1 = 1.93;
  enum real a2 = 1.29;
  enum real a3 = 0.388;
  enum real a4 = 0.028;
  alias flat_top = cosine!(N, W, a0, a1, a2, a3, a4);
}

/// Rife-Vincent window function of Class I with K = 1
///
/// Note: Functionally equivalent to the Hann window function.
template rife_vincent1(uint N, W) {
  enum real a0 = 1.0;
  enum real a1 = 1.0;
  alias rife_vincent1 = cosine!(N, W, a0, a1);
}

/// Rife-Vincent window function of Class I with K = 2
template rife_vincent2(uint N, W) {
  enum real a0 = 1.0;
  enum real a1 = 4.0 / 3.0;
  enum real a1 = 1.0 / 3.0;
  alias rife_vincent2 = cosine!(N, W, a0, a1, a2);
}

// TODO: Add some other pretty useful window functions:
// Gaussian, normal, Tukey, Planck-taper, Slepian, Kaiser, Dolph-Chebyshev, Ultraspherical, Poisson

/// Lanczos window function
template lanczos(uint N, W) {
  enum real f = cast(real) PI * 2.0 / cast(real) N;
  alias func = (uint n) {
    const auto z = f * cast(real) n - PI;
    return sin(z) / z;
  };
  alias lanczos = window_generate!(N, W, func);
}
