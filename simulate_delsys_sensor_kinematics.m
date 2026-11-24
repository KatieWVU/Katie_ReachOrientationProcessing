function manifestTable = simulate_delsys_sensor_kinematics(outputDir, nRate, makePlot)
%SIMULATE_DELSYS_SENSOR_KINEMATICS Simulate active Delsys forearm accelerometer
%   signals across 8 minimum-jerk reaching trajectories and 27 3D sensor
%   orientations (aligned, single-axis +/-45 deg, two-axis combinations, and
%   three-axis combinations about X, Y, and Z), incorporating gravity.
%
%   Usage:
%       manifestTable = simulate_delsys_sensor_kinematics()
%       manifestTable = simulate_delsys_sensor_kinematics(outputDir, nRate, makePlot)
%
%   Inputs (all optional):
%       outputDir - Directory where .mat files and simulation_manifest.csv
%                   are written (default: '<scriptDir>/simulated_sensor_outputs').
%       nRate     - Sampling frequency in Hz (default: 148.15 Hz, Delsys Trigno).
%       makePlot  - Logical flag to generate and save the example figure for
%                   horizontal reach (0 -> +0.2X, 120 bpm) with +45 deg X
%                   sensor rotation (default: true).
%
%   Outputs:
%       manifestTable - MATLAB table summarizing all 216 generated .mat files,
%                       trajectory conditions, sensor orientations, and signal
%                       metrics.
%
%   Coordinate & Sensor Physics Conventions:
%       World frame W:
%           +X_W : Horizontal reach axis (0 <-> +0.2 m)
%           +Y_W : Nominal forearm longitudinal axis (aligned with sensor +Y)
%           +Z_W : Vertically upward (0 <-> +0.2 m)
%           g_W  : Gravitational acceleration = [0; 0; -9.81] m/s^2
%
%       Sensor rotation matrix R in SO(3):
%           R = R_z(rz) * R_y(ry) * R_x(rx)  (extrinsic X-Y-Z / intrinsic Z-Y-X)
%           Iterates cleanly over the 27 orientations (rx, ry, rz) in {-45, 0, +45}^3:
%             Tier 0 (1) : Aligned (0, 0, 0)
%             Tier 1 (6) : Single-axis +45X, -45X, +45Y, -45Y, +45Z, -45Z
%             Tier 2 (12): Two-axis combinations (X&Y, X&Z, Y&Z)
%             Tier 3 (8) : Three-axis combinations (X&Y&Z)
%           Columns of R are local unit vectors [u_x, u_y, u_z] expressed in W.
%
%       Active MEMS accelerometer measurement (specific force):
%           a_sensor_W(t) = a_kin_W(t) - g_W = a_kin_W(t) + [0; 0; +9.81]
%           a_sensor_L(t) = R' * a_sensor_W(t)
%           (e.g., stationary aligned sensor with +Z_L = +Z_W reads +9.81 m/s^2
%           on Z; rotated +45 deg about X reads [0, +6.937, +6.937] m/s^2.)

    %% 1. Default Arguments & Simulation Constants
    scriptDir = fileparts(mfilename('fullpath'));
    if nargin < 1 || isempty(outputDir)
        outputDir = fullfile(scriptDir, 'simulated_sensor_outputs');
    end
    if nargin < 2 || isempty(nRate)
        nRate = 148.15;  % Delsys Trigno accelerometer sampling rate (Hz)
    end
    if nargin < 3 || isempty(makePlot)
        makePlot = true;
    end

    if ~isfolder(outputDir)
        mkdir(outputDir);
    end

    g_mag    = 9.81;              % Standard gravitational acceleration (m/s^2)
    g_world  = [0; 0; -g_mag];    % Gravity vector pointing along -Z_W
    nPad     = 10;                % Stationary samples before & after movement
    tol_orth = 1e-12;             % SO(3) and norm invariance tolerance
    tol_fd   = 5e-2;              % Numerical 2nd-derivative consistency tolerance

    %% 2. Define the 8 Minimum-Jerk Trajectories (via gettragect.m)
    % Fast = 120 bpm (60/120 = 0.50 s), Slow = 80 bpm (60/80 = 0.75 s)
    t_fast = 60.0 / 120.0;
    t_slow = 60.0 / 80.0;

    trajSpecs = [ ...
        struct('id', 1, 'name', 'H_OrigToPos0p2X_120bpm', 'plane', 'Horizontal', ...
               'direction', 'Origin_to_+0.2X', 'bpm', 120, 'tSim', t_fast, ...
               'nROM', [0.0, 0.2; 0.0, 0.0; 0.0, 0.0]);
        struct('id', 2, 'name', 'H_OrigToPos0p2X_80bpm',  'plane', 'Horizontal', ...
               'direction', 'Origin_to_+0.2X', 'bpm', 80,  'tSim', t_slow, ...
               'nROM', [0.0, 0.2; 0.0, 0.0; 0.0, 0.0]);
        struct('id', 3, 'name', 'H_Pos0p2XToOrig_120bpm', 'plane', 'Horizontal', ...
               'direction', '+0.2X_to_Origin', 'bpm', 120, 'tSim', t_fast, ...
               'nROM', [0.2, 0.0; 0.0, 0.0; 0.0, 0.0]);
        struct('id', 4, 'name', 'H_Pos0p2XToOrig_80bpm',  'plane', 'Horizontal', ...
               'direction', '+0.2X_to_Origin', 'bpm', 80,  'tSim', t_slow, ...
               'nROM', [0.2, 0.0; 0.0, 0.0; 0.0, 0.0]);
        struct('id', 5, 'name', 'V_OrigToPos0p2Z_120bpm', 'plane', 'Vertical', ...
               'direction', 'Origin_to_+0.2Z', 'bpm', 120, 'tSim', t_fast, ...
               'nROM', [0.0, 0.0; 0.0, 0.0; 0.0, 0.2]);
        struct('id', 6, 'name', 'V_OrigToPos0p2Z_80bpm',  'plane', 'Vertical', ...
               'direction', 'Origin_to_+0.2Z', 'bpm', 80,  'tSim', t_slow, ...
               'nROM', [0.0, 0.0; 0.0, 0.0; 0.0, 0.2]);
        struct('id', 7, 'name', 'V_Pos0p2ZToOrig_120bpm', 'plane', 'Vertical', ...
               'direction', '+0.2Z_to_Origin', 'bpm', 120, 'tSim', t_fast, ...
               'nROM', [0.0, 0.0; 0.0, 0.0; 0.2, 0.0]);
        struct('id', 8, 'name', 'V_Pos0p2ZToOrig_80bpm',  'plane', 'Vertical', ...
               'direction', '+0.2Z_to_Origin', 'bpm', 80,  'tSim', t_slow, ...
               'nROM', [0.0, 0.0; 0.0, 0.0; 0.2, 0.0]) ...
    ];

    sAngList = {'X', 'Y', 'Z'};
    nTraj    = numel(trajSpecs);
    trajs    = cell(nTraj, 1);

    for iT = 1:nTraj
        spec = trajSpecs(iT);
        [posS, velS, accS] = gettragect(nRate, spec.tSim, sAngList, spec.nROM, 0, nPad);

        tTime = posS.tTime(:);
        p_W   = [posS.X(:), posS.Y(:), posS.Z(:)];
        v_W   = [velS.X(:), velS.Y(:), velS.Z(:)];
        a_W   = [accS.X(:), accS.Y(:), accS.Z(:)];

        % Verify trajectory endpoints, boundary rest conditions, peak velocity,
        % and numerical second-derivative agreement on the active movement segment.
        assert(norm(p_W(1, :) - spec.nROM(:, 1).') < tol_orth, ...
            'Start position mismatch for %s.', spec.name);
        assert(norm(p_W(end, :) - spec.nROM(:, 2).') < tol_orth, ...
            'End position mismatch for %s.', spec.name);
        assert(norm(v_W(1, :)) < tol_orth && norm(v_W(end, :)) < tol_orth, ...
            'Boundary velocity is non-zero for %s.', spec.name);
        assert(norm(a_W(1, :)) < tol_orth && norm(a_W(end, :)) < tol_orth, ...
            'Boundary acceleration is non-zero for %s.', spec.name);

        % Check numerical 2nd derivative inside the smooth movement segment
        idxMove = (nPad + 1):(numel(tTime) - nPad);
        a_W_fd  = computeNumericalAccel2nd(tTime(idxMove), p_W(idxMove, :));
        fd_err  = max(vecnorm(a_W_fd(2:end-1, :) - a_W(idxMove(2:end-1), :), 2, 2));
        assert(fd_err < tol_fd, ...
            'Numerical vs. analytical acceleration mismatch for %s: %.3e m/s^2', ...
            spec.name, fd_err);

        % Check theoretical minimum-jerk peak speed: v_peak = (15/8) * |dx| / T_eff
        T_eff = tTime(idxMove(end)) - tTime(idxMove(1));
        v_peak_expected = (15.0 / 8.0) * 0.2 / T_eff;
        v_peak_actual   = max(vecnorm(v_W, 2, 2));
        assert(abs(v_peak_actual - v_peak_expected) < 1e-3, ...
            'Peak velocity mismatch for %s: got %.4f, expected %.4f m/s', ...
            spec.name, v_peak_actual, v_peak_expected);

        trajs{iT} = struct( ...
            'spec',   spec, ...
            'tTime',  tTime, ...
            'p_W',    p_W, ...
            'v_W',    v_W, ...
            'a_W',    a_W, ...
            'fd_err', fd_err, ...
            'T_eff',  T_eff);
    end

    %% 3. Build Ordered 27-Orientation Grid (Aligned -> 1-Axis -> 2-Axis -> 3-Axis)
    % Tier 0 (1) : (0, 0, 0)
    % Tier 1 (6) : (+45X, -45X, +45Y, -45Y, +45Z, -45Z)
    % Tier 2 (12): (+/-45X & +/-45Y), (+/-45X & +/-45Z), (+/-45Y & +/-45Z)
    % Tier 3 (8) : (+/-45X & +/-45Y & +/-45Z)
    angleList = [ ...
          0,   0,   0; ...  % Tier 0: Aligned
         45,   0,   0; ...  % Tier 1: Single-axis
        -45,   0,   0; ...
          0,  45,   0; ...
          0, -45,   0; ...
          0,   0,  45; ...
          0,   0, -45; ...
         45,  45,   0; ...  % Tier 2: Two-axis (X & Y)
         45, -45,   0; ...
        -45,  45,   0; ...
        -45, -45,   0; ...
         45,   0,  45; ...  % Tier 2: Two-axis (X & Z)
         45,   0, -45; ...
        -45,   0,  45; ...
        -45,   0, -45; ...
          0,  45,  45; ...  % Tier 2: Two-axis (Y & Z)
          0,  45, -45; ...
          0, -45,  45; ...
          0, -45, -45; ...
         45,  45,  45; ...  % Tier 3: Three-axis (X & Y & Z)
         45,  45, -45; ...
         45, -45,  45; ...
         45, -45, -45; ...
        -45,  45,  45; ...
        -45,  45, -45; ...
        -45, -45,  45; ...
        -45, -45, -45 ...
    ];

    nOrient = size(angleList, 1);
    orients = repmat(struct('rx', 0, 'ry', 0, 'rz', 0, 'rotGroup', '', ...
                            'tag', '', 'R', eye(3)), nOrient, 1);

    for idxO = 1:nOrient
        rx = angleList(idxO, 1);
        ry = angleList(idxO, 2);
        rz = angleList(idxO, 3);
        R  = buildRotationZYX(rx, ry, rz);

        % Verify SO(3) properties for every orientation
        assert(abs(det(R) - 1.0) < tol_orth, ...
            'det(R) ~= 1 for (rx=%d, ry=%d, rz=%d).', rx, ry, rz);
        assert(norm(R.' * R - eye(3), 'fro') < tol_orth, ...
            'R''*R ~= I for (rx=%d, ry=%d, rz=%d).', rx, ry, rz);
        assert(all(abs(vecnorm(R, 2, 1) - 1.0) < tol_orth), ...
            'Basis vectors not unit length for (rx=%d, ry=%d, rz=%d).', rx, ry, rz);
        assert(norm(cross(R(:, 1), R(:, 2)) - R(:, 3)) < tol_orth, ...
            'Basis not right-handed for (rx=%d, ry=%d, rz=%d).', rx, ry, rz);

        nNonZero = nnz([rx, ry, rz]);
        switch nNonZero
            case 0
                rotGroup = 'Aligned';
            case 1
                rotGroup = 'SingleAxis';
            case 2
                rotGroup = 'TwoAxis';
            otherwise
                rotGroup = 'ThreeAxis';
        end

        tag = sprintf('Rx%s_Ry%s_Rz%s', ...
            formatAngleTag(rx), formatAngleTag(ry), formatAngleTag(rz));

        orients(idxO).rx       = rx;
        orients(idxO).ry       = ry;
        orients(idxO).rz       = rz;
        orients(idxO).rotGroup = rotGroup;
        orients(idxO).tag      = tag;
        orients(idxO).R        = R;
    end

    % Verify all 27 rotation matrices are strictly pairwise distinct
    for a = 1:(nOrient - 1)
        for b = (a + 1):nOrient
            assert(norm(orients(a).R - orients(b).R, 'fro') > 1e-6, ...
                'Duplicate rotation matrix detected between %s and %s.', ...
                orients(a).tag, orients(b).tag);
        end
    end

    %% 4. Simulate All 8 x 27 = 216 Conditions & Export .mat Files
    nRuns = nTraj * nOrient;
    FileName       = strings(nRuns, 1);
    TrajectoryName = strings(nRuns, 1);
    Plane          = strings(nRuns, 1);
    Direction      = strings(nRuns, 1);
    PaceBPM        = zeros(nRuns, 1);
    DurationSec    = zeros(nRuns, 1);
    RotationGroup  = strings(nRuns, 1);
    RotX_deg       = zeros(nRuns, 1);
    RotY_deg       = zeros(nRuns, 1);
    RotZ_deg       = zeros(nRuns, 1);
    StaticAx_L     = zeros(nRuns, 1);
    StaticAy_L     = zeros(nRuns, 1);
    StaticAz_L     = zeros(nRuns, 1);
    PeakAbsAx_L    = zeros(nRuns, 1);
    PeakAbsAy_L    = zeros(nRuns, 1);
    PeakAbsAz_L    = zeros(nRuns, 1);

    exampleData = [];
    runIdx = 0;

    for iT = 1:nTraj
        tr   = trajs{iT};
        spec = tr.spec;

        % World-frame active accelerometer specific force: a_meas_W = a_kin_W - g_W
        a_W_kin    = tr.a_W;
        a_W_sensor = a_W_kin - g_world.';  % N x 3, adds +9.81 m/s^2 to Z_W

        for iO = 1:nOrient
            runIdx = runIdx + 1;
            ori = orients(iO);
            R   = ori.R;

            % Transform kinematic and active-sensor accelerations into Local frame L
            a_L_kin      = (R.' * a_W_kin.').';
            a_L_sensor   = (R.' * a_W_sensor.').';
            a_L_sensor_g = a_L_sensor ./ g_mag;

            % Verify Euclidean norm invariance under rigid rotation
            norm_err_kin = max(abs(vecnorm(a_L_kin, 2, 2) - vecnorm(a_W_kin, 2, 2)));
            norm_err_sen = max(abs(vecnorm(a_L_sensor, 2, 2) - vecnorm(a_W_sensor, 2, 2)));
            assert(norm_err_kin < tol_orth && norm_err_sen < tol_orth, ...
                'Euclidean acceleration norm not preserved for %s / %s.', ...
                spec.name, ori.tag);

            % Spot-check static gravity physics at rest (sample 1)
            if ori.rx == 0 && ori.ry == 0 && ori.rz == 0
                assert(norm(a_L_sensor(1, :) - [0, 0, g_mag]) < tol_orth, ...
                    'Aligned sensor static gravity mismatch.');
            elseif ori.rx == 45 && ori.ry == 0 && ori.rz == 0
                expected_g = [0, g_mag * sin(pi/4), g_mag * cos(pi/4)];
                assert(norm(a_L_sensor(1, :) - expected_g) < tol_orth, ...
                    'Rx=+45 deg sensor static gravity mismatch.');
            elseif ori.rx == 0 && ori.ry == 45 && ori.rz == 0
                expected_g = [-g_mag * sin(pi/4), 0, g_mag * cos(pi/4)];
                assert(norm(a_L_sensor(1, :) - expected_g) < tol_orth, ...
                    'Ry=+45 deg sensor static gravity mismatch.');
            end

            % Build self-contained output structure for this condition
            fname    = sprintf('%s_%s.mat', spec.name, ori.tag);
            fullPath = fullfile(outputDir, fname);

            simData = struct();
            simData.condition = struct( ...
                'fileName',        fname, ...
                'trajectoryId',    spec.id, ...
                'trajectoryName',  spec.name, ...
                'plane',           spec.plane, ...
                'direction',       spec.direction, ...
                'bpm',             spec.bpm, ...
                'tSimNominal_s',   spec.tSim, ...
                'tMoveActual_s',   tr.T_eff, ...
                'nRate_Hz',        nRate, ...
                'nPadSamples',     nPad, ...
                'rotationGroup',   ori.rotGroup, ...
                'rot_deg',         [ori.rx, ori.ry, ori.rz], ...
                'eulerOrder',      'R = Rz(rz) * Ry(ry) * Rx(rx)', ...
                'gravityModel',    'a_sensor_L = R'' * (a_kin_W - g_W), g_W = [0; 0; -9.81] m/s^2');
            simData.tTime               = tr.tTime;
            simData.R                   = R;
            simData.basis_L             = R;
            simData.g_world             = g_world;
            simData.pos_world           = tr.p_W;
            simData.vel_world           = tr.v_W;
            simData.acc_world_kinematic = a_W_kin;
            simData.acc_world_sensor    = a_W_sensor;
            simData.acc_local_kinematic = a_L_kin;
            simData.acc_local_sensor    = a_L_sensor;     % [N x 3] m/s^2 (active sensor output)
            simData.acc_local_sensor_g  = a_L_sensor_g;   % [N x 3] in units of g

            % Save directly with top-level variables for easy MATLAB loading
            save(fullPath, '-struct', 'simData');

            % Capture requested example: Horizontal origin -> +0.2X (120 bpm), Rx = +45 deg
            if spec.id == 1 && ori.rx == 45 && ori.ry == 0 && ori.rz == 0
                exampleData = simData;
            end

            % Record row in master manifest
            FileName(runIdx)       = string(fname);
            TrajectoryName(runIdx) = string(spec.name);
            Plane(runIdx)          = string(spec.plane);
            Direction(runIdx)      = string(spec.direction);
            PaceBPM(runIdx)        = spec.bpm;
            DurationSec(runIdx)    = spec.tSim;
            RotationGroup(runIdx)  = string(ori.rotGroup);
            RotX_deg(runIdx)       = ori.rx;
            RotY_deg(runIdx)       = ori.ry;
            RotZ_deg(runIdx)       = ori.rz;
            StaticAx_L(runIdx)     = a_L_sensor(1, 1);
            StaticAy_L(runIdx)     = a_L_sensor(1, 2);
            StaticAz_L(runIdx)     = a_L_sensor(1, 3);
            PeakAbsAx_L(runIdx)    = max(abs(a_L_sensor(:, 1)));
            PeakAbsAy_L(runIdx)    = max(abs(a_L_sensor(:, 2)));
            PeakAbsAz_L(runIdx)    = max(abs(a_L_sensor(:, 3)));
        end
    end

    manifestTable = table( ...
        FileName, TrajectoryName, Plane, Direction, PaceBPM, DurationSec, ...
        RotationGroup, RotX_deg, RotY_deg, RotZ_deg, ...
        StaticAx_L, StaticAy_L, StaticAz_L, ...
        PeakAbsAx_L, PeakAbsAy_L, PeakAbsAz_L);

    manifestCsvPath = fullfile(outputDir, 'simulation_manifest.csv');
    writetable(manifestTable, manifestCsvPath);

    fprintf('=========================================================================\n');
    fprintf('  DELSYS FOREARM ACCELEROMETER KINEMATICS SIMULATION COMPLETE\n');
    fprintf('=========================================================================\n');
    fprintf('  Sampling Rate       : %.2f Hz (dt = %.5f s)\n', nRate, 1/nRate);
    fprintf('  Trajectories        : %d (4 Horizontal, 4 Vertical; 120 & 80 bpm)\n', nTraj);
    fprintf('  Sensor Orientations : %d unique SO(3) orientations (Aligned + 1/2/3-axis +/-45 deg)\n', nOrient);
    fprintf('  Total .mat Files    : %d saved to %s\n', nRuns, outputDir);
    fprintf('  Master Manifest     : %s\n', manifestCsvPath);
    fprintf('  All SO(3), trajectory, and gravity-invariance assertions: PASS\n');
    fprintf('=========================================================================\n');

    %% 5. Plot Example Condition: Horizontal 0 -> +0.2X (120 bpm), Rx = +45 deg
    if makePlot && ~isempty(exampleData)
        plotPath = fullfile(scriptDir, 'example_H_OrigToPos0p2X_Rxp45.png');
        plotExampleCondition(exampleData, plotPath);
        fprintf('  Saved example plot  : %s\n', plotPath);
    end
end

%% ========================================================================
%  Local Helper Functions
%  ========================================================================

function R = buildRotationZYX(rx_deg, ry_deg, rz_deg)
%BUILDROTATIONZYX Construct proper rotation matrix R = Rz(rz) * Ry(ry) * Rx(rx).
    cx = cosd(rx_deg); sx = sind(rx_deg);
    cy = cosd(ry_deg); sy = sind(ry_deg);
    cz = cosd(rz_deg); sz = sind(rz_deg);

    Rx = [ 1,   0,   0;
           0,  cx, -sx;
           0,  sx,  cx ];

    Ry = [ cy,  0,  sy;
            0,  1,   0;
          -sy,  0,  cy ];

    Rz = [ cz, -sz,  0;
           sz,  cz,  0;
            0,   0,  1 ];

    R = Rz * Ry * Rx;
end

function tag = formatAngleTag(angle_deg)
%FORMATANGLETAG Format signed integer angle for clean filenames (e.g., p45, m45, 0).
    if angle_deg > 0
        tag = sprintf('p%d', round(angle_deg));
    elseif angle_deg < 0
        tag = sprintf('m%d', abs(round(angle_deg)));
    else
        tag = '0';
    end
end

function acc_fd = computeNumericalAccel2nd(t, pos)
%COMPUTENUMERICALACCEL2ND 2nd-order central-difference acceleration check.
    dt = t(2) - t(1);
    acc_fd = zeros(size(pos));
    acc_fd(2:end-1, :) = (pos(3:end, :) - 2 * pos(2:end-1, :) + pos(1:end-2, :)) / (dt^2);
    acc_fd(1, :)       = acc_fd(2, :);
    acc_fd(end, :)     = acc_fd(end-1, :);
end

function plotExampleCondition(simData, plotPath)
%PLOTEXAMPLECONDITION Generate 3-panel verification plot for the requested
%   horizontal reach (0 -> +0.2X, 120 bpm) with +45 deg X sensor rotation.
    t       = simData.tTime;
    p_W     = simData.pos_world;
    v_W     = simData.vel_world;
    a_W_kin = simData.acc_world_kinematic;
    a_L_kin = simData.acc_local_kinematic;
    a_L_sen = simData.acc_local_sensor;
    R       = simData.R;

    u_x = R(:, 1);
    u_y = R(:, 2);
    u_z = R(:, 3);

    col_x = [0.85, 0.15, 0.15];
    col_y = [0.10, 0.62, 0.25];
    col_z = [0.10, 0.40, 0.85];

    fig = figure('Name', 'Delsys Forearm Sensor Simulation Example', ...
                 'Color', 'w', ...
                 'Units', 'pixels', ...
                 'Position', [80, 80, 1450, 760]);

    tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, 'Delsys Forearm Sensor Simulation: Horizontal Reach (0 \rightarrow +0.2 m X, 120 bpm) | Sensor Rotated +45^\circ about X', ...
        'FontSize', 12.5, 'FontWeight', 'bold');

    % --- Left Panel (spanning 2 rows): 3D Trajectory, World Frame, Gravity, & Rotated Sensor Triads ---
    ax1 = nexttile(tl, 1, [2, 1]);
    hold(ax1, 'on');
    grid(ax1, 'on');
    box(ax1, 'on');

    % World frame reference axes at origin
    wScale = 0.085;
    quiver3(ax1, 0, 0, 0, wScale, 0, 0, 0, 'Color', [0.45, 0.45, 0.45], 'LineWidth', 1.4, 'LineStyle', '--', 'MaxHeadSize', 0.35);
    quiver3(ax1, 0, 0, 0, 0, wScale, 0, 0, 'Color', [0.45, 0.45, 0.45], 'LineWidth', 1.4, 'LineStyle', '--', 'MaxHeadSize', 0.35);
    quiver3(ax1, 0, 0, 0, 0, 0, wScale, 0, 'Color', [0.45, 0.45, 0.45], 'LineWidth', 1.4, 'LineStyle', '--', 'MaxHeadSize', 0.35);
    text(ax1, wScale * 1.12, 0, 0, 'X_W', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.35, 0.35, 0.35]);
    text(ax1, 0, wScale * 1.12, 0, 'Y_W', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.35, 0.35, 0.35]);
    text(ax1, 0, 0, wScale * 1.12, 'Z_W', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.35, 0.35, 0.35]);

    % Gravity vector arrow pointing along -Z_W
    h_g = quiver3(ax1, -0.04, 0, 0.04, 0, 0, -0.08, 0, ...
        'Color', [0.55, 0.15, 0.70], 'LineWidth', 2.4, 'MaxHeadSize', 0.45, ...
        'DisplayName', 'Gravity $\mathbf{g}_W$ ($-9.81\;\mathrm{m/s}^2\,\hat{K}$)');
    text(ax1, -0.04, 0, -0.052, 'g_W', 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.55, 0.15, 0.70]);

    % Trajectory path
    h_traj = plot3(ax1, p_W(:, 1), p_W(:, 2), p_W(:, 3), '-', ...
        'Color', [0.15, 0.15, 0.20], 'LineWidth', 2.6, 'DisplayName', 'Origin Path $\mathbf{p}(t)$');
    h_start = plot3(ax1, p_W(1, 1), p_W(1, 2), p_W(1, 3), 'o', ...
        'MarkerSize', 8, 'MarkerFaceColor', [0.15, 0.70, 0.30], 'MarkerEdgeColor', 'k', ...
        'DisplayName', 'Start ($0$ m)');
    h_end = plot3(ax1, p_W(end, 1), p_W(end, 2), p_W(end, 3), 's', ...
        'MarkerSize', 8, 'MarkerFaceColor', [0.85, 0.25, 0.25], 'MarkerEdgeColor', 'k', ...
        'DisplayName', 'End ($+0.20$ m)');

    % Plot 5 evenly spaced rotated sensor triads along the 0 -> 0.20 m reach
    xTargets = linspace(p_W(1, 1), p_W(end, 1), 5);
    P_s      = [xTargets(:), zeros(5, 1), zeros(5, 1)];
    nS       = size(P_s, 1);
    tScale   = 0.052;

    Ux = repmat((tScale * u_x).', nS, 1);
    Uy = repmat((tScale * u_y).', nS, 1);
    Uz = repmat((tScale * u_z).', nS, 1);

    h_ux = quiver3(ax1, P_s(:, 1), P_s(:, 2), P_s(:, 3), Ux(:, 1), Ux(:, 2), Ux(:, 3), 0, ...
        'Color', col_x, 'LineWidth', 2.0, 'MaxHeadSize', 0.45, 'DisplayName', 'Sensor $\hat{u}_x$');
    h_uy = quiver3(ax1, P_s(:, 1), P_s(:, 2), P_s(:, 3), Uy(:, 1), Uy(:, 2), Uy(:, 3), 0, ...
        'Color', col_y, 'LineWidth', 2.0, 'MaxHeadSize', 0.45, 'DisplayName', 'Sensor $\hat{u}_y$');
    h_uz = quiver3(ax1, P_s(:, 1), P_s(:, 2), P_s(:, 3), Uz(:, 1), Uz(:, 2), Uz(:, 3), 0, ...
        'Color', col_z, 'LineWidth', 2.0, 'MaxHeadSize', 0.45, 'DisplayName', 'Sensor $\hat{u}_z$');

    axis(ax1, 'equal');
    xlim(ax1, [-0.08, 0.28]);
    ylim(ax1, [-0.10, 0.12]);
    zlim(ax1, [-0.08, 0.12]);
    xlabel(ax1, 'X_W (m)', 'FontWeight', 'bold');
    ylabel(ax1, 'Y_W (m) [Forearm Axis]', 'FontWeight', 'bold');
    zlabel(ax1, 'Z_W (m) [Vertical]', 'FontWeight', 'bold');
    title(ax1, '3D Reach Path & Rotated Sensor Frame (R_x = +45^\circ)', 'FontWeight', 'bold');
    legend(ax1, [h_traj, h_start, h_end, h_ux, h_uy, h_uz, h_g], ...
        'Location', 'southoutside', 'NumColumns', 2, 'Interpreter', 'latex', 'FontSize', 9);
    view(ax1, 30, 24);

    % --- Top-Right Panel: Minimum-Jerk World Trajectory Kinematics along X ---
    ax2 = nexttile(tl, 2);
    hold(ax2, 'on');
    grid(ax2, 'on');
    box(ax2, 'on');

    yyaxis(ax2, 'left');
    l1 = plot(ax2, t, p_W(:, 1), '-', 'Color', [0.15, 0.15, 0.20], 'LineWidth', 2.0, ...
        'DisplayName', 'Position x_W(t) [m]');
    l2 = plot(ax2, t, v_W(:, 1), '--', 'Color', [0.10, 0.55, 0.75], 'LineWidth', 2.0, ...
        'DisplayName', 'Velocity v_{x,W}(t) [m/s]');
    ylabel(ax2, 'Position (m) / Velocity (m/s)', 'FontWeight', 'bold');
    ax2.YColor = [0.15, 0.15, 0.20];

    yyaxis(ax2, 'right');
    l3 = plot(ax2, t, a_W_kin(:, 1), '-', 'Color', col_x, 'LineWidth', 2.0, ...
        'DisplayName', 'Kinematic Accel a_{x,W}(t) [m/s^2]');
    ylabel(ax2, 'World Kinematic Accel (m/s^2)', 'FontWeight', 'bold');
    ax2.YColor = col_x;

    yline(ax2, 0, ':', 'Color', [0.55, 0.55, 0.55], 'LineWidth', 1.0);
    xlim(ax2, [t(1), t(end)]);
    xlabel(ax2, 'Time (s)', 'FontWeight', 'bold');
    title(ax2, 'Flash & Hogan Minimum-Jerk World Kinematics (X_W)', 'FontWeight', 'bold');
    legend(ax2, [l1, l2, l3], 'Location', 'northeast', 'FontSize', 8.5);

    % --- Bottom-Right Panel: Active Delsys Sensor Output in Local Frame L (with Gravity) ---
    ax3 = nexttile(tl, 4);
    hold(ax3, 'on');
    grid(ax3, 'on');
    box(ax3, 'on');

    s1 = plot(ax3, t, a_L_sen(:, 1), '-',  'Color', col_x, 'LineWidth', 2.2, ...
        'DisplayName', 'Sensor a_{x,L} (with g)');
    s2 = plot(ax3, t, a_L_sen(:, 2), '-',  'Color', col_y, 'LineWidth', 2.6, ...
        'DisplayName', 'Sensor a_{y,L} (with g = +6.94 m/s^2)');
    s3 = plot(ax3, t, a_L_sen(:, 3), '--', 'Color', col_z, 'LineWidth', 2.2, ...
        'DisplayName', 'Sensor a_{z,L} (with g = +6.94 m/s^2)');
    s4 = plot(ax3, t, a_L_kin(:, 1), ':',  'Color', [0.35, 0.35, 0.35], 'LineWidth', 1.4, ...
        'DisplayName', 'Kinematic-only a_{x,L} (no g)');

    yline(ax3, 0, ':', 'Color', [0.55, 0.55, 0.55], 'LineWidth', 1.0);
    xlim(ax3, [t(1), t(end)]);
    ylim(ax3, [-6.0, 9.5]);
    xlabel(ax3, 'Time (s)', 'FontWeight', 'bold');
    ylabel(ax3, 'Active Sensor Output (m/s^2)', 'FontWeight', 'bold');
    title(ax3, 'Active Delsys Sensor Output a_{sensor,L}(t) = R^T (a_W(t) - g_W)', 'FontWeight', 'bold');
    legend(ax3, [s1, s2, s3, s4], 'Location', 'southwest', 'NumColumns', 2, 'FontSize', 8.2);

    exportgraphics(fig, plotPath, 'Resolution', 200);
    close(fig);
end
