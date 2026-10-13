function p = tracker_defaults
    % Default location, panel and controller settings.
    p.latitude = 29.8543;
    p.longitude = 77.8880;
    p.utcOffset = 5.5;
    p.date = datetime(2026, 3, 21);
    p.dt = 60;
    p.weather = 'Clear sky';
    p.rating = 400;
    p.tempCoefficient = -0.004;
    p.noct = 45;
    p.ambient = 28;
    p.loss = 0.10;
    p.albedo = 0.20;
    p.fixedTilt = abs(p.latitude);
    p.fixedAzimuth = 180;
    p.maxTilt = 85;
    p.singleLimit = 60;
    p.slewRate = 0.20;
    p.deadband = 1;
    p.commandInterval = 300;
    p.motorWatts = 8;
    p.standbyWatts = 0.05;
end
