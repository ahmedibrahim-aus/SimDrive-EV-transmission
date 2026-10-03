function t = courseTargets()
%COURSETARGETS Fixed design targets of the EV gearbox module, one place.
%   These are course defaults. An instructor may change life_km (see the
%   instructor guide); students design to these values and do not choose them.
    t.life_km = 150000;          % bearing L10 and gear design life
    t.gear_bending = 1.50;       % AGMA bending safety factor S_F
    t.gear_contact = 1.20;       % AGMA contact safety factor S_H
    t.shaft_fatigue = 1.50;      % DE-Goodman, every critical section
    t.shaft_yield = 1.50;        % static von Mises yield, every section
    t.qv_check_kph = 120;        % vehicle speed for the Eq. (14-29) Q_v check
end
