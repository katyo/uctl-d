/**
   ## Filters

   Digital signal filters
*/
module uctl.filt;

public import uctl.filt.avg: avg;
public import uctl.filt.med: med;
public import EMA = uctl.filt.ema;
public import FIR = uctl.filt.fir;
public import LQE = uctl.filt.lqe;

alias mk = uctl.filt.ema.mk;
alias mk = uctl.filt.fir.mk;
alias mk = uctl.filt.lqe.mk;
