classdef ImuCalibrationGui < matlab.apps.AppBase
    % Properties corresponding to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        StartCaptureButton        matlab.ui.control.Button
        EstimateParamsButton      matlab.ui.control.Button
        PlotRawVsCalibratedButton matlab.ui.control.Button
        SaveProfileButton         matlab.ui.control.Button
        UIAxes                    matlab.ui.control.UIAxes
    end

    properties (Access = private)
        RawAccData     struct
        RawGyroData    struct
        CalibratedAccData  double
        CalibratedGyroData double
        BiasAcc        double
        BiasGyro       double
        ScaleAcc       double
        ScaleGyro      double
    end

    methods (Access = private)
       function StartCapture(app)
    % Run simulation
    simOut = sim('Imu_sensor_module', 'SimulationMode', 'normal', 'StopTime', '10');
    
    % Get accelerometer data
    if isfield(simOut, 'Accel_meas')
        app.RawAccData = simOut.Accel_meas;
    else
        % Check base workspace as fallback
        try
            app.RawAccData = evalin('base', 'Accel_meas');
        catch
            error('Accelerometer data not found in workspace or simulation output.');
        end
    end
    
    % Get gyroscope data
    if isfield(simOut, 'Gyro_meas')
        app.RawGyroData = simOut.Gyro_meas;
    else
        % Check base workspace as fallback
        try
            app.RawGyroData = evalin('base', 'Gyro_meas');
        catch
            error('Gyroscope data not found in workspace or simulation output.');
        end
    end
end

        function EstimateCalibration(app)
            if isempty(app.RawAccData) || isempty(app.RawGyroData)
                uialert(app.UIFigure, 'Capture data first.', 'Error');
                return;
            end
            
            % Extract values from structure
            acc_values = app.RawAccData.signals.values;
            gyro_values = app.RawGyroData.signals.values;
            
            % Calculate calibration parameters
            app.BiasAcc = mean(acc_values, 1);  % Mean across rows
            app.ScaleAcc = max(acc_values) - min(acc_values);
            app.CalibratedAccData = (acc_values - app.BiasAcc) ./ app.ScaleAcc;
            
            app.BiasGyro = mean(gyro_values, 1);
            app.ScaleGyro = max(gyro_values) - min(gyro_values);
            app.CalibratedGyroData = (gyro_values - app.BiasGyro) ./ app.ScaleGyro;
        end

        function PlotData(app)
    if isempty(app.RawAccData) || isempty(app.CalibratedAccData) || ...
       isempty(app.RawGyroData) || isempty(app.CalibratedGyroData)
        uialert(app.UIFigure, 'Calibrate data first.', 'Error');
        return;
    end

    % Clear previous plots
    cla(app.UIAxes);
    
    % Plot accelerometer data
    plot(app.UIAxes, app.RawAccData.time, app.RawAccData.signals.values, '--', ...
         app.RawAccData.time, app.CalibratedAccData, '-', 'LineWidth', 1.5);
    hold(app.UIAxes, 'on');
    
    % Plot gyroscope data
    plot(app.UIAxes, app.RawGyroData.time, app.RawGyroData.signals.values, '--', ...
         app.RawGyroData.time, app.CalibratedGyroData, '-', 'LineWidth', 1.5);
    hold(app.UIAxes, 'off');
    
    % Add labels and legend
    title(app.UIAxes, 'IMU Calibration Results');
    xlabel(app.UIAxes, 'Time (s)');
    ylabel(app.UIAxes, 'Measurement Values');
    legend(app.UIAxes, {'Raw Acc X','Raw Acc Y','Raw Acc Z', ...
                        'Cal Acc X','Cal Acc Y','Cal Acc Z', ...
                        'Raw Gyro X','Raw Gyro Y','Raw Gyro Z', ...
                        'Cal Gyro X','Cal Gyro Y','Cal Gyro Z'}, ...
           'Location', 'eastoutside');
    grid(app.UIAxes, 'on');
end


        function SaveProfile(app)
            if isempty(app.BiasAcc) || isempty(app.ScaleAcc) || ...
               isempty(app.BiasGyro) || isempty(app.ScaleGyro)
                uialert(app.UIFigure, 'No calibration data to save.', 'Error');
                return;
            end
            
            [file, path] = uiputfile('*.mat', 'Save Calibration Profile');
            if ~isequal(file, 0)
                bias_acc = app.BiasAcc;
                scale_acc = app.ScaleAcc;
                bias_gyro = app.BiasGyro;
                scale_gyro = app.ScaleGyro;
                save(fullfile(path, file), 'bias_acc', 'scale_acc', 'bias_gyro', 'scale_gyro');
            end
        end
    end

    methods (Access = private)
        % Button callbacks
        function StartCaptureButtonPushed(app, ~)
            StartCapture(app);
            disp('Data capture completed successfully');
        end

        function EstimateParamsButtonPushed(app, ~)
            EstimateCalibration(app);
            disp('Calibration parameters estimated');
        end

        function PlotRawVsCalibratedButtonPushed(app, ~)
            PlotData(app);
        end

        function SaveProfileButtonPushed(app, ~)
            SaveProfile(app);
        end
    end

    methods (Access = public)
        % App initialization and UI setup
        function app = ImuCalibrationGui
            % Create UI components
            app.UIFigure = uifigure('Name', 'IMU Calibration Tool', ...
                                   'Position', [100 100 800 600]);
            
            % Create buttons with proper callback binding
            app.StartCaptureButton = uibutton(app.UIFigure, 'push', ...
                'Position', [20 550 120 30], ...
                'Text', 'Start Capture', ...
                'ButtonPushedFcn', createCallbackFcn(app, @StartCaptureButtonPushed, true));
            
            app.EstimateParamsButton = uibutton(app.UIFigure, 'push', ...
                'Position', [160 550 140 30], ...
                'Text', 'Estimate Parameters', ...
                'ButtonPushedFcn', createCallbackFcn(app, @EstimateParamsButtonPushed, true));
            
            app.PlotRawVsCalibratedButton = uibutton(app.UIFigure, 'push', ...
                'Position', [320 550 160 30], ...
                'Text', 'Plot Data', ...
                'ButtonPushedFcn', createCallbackFcn(app, @PlotRawVsCalibratedButtonPushed, true));
            
            app.SaveProfileButton = uibutton(app.UIFigure, 'push', ...
                'Position', [500 550 120 30], ...
                'Text', 'Save Profile', ...
                'ButtonPushedFcn', createCallbackFcn(app, @SaveProfileButtonPushed, true));
            
            % Create axes for plotting
            app.UIAxes = uiaxes(app.UIFigure, ...
                'Position', [50 50 700 480], ...
                'XTickLabel', {}, 'YTickLabel', {});
            title(app.UIAxes, 'IMU Calibration Results');
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Measurement Values');
            
            % Initialize data storage
            app.RawAccData = struct('time', [], 'signals', struct('values', []));
            app.RawGyroData = struct('time', [], 'signals', struct('values', []));
        end
    end
end
