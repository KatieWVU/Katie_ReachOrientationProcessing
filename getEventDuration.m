% calculates the time events take, the returns average and standard
% deviation of event times.

function [mean,std] = getEventDuration(eventTimesIn)

mean = -1;
std = -1;

diffs = zeros(length(eventTimesIn)-1,1);
for i = 1:length(eventTimesIn)-1
    diffs(i) = eventsTimesIn(i+1)-eventTimesIn(i);
end

mean = mean(diffs);
std = std(diffs);

end