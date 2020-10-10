import uctl;

extern(C):

enum dt = 1.0.as!msec;

export float get_timing() {
  return dt.to!sec.raw;
}

static f_param = mk!(Filt.EMA.Window, dt)(1.0f.as!sec);
static f_state = Filt.EMA.State!(f_param, float)();

export void f_set_window(float time) {
  f_param = time.as!sec;
}

export void f_reset(float value) {
  f_state = value;
}

export float f_apply(float value) {
  return f_state(f_param, value);
}

//alias P = fix!(0, 100);
//alias V = fix!(-150, 250);
alias P = fix!(0, 10000);
alias V = fix!(-10000, 10000);

static x_param = mk!(Filt.EMA.Window, dt)(P(1.0).as!sec);
static x_state = Filt.EMA.State!(x_param, V)();

export void x_set_window(float time) {
  x_param = P(time).as!sec;
}

export void x_reset(float value) {
  x_state = V(value);
}

export float x_apply(float value) {
  return cast(float) x_state(x_param, V(value));
}

void _start() {}
