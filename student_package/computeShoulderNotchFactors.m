function factors = computeShoulderNotchFactors(diameterRatio, filletRatio, ultimateStrengthMPa, shaftDiameterMm)
%COMPUTESHOULDERNOTCHFACTORS Calculate Shigley stepped-shaft notch factors.
%   factors = COMPUTESHOULDERNOTCHFACTORS(Dd, rd, Sut, dMm) returns a table
%   with one row per shoulder: the theoretical stress-concentration factors
%   Kt_axial, Kt_bending and Kts, the notch sensitivities q and qs, the
%   fatigue factors Kf_axial, Kf_bending and Kfs, and the fillet radius r_mm.
%   Kt and Kf repeat the bending values. dMm is the smaller shaft diameter,
%   which sets r = rd*dMm for q and qs; it defaults to 40 mm.
%
%   The three Kt surfaces are digitized from the Appendix A charts of
%   Shigley's Mechanical Engineering Design, 11th edition, for a round
%   shaft with a shoulder fillet in tension, in torsion and in bending.
%
%   Notch sensitivity is not digitized. q and qs come from the Shigley Ch. 6
%   SI curve fits for the Neuber constant, one for bending and axial load
%   and one for torsion. The Ch. 6 notch-sensitivity charts plot that same
%   relation.
%
%   Dd is D/d, rd is r/d, Sut is in MPa, and dMm is in millimeters. Linear
%   interpolation is used between digitized chart points.
%
%   Domain. rd runs from 0.025 to 0.100 and Dd from 1.05 to
%   1.50. The grids stop at rd = 0.025 because the printed curves stop
%   there: on the tension chart the D/d = 1.02, 1.05, 1.10 and 1.50 curves
%   begin at rd of about 0.023, 0.032, 0.028 and 0.042, and on the torsion
%   chart the
%   four curves begin between rd of about 0.013 and 0.021. Anything below
%   rd = 0.025 would be extrapolation, not chart reading.
%
%   Accuracy. Entries read directly off a plotted curve agree with the
%   figure to about +/-0.05 in Kt or Kts, which is the width of the printed
%   line plus the axis reading. Six tension entries are extrapolations
%   rather than reads, because the tension-chart curve concerned has not started
%   yet: D/d = 1.05 at rd = 0.025 and 0.030, D/d = 1.10 at rd = 0.025, and
%   D/d = 1.50 at rd = 0.025, 0.030 and 0.040. They follow the plotted part of the same curve as
%   Kt = 1 + a (r/d)^b and carry no chart-reading tolerance. The tension
%   chart ordinate stops at 2.6 and the torsion and bending ordinates stop
%   at 3.0. Every entry read off a curve lies inside its chart's ordinate;
%   the extrapolated D/d = 1.50 entries 2.98 and 2.80 lie above the tension
%   chart ordinate, which is why they are named here.
%
%   The bending grid carries no Dd = 1.20 curve, because the bending chart
%   does not plot one, and interpolates between 1.10 and 1.50. The torsion
%   chart begins at Dd = 1.09, so smaller shoulders are read on that curve.

    arguments
        diameterRatio {mustBeNumeric, mustBeReal, mustBeFinite}
        filletRatio {mustBeNumeric, mustBeReal, mustBeFinite}
        ultimateStrengthMPa (1,1) {mustBeNumeric, mustBeReal, mustBeFinite, mustBePositive}
        shaftDiameterMm (1,1) {mustBeNumeric, mustBeReal, mustBeFinite, mustBePositive} = 40
    end

    validateUltimateStrength(ultimateStrengthMPa);

    [diameterRatio, filletRatio] = expandScalarInputs(diameterRatio, filletRatio);
    diameterRatio = diameterRatio(:);
    filletRatio = filletRatio(:);

    validateShoulderGeometry(diameterRatio, filletRatio);

    filletGrid = [0.025 0.030 0.040 0.050 0.075 0.100];

    % Tension chart. The six entries named as extrapolations in the help
    % text are D/d = 1.05 at r/d = 0.025 and 0.030, D/d = 1.10 at r/d =
    % 0.025, and D/d = 1.50 at r/d = 0.025, 0.030 and 0.040; every other
    % entry is read off a plotted curve.
    axialDiameterGrid = [1.05 1.10 1.50];
    ktAxialGrid = [
        2.11 2.22 2.98
        1.97 2.12 2.80
        1.81 1.96 2.55
        1.71 1.86 2.38
        1.55 1.68 2.08
        1.47 1.56 1.88];

    % Bending chart.
    bendingDiameterGrid = [1.05 1.10 1.50 3.00];
    ktBendingGrid = [
        2.14 2.25 2.58 2.84
        2.04 2.15 2.44 2.70
        1.90 1.99 2.22 2.48
        1.80 1.88 2.07 2.31
        1.64 1.70 1.82 2.00
        1.54 1.59 1.67 1.81];

    % Torsion chart.
    torsionDiameterGrid = [1.09 1.20 1.33 2.00];
    ktsGrid = [
        1.52 1.97 2.08 2.21
        1.44 1.85 1.97 2.07
        1.35 1.71 1.81 1.90
        1.29 1.61 1.70 1.77
        1.21 1.44 1.53 1.58
        1.17 1.35 1.43 1.47];

    validateChartRange(diameterRatio, filletRatio, axialDiameterGrid, ...
        bendingDiameterGrid, torsionDiameterGrid, filletGrid);

    % The torsion chart begins at D/d = 1.09. Using that curve for smaller
    % shoulders is conservative because Kts increases with D/d.
    torsionDiameterRatio = max(diameterRatio, min(torsionDiameterGrid));

    ktAxial = interp2(axialDiameterGrid, filletGrid, ktAxialGrid, ...
        diameterRatio, filletRatio, "linear");
    ktBending = interp2(bendingDiameterGrid, filletGrid, ktBendingGrid, ...
        diameterRatio, filletRatio, "linear");
    kts = interp2(torsionDiameterGrid, filletGrid, ktsGrid, ...
        torsionDiameterRatio, filletRatio, "linear");

    filletRadiusMm = filletRatio .* shaftDiameterMm;

    % Shigley Ch. 6 notch-sensitivity fits for steel, with Sut in
    % MPa and sqrt(a), sqrt(as) in sqrt(mm). The first fit covers bending and
    % axial loading; the second covers torsion.
    sqrtA = 1.240 - 2.250e-3*ultimateStrengthMPa + ...
        1.600e-6*ultimateStrengthMPa^2 - 4.110e-10*ultimateStrengthMPa^3;
    sqrtAs = 0.958 - 1.830e-3*ultimateStrengthMPa + ...
        1.430e-6*ultimateStrengthMPa^2 - 4.110e-10*ultimateStrengthMPa^3;
    q = 1 ./ (1 + sqrtA ./ sqrt(filletRadiusMm));
    qs = 1 ./ (1 + sqrtAs ./ sqrt(filletRadiusMm));

    kfAxial = 1 + q .* (ktAxial - 1);
    kfBending = 1 + q .* (ktBending - 1);
    kfs = 1 + qs .* (kts - 1);

    % Kt and Kf repeat the bending factors.
    kt = ktBending;
    kf = kfBending;
    chartSource = repmat( ...
        "Shigley 11e Appendix A shoulder-fillet charts; q from the Ch. 6 fits", ...
        numel(diameterRatio), 1);
    digitizationTolerance = 0.05 + zeros(size(diameterRatio));

    factors = table(diameterRatio, filletRatio, filletRadiusMm, ...
        torsionDiameterRatio, ktAxial, ktBending, kts, ...
        sqrtA + zeros(size(diameterRatio)), sqrtAs + zeros(size(diameterRatio)), ...
        q, qs, kfAxial, kfBending, kfs, kt, kf, ...
        chartSource, digitizationTolerance, ...
        'VariableNames', {'D_over_d','r_over_d','r_mm', ...
        'D_over_d_torsion','Kt_axial','Kt_bending','Kts', ...
        'sqrtA_mm05','sqrtAs_mm05','q','qs','Kf_axial','Kf_bending', ...
        'Kfs','Kt','Kf','ChartSource','DigitizationTolerance'});
end

function [diameterRatio, filletRatio] = expandScalarInputs(diameterRatio, filletRatio)
    if isscalar(diameterRatio) && ~isscalar(filletRatio)
        diameterRatio = repmat(diameterRatio, size(filletRatio));
    elseif isscalar(filletRatio) && ~isscalar(diameterRatio)
        filletRatio = repmat(filletRatio, size(diameterRatio));
    elseif ~isequal(size(diameterRatio), size(filletRatio))
        error('SimDrive:ShoulderNotch:SizeMismatch', ...
            'D/d and r/d must be scalars or arrays with matching size.');
    end
end

function validateUltimateStrength(ultimateStrengthMPa)
    % The Ch. 6 cubic fits for the Neuber constant are drawn from the
    % notch-sensitivity charts, which plot steels from 60 to 200 kpsi, that is
    % 415 to 1400 MPa. Shigley states the fits for 340 to 1700 MPa (bending)
    % and 340 to 1500 MPa (torsion); the helper keeps to the narrower range
    % the figures plot, a course choice. Above about 1700 MPa sqrt(a) turns
    % negative, which returns q > 1 and Kf > Kt.
    minimumStrengthMPa = 415;
    maximumStrengthMPa = 1400;
    if ultimateStrengthMPa < minimumStrengthMPa || ultimateStrengthMPa > maximumStrengthMPa
        error('SimDrive:ShoulderNotch:OutsideStrengthRange', ...
            ['Sut = %.0f MPa is outside %.0f to %.0f MPa, the range of the Shigley ' ...
            'Ch. 6 notch-sensitivity charts that this course allows.'], ultimateStrengthMPa, ...
            minimumStrengthMPa, maximumStrengthMPa);
    end
end

function validateShoulderGeometry(diameterRatio, filletRatio)
    if any(diameterRatio <= 1, 'all')
        error('SimDrive:ShoulderNotch:InvalidDiameterRatio', ...
            'D/d must be greater than 1.');
    end
    if any(filletRatio <= 0, 'all')
        error('SimDrive:ShoulderNotch:InvalidFilletRatio', ...
            'r/d must be positive.');
    end
    % Relative tolerance, so that an exactly filled shoulder such as
    % D/d = 1.20 with r/d = 0.100 is accepted rather than rejected by
    % floating-point round-off.
    maximumFilletRatio = 0.5*(diameterRatio - 1);
    if any(filletRatio > maximumFilletRatio.*(1 + 1e-9), 'all')
        error('SimDrive:ShoulderNotch:InvalidGeometry', ...
            'r/d must not exceed the available shoulder height, (D/d - 1)/2.');
    end
end

function validateChartRange(diameterRatio, filletRatio, axialDiameterGrid, ...
        bendingDiameterGrid, torsionDiameterGrid, filletGrid)
    minimumDiameter = min([axialDiameterGrid bendingDiameterGrid]);
    maximumDiameter = min([max(axialDiameterGrid) max(bendingDiameterGrid) ...
        max(torsionDiameterGrid)]);
    outsideDiameterRange = diameterRatio < minimumDiameter | diameterRatio > maximumDiameter;
    outsideFilletRange = filletRatio < min(filletGrid) | filletRatio > max(filletGrid);
    if any(outsideDiameterRange | outsideFilletRange, 'all')
        error('SimDrive:ShoulderNotch:OutsideChartRange', ...
            'D/d or r/d is outside the digitized Shigley 11e chart range.');
    end
end
