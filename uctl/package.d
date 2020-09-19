/**

   # Generic control library for low-end hadrware

   ![License: MIT](https://img.shields.io/badge/License-MIT-brightgreen.svg) ![Build Status](https://github.com/katyo/uctl-d/workflows/CI/badge.svg)

   This library intended to simplify developing control algorithms for bare-metal low-end hardware such as microcontrollers without FPU.

   ## Overview

   This library consist of independent components which grouped by filters, regulators, transformers, modulators, models and utils, such as clampers, scalers and etc.
   Also it includes some widely used math functions approximations, which can be configured to reach optimal balance between precision and speed.

   The filters and regulators can be configured in a human-friendly way without using obscure artifical coefficients.

   In addition to standard floating-point types, this library introduces easy to use range-based fixed-point type, which can help to make control algorithms so efficient to fit to low-end integer microcontrollers without floating-point unit (FPU).

   To get easy developing, debugging, testing and verivication all components can operate both with floating-point and fixed-point values.

   ### Optimization techniques

   When you targeted to FPU-less hardware in order to get best possible performance and reduce firmware size you should use only binary fixed-point arithmetic because internally it operates with integers.
   Also you should avoid exceeding platform word size when it is possible without lossing required precision.

   ### Implementation notes

   Fixed point arithmetic has well known problems with overflowing especially on multiplication. Also it has well known problems with precision loss on division. Using range-based arithmetic can help to avoid that problems by selecting optimal type for each operation. To get it works this library utilizes metaprogramming features of programming language on types level.

   ### Why D? Why not C++ or Rust or something else

   Only limited subset of programming languages can be used for microcontrollers firmware development. Traditionally this is $(I C) and $(I C++) and now is $(I Rust) also.

   Different programming languages have different metaprogramming capabilities. Previously I tried implement similar libraries with $(I C++) and even $(I Rust). But in practice was not so easy to reach planned goals using it.

   Template system of $(I C++) technically has needed capabilities but it isn't so clear and flexible but much more poor and tricky.
   $(I Rust) is missing type-level constants itself but it has alternative solutions like `typenum` which allows to do it but it isn't so easy to use especially for non-integers.
   $(I D) has powerful compile-time function evaluation (CTFE) engine and also much more clear, flexible and easy to use template system.
In my experience currently $(I D) is a best choice to achieve the goals pursued by this library.

*/
module uctl;

public import uctl.math;
public import uctl.unit;
public import uctl.util;

public import Filt = uctl.filt;
public import Trans = uctl.trans;
public import Regul = uctl.regul;
public import Simul = uctl.simul;
public import Modul = uctl.modul;

alias uctl.filt.mk mk;
alias uctl.trans.mk mk;
alias uctl.regul.mk mk;
alias uctl.simul.mk mk;
alias uctl.modul.mk mk;
alias uctl.util.mk mk;
