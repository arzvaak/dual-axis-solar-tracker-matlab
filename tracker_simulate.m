function r = tracker_simulate(p)
    % Run one day for fixed, single-axis and dual-axis panels.
    validateattributes(p.latitude, {'numeric'}, {'scalar', 'finite', '>=', -89, '<=', 89});
    validateattributes(p.longitude, {'numeric'}, {'scalar', 'finite', '>=', -180, '<=', 180});
    validateattributes(p.dt, {'numeric'}, {'scalar', 'finite', 'positive', '<=', 300});
    validateattributes(p.slewRate, {'numeric'}, {'scalar', 'finite', 'positive'});
    validateattributes(p.commandInterval, {'numeric'}, {'scalar', 'finite', '>=', p.dt});
    validateattributes(p.rating, {'numeric'}, {'scalar', 'finite', 'positive'});
    assert(mod(86400, p.dt)==0, 'Time step must divide 86400 seconds.');
    assert(ismember(p.weather, {'Clear sky', 'Broken cloud', 'Overcast'}), 'Unknown weather.');

    % Sun position and shared weather.
    t = (0:p.dt:86400-p.dt)';
    s = tracker_sun(p, t);
    z = max(0, s.vector(:, 3));
    ghi = zeros(size(t));
    daylit = z>0;
    ghi(daylit) = 1098*z(daylit).*exp(-0.059./z(daylit));
    switch p.weather
    case 'Clear sky'
        transmission = ones(size(t));
        diffuse = 0.15*ones(size(t));
    case 'Broken cloud'
        transmission = 1-0.65*exp(-((t/3600-10)/0.65).^2)-0.55*exp(-((t/3600-14)/0.9).^2);
        diffuse = 0.15+0.65*(1-transmission);
    case 'Overcast'
        transmission = 0.30*ones(size(t));
        diffuse = 0.95*ones(size(t));
    end
    ghi = ghi.*transmission;
    dhi = ghi.*diffuse;
    dni = zeros(size(t));
    dni(daylit) = (ghi(daylit)-dhi(daylit))./z(daylit);
    ambient = p.ambient+4*sin(2*pi*(t/86400-0.35));
    env = [dni dhi ghi ambient s.vector];

    % Keep azimuth signed about the baseline direction in either hemisphere.
    center = p.fixedAzimuth;
    az = center+mod(s.azimuth-center+180, 360)-180;
    az = max(center-175, min(center+175, az));
    elev = max(90-p.maxTilt, min(90, s.elevation));
    dualTarget = [az elev];
    dualTarget(~daylit, :) = repmat([center 90], sum(~daylit), 1);
    % Horizontal north-south axis: normal=[sin(theta),0,cos(theta)].
    singleTarget = max(-p.singleLimit, min(p.singleLimit, atan2d(s.vector(:, 1), s.vector(:, 3))));
    singleTarget(~daylit) = 0;

    % Hold targets between controller commands.
    holdIndex = floor(t/p.commandInterval)*p.commandInterval/p.dt+1;
    holdIndex = floor(holdIndex);
    dualTarget = dualTarget(holdIndex, :);
    singleTarget = singleTarget(holdIndex, :);
    [dual, mDual] = tracker_actuate(dualTarget, [center 90], p);
    [single, mSingle] = tracker_actuate(singleTarget, 0, p);

    % Use the same irradiance and panel model for all three orientations.
    nFixed = repmat([sind(p.fixedTilt)*sind(center) sind(p.fixedTilt)*cosd(center) cosd(p.fixedTilt)], numel(t), 1);
    nSingle = [sind(single) zeros(size(t)) cosd(single)];
    nDual = [cosd(dual(:, 2)).*sind(dual(:, 1)) cosd(dual(:, 2)).*cosd(dual(:, 1)) sind(dual(:, 2))];
    [Pfix, Gfix, Tfix] = tracker_power(env, nFixed, p);
    [Psingle, Gsingle, Tsingle] = tracker_power(env, nSingle, p);
    [Pdual, Gdual, Tdual] = tracker_power(env, nDual, p);
    P = [Pfix Psingle Pdual];
    motor = [zeros(size(t)) mSingle mDual];
    net = P-motor;

    % Charge standby for the full day, including intervals with no sunlight.
    energy = cumsum(net, 1)*p.dt/3600000;
    gross = sum(P, 1)*p.dt/3600000;
    angleError = acosd(max(-1, min(1, sum(nDual.*s.vector, 2))));
    angleError(~daylit) = NaN;
    r = struct('p', p, 't', t, 'sun', s, 'env', env, 'dualTarget', dualTarget, 'singleTarget', singleTarget, 'dual', dual, 'single', single, 'power', P, 'motor', motor, 'netPower', net, 'energy', energy, 'grossEnergy', gross, 'motorEnergy', sum(motor, 1)*p.dt/3600000, 'poa', [Gfix Gsingle Gdual], 'temperature', [Tfix Tsingle Tdual], 'error', angleError);
    r.gain = NaN;
    if energy(end, 1)>0
        r.gain = 100*(energy(end, 3)/energy(end, 1)-1);
    end
end
