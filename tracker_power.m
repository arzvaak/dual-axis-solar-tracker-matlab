function [power, poa, temp] = tracker_power(env, normal, p)
    % Convert panel irradiance and cell temperature to DC power.
    mu = max(0, sum(env(:, 5:7).*normal, 2));
    c = max(-1, min(1, normal(:, 3)));
    poa = env(:, 1).*mu+env(:, 2).*(1+c)/2+p.albedo*env(:, 3).*(1-c)/2;
    temp = env(:, 4)+(p.noct-20)/800*poa;
    power = p.rating*poa/1000.*max(0, 1+p.tempCoefficient*(temp-25))*(1-p.loss);
end
