import uctl;

extern(C):

enum dt = 1.0.as!msec;

export float get_timing() {
  return dt.to!sec.raw;
}

static f_param = mk!(Filt.LQE.Param)(0.0f, 0.0f, 0.0f, 0.0f);
static f_state = Filt.LQE.State!(f_param, float)();

export void f_set_params(float f, float h, float q, float r) {
  f_param = mk!(Filt.LQE.Param)(f, h, q, r);
}

export void f_reset(float value, float covar) {
  f_state.x = value;
  f_state.p = covar;
}

export float f_apply(float value) {
  return f_state(f_param, value);
}

alias P = fix!(0.01, 0.99);
alias V = fix!(-100, 100);

static x_param = mk!(Filt.LQE.Param)(P(0), P(0), P(0), P(0));
static x_state = Filt.LQE.State!(x_param, V)();

export void x_set_params(float f, float h, float q, float r) {
  x_param = mk!(Filt.LQE.Param)(P(f), P(h), P(q), P(r));
}

export void x_reset(float value, float covar) {
  x_state.x = V(value);
  x_state.p = x_state.C(covar);
}

export float x_apply(float value) {
  return cast(float) x_state(x_param, V(value));
}

void _start() {}
