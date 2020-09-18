/**
   ## Window functions

   This module defines window function weights type and initializers for some well known widely used window functions.

   ![Window functions](win_funcs.svg)

   See_Also:
     [Window function](https://en.wikipedia.org/wiki/Window_function) wikipedia article.
 */
module uctl.util.win;

import std.traits: Unqual, Parameters, ReturnType, isInstanceOf;
import std.math: fabs, sin, cos, PI;
import uctl.num: isNum, isNumer;

version(unittest) {
  import uctl.test: assert_eq, unittests;
  import uctl.num: fix;

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

  W[L] weight;

  alias weight this;

  const pure nothrow @nogc @safe
  this(const W w) {
    weight = () {
      W[L] ws;
      foreach(i; 0..L) {
        ws[i] = w;
      }
      return ws;
    } ();
  }
}

/// Test `Window`
nothrow @nogc unittest {
  static immutable w = Window!(100, double)(0.0);

  assert_eq(w[0], 0.0);
  assert_eq(w[50], 0.0);
  assert_eq(w[100], 0.0);
}

/// Check for window function
template isWindow(alias W) {
  static if (__traits(compiles, W!(5, float))) {
    alias w = W!(5, float);
    static if (!is(w)) {
      enum bool isWindow = isInstanceOf!(Window, typeof(w));
    } else {
      enum bool isWindow = false;
    }
  } else {
    enum bool isWindow = false;
  }
}

/// Test `isWindow`
nothrow @nogc unittest {
  assert(isWindow!rectangular);
  assert(isWindow!dirichlet);
  assert(isWindow!hamming);
  assert(isWindow!hann);
  assert(isWindow!lanczos);
}

/// Create window by generating weights
template genWindow(alias F) if (Parameters!F.length == 1 && isNum!(ReturnType!F)) {
  alias genWindow(uint N, W) = .genWindow!(F, N, W);
}

/// Create window by generating weights
template genWindow(alias F, uint N, W) if (Parameters!F.length == 1 && isNum!(ReturnType!F) && isNumer!W && N > 0) {
  immutable Window!(N, W) genWindow = () {
    Window!(N, W) window;
    foreach (i; 0..window.L) {
      window[i] = cast(W) F(i);
    }
    return window;
  } ();
}

/// Rectangular window function
alias rectangular = genWindow!((uint n) => 1.0);

/// Boxcar window function
alias boxcar = rectangular;

/// Dirichlet window function
alias dirichlet = rectangular;

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

/// Triangular window function (2nd-order B-spline window)
template triangular(uint K) {
  template triangular(uint N, W) {
    enum uint L = N + K;
    enum real half_N = cast(real) N / cast(real) 2.0;
    enum real inv_half_L = cast(real) 2.0 / cast(real) L;
    alias func = (uint n) => 1.0 - fabs((cast(real) n - half_N) * inv_half_L);
    alias triangular = genWindow!(func, N, W);
  }
}

/// Bartlett window function
alias bartlett = triangular!0;

/// Fejer window function
alias fejer = triangular!0;

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

/// Bartlett-Hann window function
template bartlett_hann(uint N, W) {
  enum real a0 = 0.62;
  enum real a1 = 0.48;
  enum real a2 = 0.38;
  enum real PI2 = PI * 2;
  alias func = (uint n) {
    const auto d = cast(real) n / cast(real) (N + 1);
    return a0 - a1 * fabs(d - cast(real) 0.5) - a2 * cos(PI2 * d);
  };
  alias bartlett_hann = genWindow!(func, N, W);
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
  alias parzen = genWindow!(func, N, W);
}

/// Welch window function
template welch(uint N, W) {
  enum real inv_half_N = cast(real) 2.0 / cast(real) N;
  alias func = (uint n) {
    const auto v = cast(real) n * inv_half_N - 1.0;
    return 1.0 - v * v;
  };
  alias welch = genWindow!(func, N, W);
}

/// Sine window function
template sine(uint N, W) {
  enum real f = cast(real) PI / cast(real) N;
  alias sine = genWindow!((uint n) => sin(f * cast(real) n), N, W);
}

/// Hann window function
template hann(uint N, W) {
  enum real f = cast(real) PI / cast(real) N;
  alias func = (uint n) {
    const auto s = sin(f * n);
    return s * s;
  };
  alias hann = genWindow!(func, N, W);
}

/// Generic cosine window
template cosine(real a0 = 0, real a1 = 0, real a2 = 0, real a3 = 0, real a4 = 0) {
  template cosine(uint N, W) {
    enum real p0 = cast(real) PI / cast(real) N;
    enum real p1 = p0 * 2.0;
    enum real p2 = p1 * 2.0;
    enum real p3 = p2 * 2.0;
    enum real p4 = p3 * 2.0;
    alias func = (uint n) => a0 - a1 * cos(p1 * n) + a2 * cos(p2 * n) - a3 * cos(p3 * n) + a4 * cos(p4 * n);
    alias cosine = genWindow!(func, N, W);
  }
}

/// Hamming window
alias hamming = cosine!(25.0 / 46.0, 1.0 - 25.0 / 46.0);

/// Blackman window
alias blackman = cosine!(7938.0 / 18608.0, 9240.0 / 18608.0, 1430.0 / 18608.0);

/// Nuttall window function
alias nuttall = cosine!(0.355768, 0.487396, 0.144232, 0.012604);

/// Blackman-Nuttall window function
alias blackman_nuttall = cosine!(0.3635819, 0.4891775, 0.1365995,  0.0106411);

/// Blackman-Harris window function
alias blackman_harris = cosine!(0.35875, 0.48829, 0.14128, 0.01168);

/// Flat top window function
alias flat_top = cosine!(0.21557895, 0.41663158, 0.277263158, 0.083578947, 0.006947368);

/// Flat top window function
alias flat_top2 = cosine!(1.0, 1.93, 1.29, 0.388, 0.028);

/// Rife-Vincent window function of Class I with K = 1
///
/// Note: Functionally equivalent to the Hann window function.
alias rife_vincent1 = cosine!(1.0, 1.0);

/// Rife-Vincent window function of Class I with K = 2
alias rife_vincent2 = cosine!(1.0, 4.0 / 3.0, 1.0 / 3.0);

// TODO: Add some other pretty useful window functions:
// Gaussian, normal, Tukey, Planck-taper, Slepian, Kaiser, Dolph-Chebyshev, Ultraspherical, Poisson

/// Lanczos window function
template lanczos(uint N, W) {
  enum real f = cast(real) PI * 2.0 / cast(real) N;
  alias func = (uint n) {
    const auto z = f * cast(real) n - PI;
    return sin(z) / z;
  };
  alias lanczos = genWindow!(func, N, W);
}
