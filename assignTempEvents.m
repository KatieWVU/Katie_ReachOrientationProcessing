% stores detected movements in a temporary event class. This way I can go
% in with boxsci monitor trial and monitor session to make sure no events
% were missed before assigning direction.

function [bDone] = assignTempEvents(dboxIn, idSignalIn, eventsIn, idTrialIn)

dbox = dboxIn;
idSignal = idSignalIn;
events = eventsIn;
idTrial = idTrialIn;
bDone = 0;

dbox.setEvent(events,idTrial,idSignal,5) % store events under the 'special' event type for now

bDone = 1;
end