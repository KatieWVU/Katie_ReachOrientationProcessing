function alternateTempEvents(dboxIn, idSignalIn, idTrialIn)

dbox = dboxIn;
idSignal = idSignalIn;
idTrial = idTrialIn;

events = sort(cat(1,dbox.getEvent(idTrial,idSignal,1,[]),dbox.getEvent(idTrial,idSignal,3,[])));

dbox.modEvent({'idTrial',idTrial,'idSignal',idSignal},'bEvent',0);

for i = 1:numel(events)
    if mod(i,2) == 0
        dbox.setEvent(events(i),idTrial,idSignal,3,'bEvent',1); % store alternating events
    else
        dbox.setEvent(events(i),idTrial,idSignal,1,'bEvent',1);
    end
end

end