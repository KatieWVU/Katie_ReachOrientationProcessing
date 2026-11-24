%% Local Coordinate Frame 3D Kinematics and Linear Acceleration Analysis
% Models a local coordinate frame L initially coincident with the world
% frame W, rotated by a fixed +45 deg about a configurable primary axis,
% and translated along a smooth, parameterized 3D trajectory.
%
% Outputs:
%   - Command Window summary table of world and local accelerations
%   - acceleration_results.csv   : Full trajectory and acceleration dataset
%   - kinematics_verification.png: 2-subplot visual verification figure
%
% Rotation Convention:
%   R = R_W_to_L_basis is the 3x3 proper orthonormal rotation matrix whose
%   columns are the rotated local unit basis vectors [u_x, u_y, u_z]
%   expressed in World frame W coordinates (active right-handed rotation
%   by +rot_angle_deg about rot_axis). Therefore:
%     v_W = R * v_L       (Local  -> World)
%     v_L = R' * v_W      (World  -> Local, passive coordinate projection)

%% 1. Configuration Parameters (Modular User Controls)
rot_axis      = 'Z';      % Primary rotation axis: 'X', 'Y', or 'Z'
rot_angle_deg = 45.0;     % Fixed rotation angle in degrees (+45 deg)

% Time discretization
t_start = 0.0;            % Start time (s)
t_end   = 4.0;            % End time (s)
n_pts   = 101;            % Number of discrete time samples (dt = 0.04 s)
t       = linspace(t_start, t_end, n_pts).';

% Modular trajectory parameters (3D helical-sinusoidal path)
% Swap evaluateTrajectory() at the bottom of this script to use custom
% analytical equations or interpolated waypoints.
traj_params.radius  = 1.0;        % Helix radius in X-Y plane (m)
traj_params.omega   = pi / 2;     % Angular frequency in X-Y plane (rad/s)
traj_params.vz      = 0.30;       % Mean vertical climb rate (m/s)
traj_params.amp_z   = 0.25;       % Vertical sinusoidal amplitude (m)
traj_params.omega_z = pi;         % Vertical sinusoidal frequency (rad/s)

% Verification tolerances & visualization controls
tol_orth       = 1e-12;   % Tolerance for SO(3) orthogonality & unit norms
tol_accel_fd   = 1e-3;    % Tolerance for 4th-order finite-diff vs analytical (m/s^2)
tol_accel_grad = 5e-2;    % Tolerance for interior MATLAB gradient check (m/s^2)
n_plot_frames  = 9;       % Number of local coordinate triads plotted in 3D
triad_scale    = 0.35;    % Visual length of plotted unit vectors (m)

% Output file paths (saved alongside this script)
csv_filename  = 'acceleration_results.csv';
plot_filename = 'kinematics_verification.png';

%% 2. World Frame Initialization & Fixed +45 deg Rotation Matrix
% World frame W origin and standard orthonormal basis [I_hat, J_hat, K_hat]
origin_W = [0; 0; 0];
basis_W  = eye(3);

% Initialize local frame L coincident and aligned with W
origin_L0 = origin_W;
basis_L0  = basis_W;

% Construct proper orthonormal rotation matrix R (SO(3))
rot_angle_rad = deg2rad(rot_angle_deg);
R = buildPrimaryRotation(rot_axis, rot_angle_rad);

% Rotate local basis vectors: columns of basis_L are [u_x, u_y, u_z] in W
basis_L = R * basis_L0;
u_x = basis_L(:, 1);
u_y = basis_L(:, 2);
u_z = basis_L(:, 3);

%% 3. Trajectory Evaluation & 3D Linear Acceleration (World & Local Frames)
% Evaluate position p_W(t), analytical velocity v_W(t), and analytical
% linear acceleration a_W(t) expressed in World frame W (N x 3 matrices).
[p_W, v_W_analytic, a_W_analytic] = evaluateTrajectory(t, traj_params);

% Independent numerical verification of a_W(t) using:
%   (a) 4th-order finite differences across the full domain (incl. endpoints)
%   (b) MATLAB built-in gradient() twice on interior points (indices 3:N-2)
a_W_num  = computeNumericalAcceleration4th(t, p_W);
dt       = t(2) - t(1);
[~, v_W_grad] = gradient(p_W, 1, dt);
[~, a_W_grad] = gradient(v_W_grad, 1, dt);

% Project 3D world linear acceleration into the rotated Local frame L:
%   a_L(t) = R' * a_W(t)  (column vector form)
% For N x 3 row-vector storage: a_L = a_W * R
a_L_analytic = (R.' * a_W_analytic.').';
a_L_num      = (R.' * a_W_num.').';

%% 4. Kinematics & Numerical Verification Assertions
% 4a. Initial alignment and Special Orthogonal Group SO(3) checks
assert(isequal(origin_L0, origin_W) && isequal(basis_L0, basis_W), ...
    'Initial local frame L must be coincident and aligned with world frame W.');
det_err  = abs(det(R) - 1.0);
orth_err = norm(R.' * R - eye(3), 'fro');
assert(det_err < tol_orth, ...
    'Rotation matrix determinant check failed: |det(R) - 1| = %.3e', det_err);
assert(orth_err < tol_orth, ...
    'Rotation matrix orthogonality check failed: ||R''*R - I||_F = %.3e', orth_err);

% 4b. Transformed local basis vectors: unit norm, mutual orthogonality, right-handedness
basis_norms = vecnorm(basis_L, 2, 1);
assert(all(abs(basis_norms - 1.0) < tol_orth), ...
    'Local basis vectors are not unit length: max error = %.3e', max(abs(basis_norms - 1.0)));
assert(abs(dot(u_x, u_y)) < tol_orth && abs(dot(u_y, u_z)) < tol_orth && abs(dot(u_z, u_x)) < tol_orth, ...
    'Local basis vectors are not mutually orthogonal.');
assert(norm(cross(u_x, u_y) - u_z) < tol_orth, ...
    'Local basis vectors do not form a right-handed frame.');

% 4c. Verify rotation angle equals rot_angle_deg via matrix trace: tr(R) = 1 + 2*cos(theta)
recovered_angle_deg = rad2deg(acos(max(-1.0, min(1.0, (trace(R) - 1.0) / 2.0))));
assert(abs(recovered_angle_deg - abs(rot_angle_deg)) < 1e-10, ...
    'Recovered rotation angle (%.6f deg) does not match expected %.6f deg.', ...
    recovered_angle_deg, abs(rot_angle_deg));

% 4d. Numerical vs. analytical acceleration verification
max_fd_err   = max(vecnorm(a_W_num - a_W_analytic, 2, 2));
max_grad_err = max(vecnorm(a_W_grad(3:end-2, :) - a_W_analytic(3:end-2, :), 2, 2));
assert(max_fd_err < tol_accel_fd, ...
    '4th-order numerical acceleration mismatch: max L2 error = %.3e m/s^2', max_fd_err);
assert(max_grad_err < tol_accel_grad, ...
    'Interior MATLAB gradient acceleration mismatch: max L2 error = %.3e m/s^2', max_grad_err);

% 4e. Euclidean magnitude invariance under rigid rotation: ||a_L|| = ||a_W||
mag_err = max(abs(vecnorm(a_L_analytic, 2, 2) - vecnorm(a_W_analytic, 2, 2)));
assert(mag_err < tol_orth, ...
    'Acceleration magnitude not preserved by rotation: max error = %.3e', mag_err);

%% 5. Console Reporting & CSV Export
fprintf('================================================================================================================\n');
fprintf('  LOCAL COORDINATE FRAME 3D KINEMATICS & LINEAR ACCELERATION SUMMARY\n');
fprintf('================================================================================================================\n');
fprintf('  Rotation Axis      : %s-axis\n', upper(rot_axis));
fprintf('  Rotation Angle     : %+.2f deg (%.6f rad)\n', rot_angle_deg, rot_angle_rad);
fprintf('  |det(R) - 1|       : %.3e   (PASS < %.1e)\n', det_err, tol_orth);
fprintf('  ||R''*R - I||_F     : %.3e   (PASS < %.1e)\n', orth_err, tol_orth);
fprintf('  Basis Vector Norms : [%.15f, %.15f, %.15f]  (PASS)\n', basis_norms);
fprintf('  Max FD Accel Err   : %.3e m/s^2 (4th-order FD vs. Analytical, PASS < %.1e)\n', max_fd_err, tol_accel_fd);
fprintf('  Max Grad Accel Err : %.3e m/s^2 (Interior gradient vs. Analytical, PASS < %.1e)\n', max_grad_err, tol_accel_grad);
fprintf('  Max ||a_L|-|a_W||  : %.3e m/s^2 (Norm Invariance, PASS < %.1e)\n', mag_err, tol_orth);
fprintf('----------------------------------------------------------------------------------------------------------------\n');
fprintf('  Rotation Matrix R (columns = [u_x, u_y, u_z] expressed in World Frame W):\n');
for row_idx = 1:3
    fprintf('    [ %+10.6f  %+10.6f  %+10.6f ]\n', R(row_idx, 1), R(row_idx, 2), R(row_idx, 3));
end
fprintf('================================================================================================================\n\n');

% Build structured table and save full dataset to CSV
resultsTable = table( ...
    t, p_W(:, 1), p_W(:, 2), p_W(:, 3), ...
    a_W_analytic(:, 1), a_W_analytic(:, 2), a_W_analytic(:, 3), ...
    a_L_analytic(:, 1), a_L_analytic(:, 2), a_L_analytic(:, 3), ...
    'VariableNames', {'Time', 'X', 'Y', 'Z', ...
                      'ax_world', 'ay_world', 'az_world', ...
                      'ax_local', 'ay_local', 'az_local'});

writetable(resultsTable, csv_filename);

% Print cleanly formatted table for every point along the trajectory
fprintf('%8s | %9s %9s %9s | %10s %10s %10s | %10s %10s %10s\n', ...
    'Time', 'X', 'Y', 'Z', ...
    'ax_world', 'ay_world', 'az_world', ...
    'ax_local', 'ay_local', 'az_local');
fprintf('%s\n', repmat('-', 1, 108));
for k = 1:n_pts
    fprintf('%8.3f | %9.4f %9.4f %9.4f | %10.4f %10.4f %10.4f | %10.4f %10.4f %10.4f\n', ...
        resultsTable.Time(k), resultsTable.X(k), resultsTable.Y(k), resultsTable.Z(k), ...
        resultsTable.ax_world(k), resultsTable.ay_world(k), resultsTable.az_world(k), ...
        resultsTable.ax_local(k), resultsTable.ay_local(k), resultsTable.az_local(k));
end
fprintf('\nSaved full dataset (%d samples) to %s\n', n_pts, csv_filename);

%% 6. Visualization (2-Subplot Verification Figure)
fig = figure('Name', 'Local Frame 3D Kinematics Verification', ...
             'Color', 'w', ...
             'Units', 'pixels', ...
             'Position', [100, 100, 1400, 620]);

% Color palette (RGB = XYZ convention)
col_x = [0.85, 0.15, 0.15];
col_y = [0.10, 0.62, 0.25];
col_z = [0.10, 0.40, 0.85];
col_traj = [0.20, 0.20, 0.25];

% --- Subplot 1: 3D Trajectory & Rotated Local Unit Vectors ---
ax1 = subplot(1, 2, 1);
hold(ax1, 'on');
grid(ax1, 'on');
box(ax1, 'on');

% Plot World Frame W reference axes at the origin [0, 0, 0]
world_scale = 0.55;
quiver3(ax1, 0, 0, 0, world_scale, 0, 0, 0, ...
    'Color', [0.45, 0.45, 0.45], 'LineWidth', 1.4, 'LineStyle', '--', 'MaxHeadSize', 0.35);
quiver3(ax1, 0, 0, 0, 0, world_scale, 0, 0, ...
    'Color', [0.45, 0.45, 0.45], 'LineWidth', 1.4, 'LineStyle', '--', 'MaxHeadSize', 0.35);
quiver3(ax1, 0, 0, 0, 0, 0, world_scale, 0, ...
    'Color', [0.45, 0.45, 0.45], 'LineWidth', 1.4, 'LineStyle', '--', 'MaxHeadSize', 0.35);
text(ax1, world_scale * 1.08, 0, 0, 'X_W', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.35, 0.35, 0.35]);
text(ax1, 0, world_scale * 1.08, 0, 'Y_W', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.35, 0.35, 0.35]);
text(ax1, 0, 0, world_scale * 1.08, 'Z_W', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.35, 0.35, 0.35]);

% Plot 3D origin trajectory
h_traj = plot3(ax1, p_W(:, 1), p_W(:, 2), p_W(:, 3), '-', ...
    'Color', col_traj, 'LineWidth', 2.0, 'DisplayName', 'Origin Trajectory $\mathbf{p}(t)$');
h_start = plot3(ax1, p_W(1, 1), p_W(1, 2), p_W(1, 3), 'o', ...
    'MarkerSize', 7, 'MarkerFaceColor', [0.15, 0.70, 0.30], 'MarkerEdgeColor', 'k', ...
    'DisplayName', 'Start ($t = 0$ s)');
h_end = plot3(ax1, p_W(end, 1), p_W(end, 2), p_W(end, 3), 's', ...
    'MarkerSize', 7, 'MarkerFaceColor', [0.85, 0.25, 0.25], 'MarkerEdgeColor', 'k', ...
    'DisplayName', sprintf('End ($t = %.1f$ s)', t_end));

% Plot rotated local coordinate triads at sampled points along the path
sample_idx = round(linspace(1, n_pts, n_plot_frames));
n_samp     = numel(sample_idx);
P_samp     = p_W(sample_idx, :);

Ux_vec = repmat((triad_scale * u_x).', n_samp, 1);
Uy_vec = repmat((triad_scale * u_y).', n_samp, 1);
Uz_vec = repmat((triad_scale * u_z).', n_samp, 1);

h_ux = quiver3(ax1, P_samp(:, 1), P_samp(:, 2), P_samp(:, 3), ...
    Ux_vec(:, 1), Ux_vec(:, 2), Ux_vec(:, 3), 0, ...
    'Color', col_x, 'LineWidth', 1.8, 'MaxHeadSize', 0.45, 'DisplayName', 'Local $\hat{u}_x$');
h_uy = quiver3(ax1, P_samp(:, 1), P_samp(:, 2), P_samp(:, 3), ...
    Uy_vec(:, 1), Uy_vec(:, 2), Uy_vec(:, 3), 0, ...
    'Color', col_y, 'LineWidth', 1.8, 'MaxHeadSize', 0.45, 'DisplayName', 'Local $\hat{u}_y$');
h_uz = quiver3(ax1, P_samp(:, 1), P_samp(:, 2), P_samp(:, 3), ...
    Uz_vec(:, 1), Uz_vec(:, 2), Uz_vec(:, 3), 0, ...
    'Color', col_z, 'LineWidth', 1.8, 'MaxHeadSize', 0.45, 'DisplayName', 'Local $\hat{u}_z$');

% Also plot a reference triad at origin to highlight the +45 deg offset vs W
quiver3(ax1, 0, 0, 0, triad_scale * u_x(1), triad_scale * u_x(2), triad_scale * u_x(3), 0, ...
    'Color', col_x, 'LineWidth', 1.5, 'MaxHeadSize', 0.45);
quiver3(ax1, 0, 0, 0, triad_scale * u_y(1), triad_scale * u_y(2), triad_scale * u_y(3), 0, ...
    'Color', col_y, 'LineWidth', 1.5, 'MaxHeadSize', 0.45);
quiver3(ax1, 0, 0, 0, triad_scale * u_z(1), triad_scale * u_z(2), triad_scale * u_z(3), 0, ...
    'Color', col_z, 'LineWidth', 1.5, 'MaxHeadSize', 0.45);

axis(ax1, 'equal');
xlabel(ax1, 'X_W (m)', 'FontWeight', 'bold');
ylabel(ax1, 'Y_W (m)', 'FontWeight', 'bold');
zlabel(ax1, 'Z_W (m)', 'FontWeight', 'bold');
title(ax1, sprintf('3D Trajectory & Local Frame L (+%.0f^\\circ about %s-axis)', ...
    rot_angle_deg, upper(rot_axis)), 'FontSize', 11, 'FontWeight', 'bold');
legend(ax1, [h_traj, h_start, h_end, h_ux, h_uy, h_uz], ...
    'Location', 'southoutside', 'NumColumns', 3, 'Interpreter', 'latex', 'FontSize', 9);
view(ax1, 15, 38);

% --- Subplot 2: 3D Linear Acceleration in Rotated Local Frame L ---
ax2 = subplot(1, 2, 2);
hold(ax2, 'on');
grid(ax2, 'on');
box(ax2, 'on');

% Analytical local-frame accelerations (solid curves)
p1 = plot(ax2, t, a_L_analytic(:, 1), '-', 'Color', col_x, 'LineWidth', 2.0, ...
    'DisplayName', 'a_{x,L} (Analytical)');
p2 = plot(ax2, t, a_L_analytic(:, 2), '-', 'Color', col_y, 'LineWidth', 2.0, ...
    'DisplayName', 'a_{y,L} (Analytical)');
p3 = plot(ax2, t, a_L_analytic(:, 3), '-', 'Color', col_z, 'LineWidth', 2.0, ...
    'DisplayName', 'a_{z,L} (Analytical)');

% Numerical finite-difference verification markers (every 5th sample)
marker_idx = 1:5:n_pts;
p4 = plot(ax2, t(marker_idx), a_L_num(marker_idx, 1), 'o', 'Color', col_x, ...
    'MarkerSize', 5, 'LineWidth', 1.0, 'DisplayName', 'a_{x,L} (Numerical FD)');
p5 = plot(ax2, t(marker_idx), a_L_num(marker_idx, 2), 's', 'Color', col_y, ...
    'MarkerSize', 5, 'LineWidth', 1.0, 'DisplayName', 'a_{y,L} (Numerical FD)');
p6 = plot(ax2, t(marker_idx), a_L_num(marker_idx, 3), '^', 'Color', col_z, ...
    'MarkerSize', 5, 'LineWidth', 1.0, 'DisplayName', 'a_{z,L} (Numerical FD)');

yline(ax2, 0, ':', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1.0);
xlim(ax2, [t_start, t_end]);
xlabel(ax2, 'Time (s)', 'FontWeight', 'bold');
ylabel(ax2, 'Linear Acceleration in Local Frame L (m/s^2)', 'FontWeight', 'bold');
title(ax2, 'Local Frame Linear Acceleration Components a_L(t) = R^T a_W(t)', ...
    'FontSize', 11, 'FontWeight', 'bold');
legend(ax2, [p1, p2, p3, p4, p5, p6], 'Location', 'best', 'NumColumns', 2, 'FontSize', 8.5);

% Save high-resolution verification PNG
exportgraphics(fig, plot_filename, 'Resolution', 200);
fprintf('Saved verification figure to %s\n', plot_filename);

%% ========================================================================
%  Local Helper Functions
%  ========================================================================

function R = buildPrimaryRotation(axis_name, theta_rad)
%BUILDPRIMARYROTATION Construct a 3x3 right-handed rotation matrix in SO(3).
%   Columns of R represent the rotated local basis vectors [u_x, u_y, u_z]
%   expressed in World frame W coordinates after rotating by +theta_rad
%   about the specified primary axis ('X', 'Y', or 'Z').
    c = cos(theta_rad);
    s = sin(theta_rad);

    switch upper(char(axis_name))
        case 'X'
            R = [ 1,  0,  0;
                  0,  c, -s;
                  0,  s,  c ];
        case 'Y'
            R = [ c,  0,  s;
                  0,  1,  0;
                 -s,  0,  c ];
        case 'Z'
            R = [ c, -s,  0;
                  s,  c,  0;
                  0,  0,  1 ];
        otherwise
            error('local_frame_kinematics:InvalidAxis', ...
                'rot_axis must be ''X'', ''Y'', or ''Z''. Received: %s', char(axis_name));
    end
end

function [pos, vel, acc] = evaluateTrajectory(t, params)
%EVALUATETRAJECTORY Modular 3D trajectory generator with analytical derivatives.
%   Computes position pos(t), velocity vel(t), and linear acceleration acc(t)
%   expressed in World frame W as N x 3 arrays for column time vector t.
%
%   Trajectory equations (3D helical-sinusoidal motion):
%     x(t) = r * cos(w * t)
%     y(t) = r * sin(w * t)
%     z(t) = vz * t + Az * sin(wz * t)
    r  = params.radius;
    w  = params.omega;
    vz = params.vz;
    Az = params.amp_z;
    wz = params.omega_z;

    % Position p_W(t)
    x = r * cos(w * t);
    y = r * sin(w * t);
    z = vz * t + Az * sin(wz * t);
    pos = [x, y, z];

    % Velocity v_W(t) = dp_W/dt
    vx = -r * w * sin(w * t);
    vy =  r * w * cos(w * t);
    vz_t = vz + Az * wz * cos(wz * t);
    vel = [vx, vy, vz_t];

    % Linear Acceleration a_W(t) = d^2 p_W / dt^2
    ax = -r * (w^2) * cos(w * t);
    ay = -r * (w^2) * sin(w * t);
    az = -Az * (wz^2) * sin(wz * t);
    acc = [ax, ay, az];
end

function acc_num = computeNumericalAcceleration4th(t, pos)
%COMPUTENUMERICALACCELERATION4TH 4th-order finite-difference 2nd derivative.
%   Computes d^2(pos)/dt^2 for an N x 3 trajectory sampled on a uniform
%   time grid t (N >= 6) with O(dt^4) accuracy at interior and boundary points.
    n = numel(t);
    assert(n >= 6, 'At least 6 time samples are required for 4th-order differentiation.');

    dt_vec = diff(t);
    dt = dt_vec(1);
    assert(max(abs(dt_vec - dt)) < 1e-12 * max(1, abs(dt)), ...
        'Time vector t must be uniformly spaced for 4th-order finite-difference stencil.');

    inv_12dt2 = 1.0 / (12.0 * dt^2);
    acc_num = zeros(size(pos));

    % Interior points (i = 3 .. n-2): symmetric 5-point 4th-order stencil
    acc_num(3:n-2, :) = ( -pos(1:n-4, :) ...
                        + 16 * pos(2:n-3, :) ...
                        - 30 * pos(3:n-2, :) ...
                        + 16 * pos(4:n-1, :) ...
                        - pos(5:n, :) ) * inv_12dt2;

    % Start boundary points (i = 1, 2): 6-point 4th-order stencils
    w_end  = [45, -154, 214, -156, 61, -10];
    w_near = [10,  -15,  -4,   14, -6,   1];
    acc_num(1, :) = (w_end  * pos(1:6, :)) * inv_12dt2;
    acc_num(2, :) = (w_near * pos(1:6, :)) * inv_12dt2;

    % End boundary points (i = n-1, n): mirrored 6-point 4th-order stencils
    acc_num(n-1, :) = (fliplr(w_near) * pos(n-5:n, :)) * inv_12dt2;
    acc_num(n, :)   = (fliplr(w_end)  * pos(n-5:n, :)) * inv_12dt2;
end
