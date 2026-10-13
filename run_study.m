function results = run_study
    % Compare four dates under clear, broken-cloud and overcast conditions.
    p = tracker_defaults;
    r = tracker_simulate(p);
    folder = tracker_export(r);
    dates = [datetime(2026, 3, 21) datetime(2026, 6, 21) datetime(2026, 9, 23) datetime(2026, 12, 21)];
    weather = {'Clear sky', 'Broken cloud', 'Overcast'};
    rows = cell(12, 7);
    k = 0;
    for d = dates
        for w = weather
            k = k+1;
            p.date = d;
            p.weather = w{1};
            a = tracker_simulate(p);
            rows(k, :) = {char(string(d, 'yyyy-MM-dd')), w{1}, a.energy(end, 1), a.energy(end, 2), a.energy(end, 3), a.motorEnergy(3), a.gain};
        end
    end
    results = cell2table(rows, 'VariableNames', {'Date', 'Weather', 'FixedNet_kWh', 'SingleNet_kWh', 'DualNet_kWh', 'DualActuation_kWh', 'DualNetGain_percent'});
    writetable(results, fullfile(folder, 'seasonal_comparison.csv'));
    f = figure('Visible', 'off', 'Color', 'white', 'Position', [100 100 1200 760]);
    tiledlayout(2, 2);
    nexttile;
    plot(r.t/3600, r.power, 'LineWidth', 1.5);
    xlabel('Local time / h');
    ylabel('DC power / W');
    title('Equal 400 W modules | Clear sky');
    legend('Fixed', 'Single axis', 'Dual axis');
    grid on;
    nexttile;
    plot(r.t/3600, r.energy, 'LineWidth', 1.5);
    xlabel('Local time / h');
    ylabel('Net energy / kWh');
    title('Motor and standby energy deducted');
    grid on;
    nexttile;
    plot(r.t/3600, [r.sun.elevation r.dual(:, 2)]);
    xlabel('Local time / h');
    ylabel('Elevation / deg');
    title('Sun and actual panel normal');
    legend('Sun', 'Panel normal');
    grid on;
    nexttile;
    plot(r.t/3600, r.error);
    xlabel('Local time / h');
    ylabel('Pointing error / deg');
    title('Finite speed + 1 deg deadband + 5 min commands');
    grid on;
    exportgraphics(f, fullfile(folder, 'daily_comparison.png'), 'Resolution', 180);
    close(f);
    disp(results);
end
