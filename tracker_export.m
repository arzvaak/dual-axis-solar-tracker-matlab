function folder = tracker_export(r)
    % Save the current experiment, daily summary and parameters.
    folder = fullfile(fileparts(mfilename('fullpath')), 'results');
    if ~isfolder(folder)
        mkdir(folder);
    end
    T = table(r.t/3600, r.sun.azimuth, r.sun.elevation, r.env(:, 1), r.env(:, 2), r.env(:, 3), r.power(:, 1), r.power(:, 2), r.power(:, 3), r.motor(:, 2), r.motor(:, 3), r.energy(:, 1), r.energy(:, 2), r.energy(:, 3), 'VariableNames', {'LocalHour', 'SunAzimuth_deg', 'SunElevation_deg', 'DNI_Wm2', 'DHI_Wm2', 'GHI_Wm2', 'Fixed_W', 'Single_W', 'Dual_W', 'SingleMotor_W', 'DualMotor_W', 'FixedNet_kWh', 'SingleNet_kWh', 'DualNet_kWh'});
    writetable(T, fullfile(folder, 'daily_timeseries.csv'));
    save(fullfile(folder, 'experiment.mat'), 'r');
    summary = table({'Fixed';'Single axis';'Dual axis'}, r.grossEnergy', r.motorEnergy', r.energy(end, :)', 'VariableNames', {'Configuration', 'Gross_kWh', 'Actuator_kWh', 'Net_kWh'});
    writetable(summary, fullfile(folder, 'daily_summary.csv'));
    fid = fopen(fullfile(folder, 'parameters.json'), 'w');
    c = onCleanup(@()fclose(fid));
    pp = r.p;
    pp.date = char(string(pp.date, 'yyyy-MM-dd'));
    fprintf(fid, '%s', jsonencode(pp, 'PrettyPrint', true));
end
