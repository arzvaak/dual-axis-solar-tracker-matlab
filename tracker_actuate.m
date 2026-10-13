function [actual, motor] = tracker_actuate(target, initial, p)
    % Move each axis toward its target and estimate average motor power.
    actual = zeros(size(target));
    motor = zeros(size(target, 1), 1);
    prev = initial;
    for k = 1:size(target, 1)
        err = target(k, :)-prev;
        err(abs(err)<=p.deadband) = 0;
        move = max(-p.slewRate*p.dt, min(p.slewRate*p.dt, err));
        prev = prev+move;
        actual(k, :) = prev;
        motor(k) = p.standbyWatts+p.motorWatts*sum(abs(move))/(p.slewRate*p.dt);
    end
end
