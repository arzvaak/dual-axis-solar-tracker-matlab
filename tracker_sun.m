function s = tracker_sun(p, t)
    % Calculate geometric solar position as an east/north/up unit vector.
    d = day(p.date, 'dayofyear');
    days = 365+double(eomday(year(p.date), 2)==29);
    g = 2*pi/days*(d-1+(t/3600-12)/24);
    eq = 229.18*(0.000075+0.001868*cos(g)-0.032077*sin(g)-0.014615*cos(2*g)-0.040849*sin(2*g));
    dec = 0.006918-0.399912*cos(g)+0.070257*sin(g)-0.006758*cos(2*g)+0.000907*sin(2*g)-0.002697*cos(3*g)+0.00148*sin(3*g);
    ha = deg2rad((t/60+eq+4*p.longitude-60*p.utcOffset)/4-180);
    lat = deg2rad(p.latitude);
    e = -cos(dec).*sin(ha);
    n = cos(lat).*sin(dec)-sin(lat).*cos(dec).*cos(ha);
    u = sin(lat).*sin(dec)+cos(lat).*cos(dec).*cos(ha);
    s.vector = [e n u];
    s.elevation = asind(max(-1, min(1, u)));
    s.azimuth = mod(atan2d(e, n), 360);
    s.equationOfTime = eq;
end
