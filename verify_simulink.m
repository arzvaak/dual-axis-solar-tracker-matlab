function report = verify_simulink(p)
    % Compare the block model with the MATLAB calculation sample by sample.
    if nargin==0
        p = tracker_defaults;
    end
    r = tracker_simulate(p);
    model = tracker_build_simulink(p);
    out = sim(model);
    a = squeeze(out.angleOutput.Data);
    pow = squeeze(out.powerOutput.Data);
    mot = squeeze(out.motorOutput.Data);
    if size(a, 1)==3 && size(a, 2)~=3
        a = a';
        pow = pow';
        mot = mot';
    end
    angleError = max(abs(a-[r.single r.dual]), [], 'all');
    powerError = max(abs(pow-r.netPower), [], 'all');
    motorError = max(abs(mot-r.motor), [], 'all');
    assert(size(a, 1)==numel(r.t), 'Sample count mismatch');
    assert(angleError<1e-9 && powerError<1e-8 && motorError<1e-9, 'MATLAB/Simulink mismatch');
    report = struct('status', 'PASS', 'samples', size(a, 1), 'maximumAngleError_deg', angleError, 'maximumPowerError_W', powerError, 'maximumMotorError_W', motorError, 'netEnergy_kWh', sum(pow, 1)*p.dt/3600000);
    disp(report);
end
