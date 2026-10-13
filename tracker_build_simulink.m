function model = tracker_build_simulink(p)
    % Build the discrete controller and PV model for the selected settings.
    if nargin==0
        p = tracker_defaults;
    end
    assert(license('test', 'Simulink'), 'Simulink license required.');
    r = tracker_simulate(p);
    model = 'SolarTrackerSystem';
    if bdIsLoaded(model)
        close_system(model, 0);
    end
    new_system(model);
    set_param(model, 'Solver', 'FixedStepDiscrete', 'FixedStep', num2str(p.dt), 'StartTime', '0', 'StopTime', num2str(86400-p.dt), 'ReturnWorkspaceOutputs', 'on');
    ws = get_param(model, 'ModelWorkspace');
    assignin(ws, 'targetInput', timeseries([r.singleTarget r.dualTarget], r.t));
    assignin(ws, 'weatherInput', timeseries(r.env, r.t));
    add_block('simulink/Sources/From Workspace', [model '/Sun commands'], 'VariableName', 'targetInput', 'Interpolate', 'off', 'OutputAfterFinalValue', 'Holding final value', 'Position', [35 55 170 85]);
    add_block('simulink/Discrete/Unit Delay', [model '/Previous angles'], 'InitialCondition', sprintf('[0; %g; 90]', p.fixedAzimuth), 'SampleTime', num2str(p.dt), 'Position', [280 165 410 205]);
    add_block('simulink/User-Defined Functions/MATLAB Function', [model '/Sampled position controller'], 'Position', [225 35 450 115]);
    root = sfroot;
    chart = root.find('-isa', 'Stateflow.EMChart', 'Path', [model '/Sampled position controller']);
    chart.Script = sprintf(['function [angles,motors]=controller(target,previous)\n' ...
    'err=target-previous;\nerr(abs(err)<=%.15g)=0;\nmove=max(-%.15g,min(%.15g,err));\nangles=previous+move;\n' ...
    'motors=[0; %.15g+%.15g*abs(move(1))/%.15g; %.15g+%.15g*(abs(move(2))+abs(move(3)))/%.15g];\nend'], p.deadband, p.slewRate*p.dt, p.slewRate*p.dt, p.standbyWatts, p.motorWatts, p.slewRate*p.dt, p.standbyWatts, p.motorWatts, p.slewRate*p.dt);
    add_block('simulink/Sources/From Workspace', [model '/Common weather and sun'], 'VariableName', 'weatherInput', 'Interpolate', 'off', 'OutputAfterFinalValue', 'Holding final value', 'Position', [35 275 180 310]);
    add_block('simulink/User-Defined Functions/MATLAB Function', [model '/POA temperature PV'], 'Position', [515 225 735 315]);
    chart = root.find('-isa', 'Stateflow.EMChart', 'Path', [model '/POA temperature PV']);
    chart.Script = sprintf(['function power=pv(env,angles)\n' ...
    'normal=[%.15g %.15g %.15g; sin(angles(1)*pi/180) 0 cos(angles(1)*pi/180); cos(angles(3)*pi/180)*sin(angles(2)*pi/180) cos(angles(3)*pi/180)*cos(angles(2)*pi/180) sin(angles(3)*pi/180)];\n' ...
    'power=zeros(3,1);\nfor j=1:3\nmu=max(0,normal(j,:)*env(5:7));\nc=normal(j,3);\npoa=env(1)*mu+env(2)*(1+c)/2+%.15g*env(3)*(1-c)/2;\n' ...
    'temp=env(4)+(%.15g-20)/800*poa;\npower(j)=%.15g*poa/1000*max(0,1+%.15g*(temp-25))*(1-%.15g);\nend\nend'], sind(p.fixedTilt)*sind(p.fixedAzimuth), sind(p.fixedTilt)*cosd(p.fixedAzimuth), cosd(p.fixedTilt), p.albedo, p.noct, p.rating, p.tempCoefficient, p.loss);
    add_block('simulink/Math Operations/Sum', [model '/Net DC power'], 'Inputs', '+-', 'Position', [810 235 845 285]);
    add_block('simulink/Sinks/To Workspace', [model '/Power results'], 'VariableName', 'powerOutput', 'SaveFormat', 'Timeseries', 'Position', [900 235 1030 275]);
    add_block('simulink/Sinks/To Workspace', [model '/Angle results'], 'VariableName', 'angleOutput', 'SaveFormat', 'Timeseries', 'Position', [540 45 680 80]);
    add_block('simulink/Sinks/To Workspace', [model '/Motor results'], 'VariableName', 'motorOutput', 'SaveFormat', 'Timeseries', 'Position', [540 120 680 150]);
    add_block('simulink/Sinks/Scope', [model '/Power comparison'], 'Position', [900 320 1030 360]);
    add_line(model, 'Sun commands/1', 'Sampled position controller/1', 'autorouting', 'on');
    add_line(model, 'Previous angles/1', 'Sampled position controller/2', 'autorouting', 'on');
    add_line(model, 'Sampled position controller/1', 'Previous angles/1', 'autorouting', 'on');
    add_line(model, 'Sampled position controller/1', 'POA temperature PV/2', 'autorouting', 'on');
    add_line(model, 'Sampled position controller/1', 'Angle results/1', 'autorouting', 'on');
    add_line(model, 'Sampled position controller/2', 'Motor results/1', 'autorouting', 'on');
    add_line(model, 'Common weather and sun/1', 'POA temperature PV/1', 'autorouting', 'on');
    add_line(model, 'POA temperature PV/1', 'Net DC power/1', 'autorouting', 'on');
    add_line(model, 'Sampled position controller/2', 'Net DC power/2', 'autorouting', 'on');
    add_line(model, 'Net DC power/1', 'Power results/1', 'autorouting', 'on');
    add_line(model, 'Net DC power/1', 'Power comparison/1', 'autorouting', 'on');
    Simulink.Annotation(model, 'DUAL-AXIS SOLAR TRACKER | Independent discrete feedback simulation');
    save_system(model, fullfile(fileparts(mfilename('fullpath')), [model '.slx']));
end
