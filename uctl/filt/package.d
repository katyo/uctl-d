/**
   ## Filters

   Digital signal filters
*/
module uctl.filt;

public import uctl.filt.avg: avg;
public import uctl.filt.med: med;
public import uctl.filt.ema: EmaParam = Param, EmaState = State, EmaAlpha = Alpha, EmaSamples = Samples, EmaTime = Time, EmaPT1 = PT1;
public import uctl.filt.fir: FirParam = Param, FirState = State;
public import uctl.filt.lqe: LqeParam = Param, LqeState = State;

alias uctl.filt.ema.mk mk;
alias uctl.filt.fir.mk mk;
alias uctl.filt.lqe.mk mk;
