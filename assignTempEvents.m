% stores detected movements in a temporary event class. This way I can go
% in with boxsci monitor trial and monitor session to make sure no events
% were missed before assigning direction.

function assignTempEvents(dboxIn, idSignalIn, eventsIn, idTrialIn)

dbox = dboxIn;
idSignal = idSignalIn;
events = eventsIn;
idTrial = idTrialIn;

for i = 1:numel(events)
    if mod(i,2) == 0
        dbox.setEvent(events(i),idTrial,idSignal,3,'bEvent',1); % store alternating events
    else
        dbox.setEvent(events(i),idTrial,idSignal,1,'bEvent',1);
    end
end

end