% Function generates Flash & Hogan 5th-order minimum-jerk trajectory,
%   bell-shaped velocity profile, and exact analytical acceleration.
%   Adds nPad (default 10) samples of 0 velocity/acceleration at each end.
%
%   Input--------------------------------------------------------------
%
%   nRate    (double)     Sampling frequency, Hz.
%
%   tSim     (double)     Single movement duration, s.
%
%   sAngList (cell array) List of the DOF names; can be linear or angular.
%
%   nROM     (double)     [nDOF x 2] Start and end values for each DOF.
%
%   bReturn  (logical/double) Set to 1 to simulate a return movement back
%            to the start position (with an intermediate stationary stop of
%            nPad samples), otherwise set to 0 for a single movement.
%
%   nPad     (double, optional) Number of stationary zero-velocity samples
%            appended to the start and end (and between out/return when
%            bReturn == 1). Default: 10.
%
%   Output-------------------------------------------------------------
%
%   pos, vel, acc (structs) Position, velocity, and acceleration time
%            series (1 x N double) for each DOF in sAngList, plus tTime.

function [pos, vel, acc] = gettragect(nRate, tSim, sAngList, nROM, bReturn, nPad)

    if nargin < 6 || isempty(nPad)
        nPad = 10;
    end
    nPad = max(0, round(nPad));

    % Validate basic inputs
    assert(isscalar(nRate) && nRate > 0, 'gettragect:InvalidRate', ...
        'nRate must be a positive scalar.');
    assert(isscalar(tSim) && tSim > 0, 'gettragect:InvalidDuration', ...
        'tSim must be a positive scalar.');
    assert(size(nROM, 1) == numel(sAngList) && size(nROM, 2) == 2, ...
        'gettragect:InvalidROM', ...
        'nROM must be an [numel(sAngList) x 2] matrix.');

    % Discretize movement duration onto the uniform sampling grid (dt = 1/nRate)
    dt    = 1.0 / nRate;
    nMove = max(2, round(nRate * tSim));
    T_eff = nMove * dt;          % Exact duration spanned by discrete grid
    tau   = (0:nMove) / nMove;   % Normalized time in [0, 1]

    % Flash & Hogan (1985) 5th-order minimum-jerk basis functions:
    %   s(tau)   = 10*tau^3 - 15*tau^4 + 6*tau^5
    %   s'(tau)  = 30*tau^2 * (1 - tau)^2
    %   s''(tau) = 60*tau * (1 - tau) * (1 - 2*tau)
    s_pos = 10 .* tau.^3 - 15 .* tau.^4 + 6 .* tau.^5;
    s_vel = 30 .* (tau.^2) .* ((1 - tau).^2) / T_eff;
    s_acc = 60 .* tau .* (1 - tau) .* (1 - 2 .* tau) / (T_eff^2);

    % Assemble normalized position, velocity, and acceleration profiles
    % with stationary zero-velocity/zero-acceleration pads at boundaries.
    pad_zero = zeros(1, nPad);
    pad_one  = ones(1, nPad);

    if logical(bReturn)
        % Forward movement (0 -> 1), stop in between, return movement (1 -> 0)
        s_pos_full = [pad_zero, s_pos, pad_one, 1 - s_pos, pad_zero];
        s_vel_full = [pad_zero, s_vel, pad_zero, -s_vel,   pad_zero];
        s_acc_full = [pad_zero, s_acc, pad_zero, -s_acc,   pad_zero];
    else
        % Unidirectional movement (0 -> 1) with stationary start and end pads
        s_pos_full = [pad_zero, s_pos, pad_one];
        s_vel_full = [pad_zero, s_vel, pad_zero];
        s_acc_full = [pad_zero, s_acc, pad_zero];
    end

    nTotal = numel(s_pos_full);
    tTime  = (0:(nTotal - 1)) * dt;

    % Scale normalized minimum-jerk profiles for each DOF
    pos = struct();
    vel = struct();
    acc = struct();

    for iDOF = 1:numel(sAngList)
        dofName = sAngList{iDOF};
        x0   = nROM(iDOF, 1);
        xEnd = nROM(iDOF, 2);
        nAmp = xEnd - x0;

        if nAmp ~= 0
            pos.(dofName) = double(x0 + nAmp .* s_pos_full);
            vel.(dofName) = double(nAmp .* s_vel_full);
            acc.(dofName) = double(nAmp .* s_acc_full);
        else
            pos.(dofName) = double(x0 .* ones(1, nTotal));
            vel.(dofName) = zeros(1, nTotal);
            acc.(dofName) = zeros(1, nTotal);
        end
    end

    pos.tTime = tTime;
    vel.tTime = tTime;
    acc.tTime = tTime;
end
