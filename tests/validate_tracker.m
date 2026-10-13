function report = validate_tracker
    % Check solar geometry, physical limits and numerical consistency.
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    p = tracker_defaults;
    r = tracker_simulate(p);
    assert(all(isfinite(r.power(:))) && all(r.power(:)>=0), 'Nonnegative finite power');
    assert(max(abs(sum(r.sun.vector.^2, 2)-1))<1e-12, 'Sun vector norm');
    night = r.sun.elevation<=0;
    assert(all(r.power(night, :)==0, 'all'), 'Night power zero');
    assert(max(abs(r.env(:, 1).*max(0, r.sun.vector(:, 3))+r.env(:, 2)-r.env(:, 3)))<1e-9, 'GHI conservation');
    assert(all(r.dual(:, 2)>=90-p.maxTilt & r.dual(:, 2)<=90), 'Tilt limits');
    assert(max(abs(diff(r.dual)), [], 'all')<=p.slewRate*p.dt+1e-9, 'Slew constraint');
    assert(max(abs(diff(r.single)))<=p.slewRate*p.dt+1e-9, 'Single slew constraint');
    assert(all(r.motorEnergy(2:3)>p.standbyWatts*24/1000), 'Motor duty and standby');
    q = p;
    q.latitude = 0;
    q.longitude = 0;
    q.utcOffset = 0;
    q.date = datetime(2026, 3, 20);
    s = tracker_sun(q, 12*3600);
    assert(s.elevation>87.5, 'Equinox independent geometry fixture');
    q.date = datetime(2026, 6, 21);
    s = tracker_sun(q, 12*3600);
    assert(abs(s.elevation-66.55)<0.5, 'Solstice fixture');
    q = p;
    q.latitude = 80;
    q.date = datetime(2026, 12, 21);
    a = tracker_simulate(q);
    assert(all(a.power(:)==0), 'Polar night');
    assert(isnan(a.gain), 'Zero baseline gain must be undefined');
    q = p;
    q.latitude = -34;
    q.longitude = 18;
    q.utcOffset = 2;
    q.fixedAzimuth = 0;
    q.fixedTilt = 34;
    q.date = datetime(2026, 12, 21);
    a = tracker_simulate(q);
    assert(all(isfinite(a.power(:))), 'Southern hemisphere');
    q = p;
    q.slewRate = 0;
    rejected = false;
    try
        tracker_simulate(q);
    catch
        rejected = true;
    end
    assert(rejected, 'Invalid rate rejected');
    q = p;
    q.dt = 30;
    a = tracker_simulate(q);
    convergence = max(abs(a.energy(end, :)-r.energy(end, :))./max(0.01, r.energy(end, :)));
    assert(convergence<0.015, 'Timestep convergence');
    q = p;
    q.motorWatts = 0;
    q.standbyWatts = 0;
    a = tracker_simulate(q);
    assert(max(abs(a.energy(end, :)-a.grossEnergy))<1e-10, 'Zero actuator energy identity');
    q = p;
    q.weather = 'Overcast';
    a = tracker_simulate(q);
    assert(all(a.grossEnergy<r.grossEnergy), 'Cloud scenario');
    report = struct('status', 'PASS', 'checks', 17, 'timestepRelativeDifference', convergence, 'defaultNetEnergy_kWh', r.energy(end, :), 'defaultNetGain_percent', r.gain);
    disp(report);
end
