% calculates the time events take, the returns average and standard
% deviation of event times.

function [ave,sigma] = getEventDuration(eventTimesIn)

ave = -1;
sigma = -1;
times = eventTimesIn;

if numel(times) > 1
    diffs = zeros(numel(times)-1,1);
    for i = 1:length(times)-1
        diffs(i) = times(i+1)-times(i);
    end

    ave = mean(diffs);
    sigma = std(diffs);
end

end