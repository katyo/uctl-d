RTm = [
      100e3 24
      86e3  27
      82e3  30
      24e3  80
      20e3 110
      12e3 135
];

C2K = @(C) C + 273.15;
K2C = @(K) K - 273.15;

Rm = RTm(:,1);
TmC = RTm(:,2);
Tm = C2K(TmC);

R0 = Rm(1);
T0 = Tm(1);

invTm = 1 ./ Tm;

invR0 = 1 / R0;
invT0 = 1 / T0;

## Steinhart-Hart model
TofShH = @(R, a, b, c) 1 ./ (a + b * log(R) + c * log(R).^3);
invTofSh = @(R, a, b, c) a + b * log(R) + c * log(R).^3;

TofABC = @(R, abc) TofShH(R, abc(1), abc(2), abc(3));

## Fit of Steinhart-Hart model
abc = [ones(size(Rm)) log(Rm) log(Rm).^3] \ invTm
MSEofShH = mean((TofABC(Rm, abc) - Tm).^2);
RMSEofShH = sqrt(MSEofShH)

## Simplified beta model
TofBeta = @(R, Beta, R0, T0) 1 ./ (1/T0 + 1/Beta * log(R / R0));
invTofBeta = @(R, invBeta) invT0 + invBeta * log(R * invR0);

## Fit of beta model
Beta = 1 / ([log(Rm * invR0)] \ (invTm - 1/T0))
MSEofBeta = mean((TofBeta(Rm, Beta, R0, T0) - Tm).^2);
RMSEofBeta = sqrt(MSEofBeta)

## Plot results
Ra = 120e3:-1:10e3;

TaofShH = TofABC(Ra, abc);
TaCofShH = K2C(TaofShH);

TaofBeta = TofBeta(Ra, Beta, R0, T0);
TaCofBeta = K2C(TaofBeta);

plot(Rm, TmC, '+;Measurements;',
     Ra, TaCofBeta, '-;Approx. (Beta);',
     Ra, TaCofShH, '-;Approx. (Steinhart-Hart);');
xlabel("R, Ohm");
ylabel("T, *C");

print -dsvg -color '-S640,640' thr_fit.svg
