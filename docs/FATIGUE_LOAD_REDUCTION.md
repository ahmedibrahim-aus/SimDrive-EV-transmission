# FTP-75 Equivalent Sinusoid

The simulation reduces the FTP-75 torque history to one equivalent sinusoid. It is the only fatigue-load reduction used.

## Instructor-side calculation

1. Simulate the complete FTP-75 speed trace.
2. Retain finite torque samples while vehicle speed exceeds a small moving-speed threshold (`minMovingKph`), so that standing time is excluded.
3. Count the irregular torque cycles with rainflow counting.
4. Drop cycles whose range is below 2 percent of the full moving-torque range (controller ripple), then reduce the remaining spectrum to one cycle-weighted mean torque and one damage-equivalent alternating torque with the fixed exponent m = 3.
5. Construct the teaching waveform

   $$
   T_{\mathrm{eq}}(t)=T_{\mathrm{mean,eq}}+T_{\mathrm{alt,eq}}\sin\left(\frac{2\pi t}{\tau}\right).
   $$

The sinusoid is a teaching representation of the FTP-75 load spectrum. It is not a claim that the original signal is sinusoidal, and it is not a complete variable-mean fatigue-life calculation.

## Student-facing calculation

Students receive `T_mean_eq` and `T_alt_eq`. They do not perform rainflow counting, choose among alternative reduction methods, or calculate cumulative damage. They use the supplied pair to form the mean and alternating stresses required by the Shigley DE-Goodman procedure.

## Bearing load

Bearing life uses `T_cubic_mean`, the revolution-weighted cubic mean of the FTP-75 torque history. That is the Shigley Ch. 11 equivalent load, the constant load giving the same rating life as a continuously varying one, with `a = 3` for ball bearings. The mesh forces are proportional to torque, so the reactions scale with it; holding `X` and `Y` at their values for that load is the one approximation. The mean of the equivalent sinusoid is not used for bearings: it is a signed average of driving and regenerative torque and understates the load a bearing feels.

## What the export records

The export records the method identifier (`method_used`, always `equivalent-sinusoid`), the exponent (`m_sn`) and the ripple gate (`range_gate`) in `rf_data`. The moving-speed threshold (5 km/h) and the sinusoid period (120 s) are fixed in the code.
