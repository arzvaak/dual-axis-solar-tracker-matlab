function f = SolarTrackerLab
    % Display panel motion, energy comparisons and experiment controls.
    p = tracker_defaults;
    r = tracker_simulate(p);
    idx = round(12*3600/p.dt)+1;
    bg = [0.055 0.075 0.12];
    card = [0.09 0.12 0.18];
    ink = [0.88 0.92 0.97];
    muted = [0.60 0.69 0.79];
    colors = [0.60 0.68 0.78;0.22 0.65 0.96;0.98 0.72 0.25];
    f = uifigure('Name', 'Solar Tracker Lab | Renewable Energy', 'Position', [0 0 970 680], 'Color', bg);
    g = uigridlayout(f, [3 2], 'RowHeight', {52, '1x', 55}, 'ColumnWidth', {265, '1x'}, 'BackgroundColor', bg, 'Padding', [18 14 18 14], 'ColumnSpacing', 16);
    head = uigridlayout(g, [1 2], 'ColumnWidth', {'1x', 350}, 'BackgroundColor', bg);
    head.Layout.Row = 1;
    head.Layout.Column = [1 2];
    uilabel(head, 'Text', 'SOLAR / TRACKER LAB', 'FontSize', 25, 'FontWeight', 'bold', 'FontColor', ink);
    uilabel(head, 'Text', 'MATLAB + Simulink  |  Simulation study', 'FontSize', 13, 'FontColor', muted, 'HorizontalAlignment', 'right');
    side = uigridlayout(g, [18 2], 'RowHeight', {24, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 32, 28, 28, 26}, 'ColumnWidth', {115, '1x'}, 'BackgroundColor', card, 'Padding', [12 10 12 10], 'RowSpacing', 5);
    side.Layout.Row = 2;
    side.Layout.Column = 1;
    titleLabel = uilabel(side, 'Text', 'EXPERIMENT SETTINGS', 'FontWeight', 'bold', 'FontColor', colors(3, :));
    titleLabel.Layout.Column = [1 2];
    lat = number('Latitude (deg)', p.latitude, [-89 89]);
    lon = number('Longitude (deg)', p.longitude, [-180 180]);
    tz = number('UTC offset (h)', p.utcOffset, [-12 14]);
    label('Date');
    dateField = uidatepicker(side, 'Value', p.date);
    label('Weather');
    weather = uidropdown(side, 'Items', {'Clear sky', 'Broken cloud', 'Overcast'}, 'Value', p.weather);
    tilt = number('Fixed tilt (deg)', p.fixedTilt, [0 90]);
    az = number('Fixed azimuth', p.fixedAzimuth, [0 360]);
    rating = number('Module rating (W)', p.rating, [1 100000]);
    ambient = number('Ambient (C)', p.ambient, [-40 65]);
    slew = number('Slew rate (deg/s)', p.slewRate, [0.001 10]);
    deadband = number('Deadband (deg)', p.deadband, [0 10]);
    interval = number('Command every (s)', p.commandInterval, [60 3600]);
    motor = number('Motor per axis (W)', p.motorWatts, [0 1000]);
    runBtn = uibutton(side, 'Text', 'RUN EXPERIMENT', 'BackgroundColor', colors(3, :), 'FontWeight', 'bold', 'ButtonPushedFcn', @runExperiment);
    runBtn.Layout.Column = [1 2];
    exportBtn = uibutton(side, 'Text', 'Export CSV + plots', 'ButtonPushedFcn', @exportResults);
    exportBtn.Layout.Column = [1 2];
    modelBtn = uibutton(side, 'Text', 'Open Simulink model', 'ButtonPushedFcn', @openModel);
    modelBtn.Layout.Column = [1 2];
    status = uilabel(side, 'Text', 'Ready', 'FontColor', ink, 'WordWrap', 'on');
    status.Layout.Column = [1 2];
    status.Layout.Row = 18;
    main = uigridlayout(g, [2 1], 'RowHeight', {92, '1x'}, 'BackgroundColor', bg, 'Padding', [0 0 0 0]);
    main.Layout.Row = 2;
    main.Layout.Column = 2;
    kpiGrid = uigridlayout(main, [2 3], 'RowHeight', {25, '1x'}, 'BackgroundColor', card);
    kpiGrid.Layout.Row = 1;
    kpiGrid.Layout.Column = 1;
    for name = {'FIXED / kWh', 'SINGLE AXIS / kWh', 'DUAL AXIS / NET kWh'}
        uilabel(kpiGrid, 'Text', name{1}, 'FontColor', muted, 'FontSize', 12);
    end
    kpi = gobjects(1, 3);
    for startIndex = 1:3
        kpi(startIndex) = uilabel(kpiGrid, 'Text', '0.00', 'FontSize', 29, 'FontWeight', 'bold', 'FontColor', colors(startIndex, :));
    end
    tabs = uitabgroup(main);
    tabs.Layout.Row = 2;
    tabs.Layout.Column = 1;
    sceneTab = uitab(tabs, 'Title', '3D TRACKER');
    analysisTab = uitab(tabs, 'Title', 'ENERGY & CONTROL');
    infoTab = uitab(tabs, 'Title', 'MODEL & ASSUMPTIONS');
    sceneGrid = uigridlayout(sceneTab, [2 1], 'RowHeight', {'1x', 45}, 'BackgroundColor', card);
    sceneImage = uiimage(sceneGrid, 'ScaleMethod', 'fit');
    % Send rendered images to the app; browser-side axes can fail in MATLAB Online.
    renderFigure = figure('Visible', 'off', 'Color', card, 'Position', [0 0 900 480]);
    scene = axes(renderFigure, 'Position', [.08 .12 .86 .8]);
    style(scene);
    view(scene, 38, 24);
    axis(scene, 'equal');
    xlim(scene, [-4 4]);
    ylim(scene, [-3 3]);
    zlim(scene, [0 5]);
    xlabel(scene, 'East');
    ylabel(scene, 'North');
    zlabel(scene, 'Up');
    sceneInfo = uilabel(sceneGrid, 'Text', '', 'FontColor', ink, 'FontSize', 12, 'WordWrap', 'on');
    plotGrid = uigridlayout(analysisTab, [2 2], 'BackgroundColor', card);
    plotImages = gobjects(1, 4);
    plotFigures = gobjects(1, 4);
    allAxes = gobjects(1, 4);
    for plotIndex = 1:4
        plotImages(plotIndex) = uiimage(plotGrid, 'ScaleMethod', 'fit');
        plotFigures(plotIndex) = figure('Visible', 'off', 'Color', card, 'Position', [0 0 640 360]);
        allAxes(plotIndex) = axes(plotFigures(plotIndex), 'Position', [.12 .18 .83 .72]);
    end
    axesPower = allAxes(1);
    axesEnergy = allAxes(2);
    axesAngle = allAxes(3);
    axesError = allAxes(4);
    for axx = allAxes
        style(axx);
    end
    infoGrid = uigridlayout(infoTab, [1 1]);
    infoText = uitextarea(infoGrid, 'Editable', 'off', 'Value', {'MODEL CHAIN: local clock -> sun vector -> weather -> controller -> orientation -> POA irradiance -> DC power -> net energy';'';'Sun: NOAA fractional-year approximation; geometric elevation, no atmospheric refraction.';'Weather: Haurwitz clear-sky GHI, assumed diffuse fraction; synthetic cloud attenuation. No measured weather input.';'POA: DNI times positive sun/normal dot product + isotropic DHI + albedo reflection.';'PV: nameplate scaling at 1000 W/m2, simplified NOCT temperature, -0.4%/C power coefficient, 10% lumped loss.';'Mechanics: sampled position controller, deadband, 0.2 deg/s default slew; max tilt 85 deg, azimuth +/-175 deg about fixed azimuth.';'Single axis: horizontal north-south rotation axis, +/-60 deg; no row shading or backtracking.';'Night: horizontal parking; motor and standby energy are charged even when PV output is zero.';'Motor: 8 W per moving axis at full slew; duty from movement duration, plus 0.05 W standby per tracker.';'Integration: 60-second rectangles over exactly 24 hours. Timestep convergence is checked separately.';'';'Outputs are modeled DC energy at the module. No inverter clipping, detailed I-V/MPPT, wind torque, structural dynamics, shading, field validation or cost/payback model.';'Tracking changes sunlight captured, not intrinsic cell conversion efficiency.';'See README.md for equations, references, validation and reproduction.'});
    infoText.BackgroundColor = card;
    infoText.FontColor = ink;
    foot = uigridlayout(g, [1 4], 'ColumnWidth', {90, '1x', 80, 180}, 'BackgroundColor', bg, 'Padding', [0 0 0 0]);
    foot.Layout.Row = 3;
    foot.Layout.Column = [1 2];
    play = uibutton(foot, 'Text', 'PLAY', 'ButtonPushedFcn', @togglePlay);
    scrub = uislider(foot, 'Limits', [0 24], 'FontColor', muted, 'Value', 12, 'MajorTicks', 0:6:24, 'ValueChangingFcn', @scrubTime, 'ValueChangedFcn', @scrubTime);
    clock = uilabel(foot, 'Text', '12:00', 'FontColor', ink);
    gain = uilabel(foot, 'Text', '', 'FontColor', colors(3, :), 'FontWeight', 'bold');
    playTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.8, 'TimerFcn', @advance, 'BusyMode', 'drop');
    f.CloseRequestFcn = @closeApp;
    sceneObjects = [];
    sunDot = [];
    sunRay = [];
    sceneFile = [tempname '.png'];
    plotFile = [tempname '.png'];
    updatePlots;
    render;

    function label(txt),
        uilabel(side, 'Text', txt, 'FontColor', ink, 'FontSize', 11);
    end

    function h = number(txt, v, limits),
        label(txt);
        h = uieditfield(side, 'numeric', 'Value', v, 'Limits', limits);
    end

    function style(a),
        a.Color = card;
        a.XColor = muted;
        a.YColor = muted;
        a.ZColor = muted;
        a.GridColor = muted;
        grid(a, 'on');
        a.FontSize = 10;
        a.Title.Color = ink;
    end

    function runExperiment(~, ~)
        stopPlayback;
        status.Text = 'Computing...';
        drawnow;
        try
            p.latitude = lat.Value;
            p.longitude = lon.Value;
            p.utcOffset = tz.Value;
            p.date = dateField.Value;
            p.weather = weather.Value;
            p.fixedTilt = tilt.Value;
            p.fixedAzimuth = az.Value;
            p.rating = rating.Value;
            p.ambient = ambient.Value;
            p.slewRate = slew.Value;
            p.deadband = deadband.Value;
            p.commandInterval = interval.Value;
            p.motorWatts = motor.Value;
            r = tracker_simulate(p);
            idx = min(numel(r.t), max(1, round(scrub.Value*3600/p.dt)+1));
            updatePlots;
            render;
            status.Text = 'Experiment complete';
        catch err
            status.Text = 'Check settings';
            uialert(f, err.message, 'Simulation settings');
        end
    end

    function updatePlots
        for a = allAxes
            cla(a);
        end
        hold(axesPower, 'on');
        hold(axesEnergy, 'on');
        for j = 1:3
            plot(axesPower, r.t/3600, r.power(:, j), 'Color', colors(j, :), 'LineWidth', 1.6);
            plot(axesEnergy, r.t/3600, r.energy(:, j), 'Color', colors(j, :), 'LineWidth', 1.6);
            kpi(j).Text = sprintf('%.3f', r.energy(end, j));
        end
        title(axesPower, 'PV power');
        ylabel(axesPower, 'W');
        legend(axesPower, {'Fixed', 'Single', 'Dual'}, 'TextColor', ink, 'Color', card, 'Location', 'northwest');
        title(axesEnergy, 'Accumulated net energy');
        ylabel(axesEnergy, 'kWh');
        plot(axesAngle, r.t/3600, r.dual(:, 1), 'Color', colors(3, :), 'LineWidth', 1.3);
        hold(axesAngle, 'on');
        plot(axesAngle, r.t/3600, r.dual(:, 2), 'Color', colors(2, :));
        title(axesAngle, 'Actual dual-axis orientation');
        ylabel(axesAngle, 'degrees');
        legend(axesAngle, {'Azimuth', 'Normal elevation'}, 'TextColor', ink, 'Color', card);
        plot(axesError, r.t/3600, r.error, 'Color', colors(3, :));
        title(axesError, 'Sun / panel-normal error');
        ylabel(axesError, 'degrees');
        for a = allAxes
            xlim(a, [0 24]);
            xlabel(a, 'Local time / h');
        end
        gain.Text = sprintf('Net gain: %+.1f%%', r.gain);
        for plotIndex = 1:4
            exportgraphics(plotFigures(plotIndex), plotFile, 'Resolution', 110);
            plotImages(plotIndex).ImageSource = imread(plotFile);
        end
    end

    function render
        if ~isvalid(f)
            return,
        end
        if isempty(sceneObjects)
            hold(scene, 'on');
            patch(scene, [-4 4 4 -4], [-3 -3 3 3], [0 0 0 0], [0.10 0.18 0.17], 'EdgeColor', 'none');
            sceneObjects = cell(1, 3);
            sunDot = plot3(scene, 0, 0, 0, 'o', 'MarkerSize', 18, 'MarkerFaceColor', [1 .85 .35], 'MarkerEdgeColor', 'none');
            sunRay = quiver3(scene, 2.1, 0, 1.25, 0, 0, 0, 0, 'Color', [1 .85 .35], 'LineStyle', '--', 'LineWidth', 1.5);
        end
        panel([-2.1 0 1.25], [sind(p.fixedTilt)*sind(p.fixedAzimuth) sind(p.fixedTilt)*cosd(p.fixedAzimuth) cosd(p.fixedTilt)], colors(1, :), 'FIXED', 1);
        panel([0 0 1.25], [sind(r.single(idx)) 0 cosd(r.single(idx))], colors(2, :), 'SINGLE', 2);
        normal = [cosd(r.dual(idx, 2))*sind(r.dual(idx, 1)) cosd(r.dual(idx, 2))*cosd(r.dual(idx, 1)) sind(r.dual(idx, 2))];
        panel([2.1 0 1.25], normal, colors(3, :), 'DUAL', 3);
        sv = r.sun.vector(idx, :);
        set(sunDot, 'XData', sv(1)*3.5, 'YData', sv(2)*3.5, 'ZData', sv(3)*3.5+1);
        set(sunRay, 'UData', sv(1)*2, 'VData', sv(2)*2, 'WData', sv(3)*2);
        if sv(3)>0
            sunDot.Visible = 'on';
            sunRay.Visible = 'on';
        else
            sunDot.Visible = 'off';
            sunRay.Visible = 'off';
        end
        xlim(scene, [-4 4]);
        ylim(scene, [-3 3]);
        zlim(scene, [0 5]);
        view(scene, 38, 24);
        title(scene, sprintf('%s | %s', datestr(p.date, 'dd mmm yyyy'), p.weather), 'Color', ink);
        sceneInfo.Text = sprintf('Sun elevation %.1f deg  |  Panel tilt %.1f deg  |  Dual %.0f W  |  Motor %.2f W\nEnergy so far: fixed %.3f / single %.3f / dual %.3f kWh', r.sun.elevation(idx), 90-r.dual(idx, 2), r.power(idx, 3), r.motor(idx, 3), r.energy(idx, :));
        clock.Text = sprintf('%02d:%02d', floor(r.t(idx)/3600), floor(mod(r.t(idx), 3600)/60));
        exportgraphics(renderFigure, sceneFile, 'Resolution', 100);
        sceneImage.ImageSource = imread(sceneFile);
    end

    function panel(center, normal, col, name, n)
        edge = cross([0 0 1], normal);
        if norm(edge)<1e-8
            edge = [1 0 0];
        else
            edge = edge/norm(edge);
        end
        other = cross(normal, edge);
        corners = [-0.8 -0.48;0.8 -0.48;0.8 0.48;-0.8 0.48];
        vertices = center+corners(:, 1)*edge+corners(:, 2)*other;
        if isempty(sceneObjects{n})
            h.face = patch(scene, 'Vertices', vertices, 'Faces', [1 2 3 4], 'FaceColor', col*.60, 'EdgeColor', col, 'LineWidth', 2);
            h.cells = gobjects(1, 11);
            for q = 1:11
                h.cells(q) = plot3(scene, [0 0], [0 0], [0 0], 'Color', col);
            end
            plot3(scene, [center(1) center(1)], [center(2) center(2)], [0 center(3)], 'Color', muted, 'LineWidth', 5);
            h.normal = quiver3(scene, center(1), center(2), center(3), 0, 0, 0, 0, 'Color', col, 'LineWidth', 1.5);
            text(scene, center(1), center(2)-1, 0.15, name, 'Color', col, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            sceneObjects{n} = h;
        end
        h = sceneObjects{n};
        h.face.Vertices = vertices;
        q = 0;
        for v = linspace(-.8, .8, 7)
            q = q+1;
            a = center+v*edge-.48*other;
            b = center+v*edge+.48*other;
            set(h.cells(q), 'XData', [a(1) b(1)], 'YData', [a(2) b(2)], 'ZData', [a(3) b(3)]);
        end
        for v = linspace(-.48, .48, 4)
            q = q+1;
            a = center-.8*edge+v*other;
            b = center+.8*edge+v*other;
            set(h.cells(q), 'XData', [a(1) b(1)], 'YData', [a(2) b(2)], 'ZData', [a(3) b(3)]);
        end
        set(h.normal, 'UData', normal(1), 'VData', normal(2), 'WData', normal(3));
    end

    function scrubTime(~, event),
        idx = min(numel(r.t), max(1, round(event.Value*3600/p.dt)+1));
        render;
    end

    function togglePlay(~, ~),
        if strcmp(playTimer.Running, 'on')
            stopPlayback;
        else
            play.Text = 'PAUSE';
            start(playTimer);
        end
    end

    function stopPlayback,
        if strcmp(playTimer.Running, 'on')
            stop(playTimer);
        end
        play.Text = 'PLAY';
    end

    function advance(~, ~),
        idx = idx+10;
        if idx>numel(r.t)
            idx = 1;
        end
        scrub.Value = r.t(idx)/3600;
        render;
        drawnow limitrate;
    end

    function exportResults(~, ~)
        stopPlayback;
        try
            folder = tracker_export(r);
            exportgraphics(scene, fullfile(folder, 'scene.png'), 'Resolution', 160);
            exportapp(f, fullfile(folder, 'dashboard.png'));
            status.Text = ['Saved: ' folder];
        catch err
            uialert(f, err.message, 'Export error');
        end
    end

    function openModel(~, ~)
        stopPlayback;
        try
            tracker_build_simulink(p);
            open_system('SolarTrackerSystem');
            status.Text = 'Simulink model ready';
        catch err
            uialert(f, err.message, 'Simulink');
        end
    end

    function closeApp(~, ~)
        stop(playTimer);
        delete(playTimer);
        delete(renderFigure);
        delete(plotFigures);
        if isfile(sceneFile)
            delete(sceneFile);
        end
        if isfile(plotFile)
            delete(plotFile);
        end
        delete(f);
    end
end
