% this script works well for subjects: 1, 4, 6, 7, 9. There are a couple of
% oddball trials within those subjects for which it gets weird. Watch out
% for those.


clear
clc
%% load database
sPathSource = "G:\Shared drives\LABS-DATASETS\DATASET_REACH_ORIENTATION";
dbox        = databox();
dbox.loadMeta(sPathSource);
%% 
idSubject       = [8]; % finished for idSubjects 1, 4,6,7,9
idSignalEvent   = 10;
sScript         = 'nData = butterfilt(nData,nRate,6,''nOrder'',2);';
sTable          = 'accraw';
sSignalList     = {'ECU_X','ECU_Y','ECU_Z'};
sSignalListFCU  = {'FCU_X','FCU_Y','FCU_Z'};
sSignalListFCR  = {'FCR_X','FCR_Y','FCR_Z'};
sTrialTypeList  = {'UP_HF','UP_HS','SIDE_HF','SIDE_HS','SIDE_VF','SIDE_VS','UP_VF','UP_VS'};
idTrialTypeF   = [7,9,11,13]; %fast movements
idTrialTypeS   = [7,9,11,13]+1; %slow movements
idTrialTypeH   = [7:10]; %horizontal trial
idTrialTypeV   = [11:14]; %vertical trial

idSignalList = dbox.getMeta('metaSignal',{'sTable',sTable,...
    'sSignal',sSignalList},'idSignal'); % read signal IDs
idSignalListFCU = dbox.getMeta('metaSignal',{'sTable',sTable,...
    'sSignal',sSignalListFCU},'idSignal'); % read signal IDs
idSignalListFCR = dbox.getMeta('metaSignal',{'sTable',sTable,...
    'sSignal',sSignalListFCR},'idSignal'); % read signal IDs
nRate = dbox.getMeta('metaSignal',{'sTable',sTable,...
    'sSignal',sSignalList{1}},'nRate');
for iTrialType = 1:numel(sTrialTypeList)
    idTrialList = dbox.getMeta('metaTrial',{'idSubject',idSubject,...
        'sTrialType',sTrialTypeList{iTrialType},'bTrial',1},'idTrial'); % read trials for a given subject
    if ~isempty(idTrialList)
        for idTrial = idTrialList
            idTrialType = dbox.getMeta('metaTrial',{'idTrial',idTrial},'idTrialType'); % read the movement type
            nBeat = dbox.getMeta('metaTrialType',{'idTrialType',idTrialType},'nBeat'); % read beat at which the subject was paced
            tBeat = (60/nBeat); % time one beat takes, in s

            tSync = dbox.getMeta('metaSync',{'idTrial',idTrial},sTable); % read the movement type

            nData      = dbox.getSignal(idSignalList(1),idTrial,'sScript',sScript);
            nData(2,:) = dbox.getSignal(idSignalList(2),idTrial,'sScript',sScript);
            nData(3,:) = dbox.getSignal(idSignalList(3),idTrial,'sScript',sScript);
            nVec     = sqrt(sum(nData.^2,1));
            nVecF    = butterfilt(abs(nVec-mean(nVec)),nRate,3,'nOrder',2);

            % get the approximate start and stop points (selected manually)
            tStart = dbox.getEvent(idTrial,idSignalEvent,'on',1);
            tStop  = dbox.getEvent(idTrial,idSignalEvent,'off',1);

            nStart = round(tStart*nRate,0);
            nStop = round(tStop*nRate,0);


            
            nx = 0:numel(nVecF)-1;
            time = nx(nStart:nStop)./nRate;
            zero = zeros(size(time));

            ECU = nVecF(nStart:nStop);

            velECU = cumtrapz(time,ECU);

            highpassECU = butterfilt(velECU,nRate,0.5,'nOrder',2,'sType','high');

            
            % BELOW THIS LINE IS FCU SIGNAL WORK


 nData      = dbox.getSignal(idSignalListFCU(1),idTrial,'sScript',sScript);
            nData(2,:) = dbox.getSignal(idSignalListFCU(2),idTrial,'sScript',sScript);
            nData(3,:) = dbox.getSignal(idSignalListFCU(3),idTrial,'sScript',sScript);
            nVec     = sqrt(sum(nData.^2,1));
            nVecFFCU    = butterfilt(abs(nVec-mean(nVec)),nRate,3,'nOrder',2);

            FCU = nVecFFCU(nStart:nStop);

            velFCU = cumtrapz(time,FCU);

            highpassFCU = butterfilt(velFCU,nRate,0.5,'nOrder',2,'sType','high');

            % BELOW THIS LINE IS FCR SIGNAL WORK


 nData      = dbox.getSignal(idSignalListFCR(1),idTrial,'sScript',sScript);
            nData(2,:) = dbox.getSignal(idSignalListFCR(2),idTrial,'sScript',sScript);
            nData(3,:) = dbox.getSignal(idSignalListFCR(3),idTrial,'sScript',sScript);
            nVec     = sqrt(sum(nData.^2,1));
            nVecFFCR    = butterfilt(abs(nVec-mean(nVec)),nRate,3,'nOrder',2);

            FCR = nVecFFCR(nStart:nStop);

            velFCR = cumtrapz(time,FCR);
            
            highpassFCR = butterfilt(velFCR,nRate,0.5,'nOrder',2,'sType','high');


            % find zero crossings (where a movement stops in theory)
            
            zerosECU = NaN(numel(highpassECU)-1,1);
            nzerosECU = NaN(numel(highpassECU)-1,1);
            for i = 1:numel(highpassECU)-1
                if highpassECU(i) == 0
                    zerosECU(i) = highpassECU(i);
                    nzerosECU(i) = i;
                elseif (highpassECU(i)>0 && highpassECU(i+1)<0) || (highpassECU(i)<0 && highpassECU(i+1)>0)
                    zerosECU(i) = highpassECU(i);
                    nzerosECU(i) = i;
                end
            end
            zerosFCU = NaN(numel(highpassFCU)-1,1);
            nzerosFCU = NaN(numel(highpassFCU)-1,1);
            for i = 1:numel(highpassFCU)-1
                if highpassFCU(i) == 0
                    zerosFCU(i) = highpassFCU(i);
                    nzerosFCU(i) = i;
                elseif (highpassFCU(i)>0 && highpassFCU(i+1)<0) || (highpassFCU(i)<0 && highpassFCU(i+1)>0)
                    zerosFCU(i) = highpassFCU(i);
                    nzerosFCU(i) = i;
                end
            end
            zerosFCR = NaN(numel(highpassFCR)-1,1);
            nzerosFCR = NaN(numel(highpassFCR)-1,1);
            for i = 1:numel(highpassFCR)-1
                if highpassFCR(i) == 0
                    zerosFCR(i) = highpassFCR(i);
                    nzerosFCR(i) = i;
                elseif (highpassFCR(i)>0 && highpassFCR(i+1)<0) || (highpassFCR(i)<0 && highpassFCR(i+1)>0)
                    zerosFCR(i) = highpassFCR(i);
                    nzerosFCR(i) = i;
                end
            end

            % get rid of all indices where there wasn't a zero crossing
            zerosECU = rmmissing(zerosECU);
            nzerosECU = rmmissing(nzerosECU);
            zerosFCU = rmmissing(zerosFCU);
            nzerosFCU = rmmissing(nzerosFCU);
            zerosFCR = rmmissing(zerosFCR);
            nzerosFCR = rmmissing(nzerosFCR);

            % if there are points too close together, remove them. They
            % will be replaced by points from a different signal

            i = 1;
            l = numel(zerosECU);
            while i < l
                if (nzerosECU(i+1)-nzerosECU(i))/nRate < 0.5*tBeat
                    nzerosECU(i+1)=[];
                    zerosECU(i+1)=[];
                    nzerosECU(i)=[];
                    zerosECU(i)=[];
                    i = i-1;
                    l = l-2;
                end
                i= i+1;
            end
            i = 1;
            l = numel(zerosFCU);
            while i < l
                if (nzerosFCU(i+1)-nzerosFCU(i))/nRate < 0.5*tBeat
                    nzerosFCU(i+1)=[];
                    zerosFCU(i+1)=[];
                    nzerosFCU(i)=[];
                    zerosFCU(i)=[];
                    i = i-1;
                    l = l-2;
                end
                i= i+1;
            end
            i = 1;
            l = numel(zerosFCR);
            while i < l
                if (nzerosFCR(i+1)-nzerosFCR(i))/nRate < 0.5*tBeat
                    nzerosFCR(i+1)=[];
                    zerosFCR(i+1)=[];
                    nzerosFCR(i)=[];
                    zerosFCR(i)=[];
                    i = i-1;
                    l = l-2;
                end
                i= i+1;
            end

            % start combining events across arrays

            insert = @(a,x,n) cat(1, x(1:n),a,x(n+1:end));

            events = [];
            nevents = [];

            if numel(zerosECU) == numel(zerosFCU) && numel(zerosFCU) == numel(zerosFCR)
                for i = 1:numel(events)
                    events(i) = (zerosECU(i)+zerosFCU(i)+zerosFCR(i))/3;
                    nevents(i) = round((nzerosECU(i)+nzerosFCU(i)+nzerosFCR(i))/3);
                end
                display(['All equal for trial ', num2str(idTrial)])
            else
                if numel(zerosECU) > numel(zerosFCU) && numel(zerosECU) >numel(zerosFCR)
                    for i = 1:numel(nzerosECU)
                        if abs(nzerosFCU(i)-nzerosECU(i)) > 0.5*tBeat
                            nzerosFCU = insert(nzerosECU(i),nzerosFCU,i);
                            zerosFCU = insert(zerosECU(i),zerosFCU,i);
                        end
                        if abs(nzerosFCR(i)-nzerosECU(i)) > 0.5*tBeat
                            nzerosFCR = insert(nzerosECU(i),nzerosFCR,i);
                            zerosFCR = insert(zerosECU(i),zerosFCR,i);
                        end
                    end
                elseif numel(zerosFCU) > numel(zerosECU) && numel(zerosFCU) >numel(zerosFCR)
                    for i = 1:numel(nzerosFCU)
                        if abs(nzerosFCU(i)-nzerosECU(i)) > 0.5*tBeat
                            nzerosECU = insert(nzerosFCU(i),nzerosECU,i);
                            zerosECU = insert(zerosFCU(i),zerosECU,i);
                        end
                        if abs(nzerosFCR(i)-nzerosFCU(i)) > 0.5*tBeat
                            nzerosFCR = insert(nzerosFCU(i),nzerosFCR,i);
                            zerosFCR = insert(zerosFCU(i),zerosFCR,i);
                        end
                    end
                else
                    for i = 1:numel(nzerosFCR)
                        if abs(nzerosFCR(i)-nzerosECU(i)) > 0.5*tBeat
                            nzerosECU = insert(nzerosFCR(i),nzerosECU,i);
                            zerosECU = insert(zerosFCR(i),zerosECU,i);
                        end
                        if abs(nzerosFCR(i)-nzerosFCU(i)) > 0.5*tBeat
                            nzerosFCU = insert(nzerosFCR(i),nzerosFCU,i);
                            zerosFCU = insert(zerosFCR(i),zerosFCU,i);
                        end
                    end
                end
            end
                    
            % if there are points too close together, remove one of them.

            i = 1;
            l = numel(zerosECU);
            while i < l
                if (nzerosECU(i+1)-nzerosECU(i))/nRate < 0.5*tBeat
                    nzerosECU(i+1)=[];
                    zerosECU(i+1)=[];
                    i = i-1;
                    l = l-1;
                end
                i= i+1;
            end
            i = 1;
            l = numel(zerosFCU);
            while i < l
                if (nzerosFCU(i+1)-nzerosFCU(i))/nRate < 0.5*tBeat
                    nzerosFCU(i+1)=[];
                    zerosFCU(i+1)=[];
                    i = i-1;
                    l = l-1;
                end
                i= i+1;
            end
            i = 1;
            l = numel(zerosFCR);
            while i < l
                if (nzerosFCR(i+1)-nzerosFCR(i))/nRate < 0.5*tBeat
                    nzerosFCR(i+1)=[];
                    zerosFCR(i+1)=[];
                    i = i-1;
                    l = l-1;
                end
                i= i+1;
            end

            
            % add any events at the beginning that were missed by other
            % signals
            if numel(zerosECU) ~= numel(zerosFCU) || numel(zerosECU) ~= numel(zerosFCR) || numel(zerosFCU) ~= numel(zerosFCR)
                if numel(zerosECU) > numel(zerosFCU) && numel(zerosECU) > numel(zerosFCR)
                    extraFCU = numel(zerosECU)-numel(zerosFCU);
                    extraFCR = numel(zerosECU) - numel(zerosFCR);
                    for i = 1:extraFCU
                        nzerosFCU = insert(nzerosECU(i),nzerosFCU,i);
                        zerosFCU = insert(zerosECU(i),zerosFCU,i);
                    end
                    for i = 1:extraFCR
                        nzerosFCR = insert(nzerosECU(i),nzerosFCR,i);
                        zerosFCR = insert(zerosECU(i),zerosFCR,i);
                    end
                elseif numel(zerosFCU) > numel(zerosECU) && numel(zerosFCU) > numel(zerosFCR)
                    extraECU = numel(zerosFCU)-numel(zerosECU);
                    extraFCR = numel(zerosFCU)-numel(zerosFCR);
                    for i = 1:extraECU
                        nzerosECU = insert(nzerosFCU(i),nzerosECU,i);
                        zerosECU = insert(zerosFCU(i),zerosECU,i);
                    end
                    for i = 1:extraFCR
                        nzerosFCR = insert(nzerosFCU(i),nzerosFCR,i);
                        zerosFCR = insert(zerosFCU(i),zerosFCR,i);
                    end
                elseif numel(zerosFCR) > numel(zerosECU) && numel(zerosFCR) > numel(zerosFCU)
                    extraECU = numel(zerosFCR)-numel(zerosECU);
                    extraFCU = numel(zerosFCR)-numel(zerosFCU);
                    for i = 1:extraECU
                        nzerosECU = insert(nzerosFCR(i),nzerosECU,i);
                        zerosECU = insert(zerosFCR(i),zerosECU,i);
                    end
                    for i = 1:extraFCU
                        nzerosFCU = insert(nzerosFCR(i),nzerosFCU,i);
                        zerosFCU = insert(zerosFCR(i),zerosFCU,i);
                    end
                end
            end

            % add any events at the end that were missed by other signals

            if numel(zerosECU) ~= numel(zerosFCU) || numel(zerosECU) ~= numel(zerosFCR) || numel(zerosFCU) ~= numel(zerosFCR)
                if numel(zerosECU) > numel(zerosFCU)
                    nzerosFCU = cat(1,nzerosFCU,nzerosECU(end));
                    zerosFCU = cat(1,zerosFCU, zerosECU(end));
                elseif numel(zerosECU)>numel(zerosFCR)
                    nzerosFCR = cat(1,nzerosFCR, nzerosECU(end));
                    zerosFCR = cat(1,zerosFCR, zerosECU(end));
                elseif numel(nzerosFCU)>numel(nzerosECU)
                    nzerosECU = cat(1,nzerosECU, nzerosFCU(end));
                    zerosECU = cat(1,zerosECU, zerosFCU(end));
                elseif numel(zerosFCU)>numel(zerosFCR)
                    nzerosFCR = cat(1,nzerosFCR, nzerosFCU(end));
                    zerosFCR = cat(1,zerosFCR, zerosFCU(end));
                elseif numel(nzerosFCR) > numel(nzerosECU)
                    nzerosECU = cat(1,nzerosECU, nzerosFCR(end));
                    zerosECU = cat(1,zerosECU, zerosFCR(end));
                else
                    nzerosFCU = cat(1,nzerosFCU,nzerosFCR(end));
                    zerosFCU = cat(1,zerosFCU, zerosFCR(end));
                end
            end



            % finish combining events into a single array
            if isempty(events)
                events = zeros(max([numel(zerosECU),numel(zerosFCU),numel(zerosFCR)]),1);
                nevents = zeros(max([numel(zerosECU),numel(zerosFCU),numel(zerosFCR)]),1);
                for i = 1:numel(zerosECU)
                    events(i) = mean([zerosECU(i),zerosFCU(i),zerosFCR(i)]);
                    nevents(i) = round(mean([nzerosECU(i),nzerosFCU(i),nzerosFCR(i)]),0);
                end
            end


            % Specific actions for certain trials:
            if idTrial == 28
                events = events(2:end);
                nevents = nevents(2:end);
            end % something was wonky with the first event for this trial

            if idTrial == 27
                events = events(4:end);
                nevents = nevents(4:end);
            end % first two placed events were inconsistent with the rest...
            % (ie did not actually represent zero crossings once averaged...
            % across all 3 signals)

            if idTrial == 52
                events = events(3:end);
                nevents = nevents(3:end);
            end % first two placed events were inconsistent with the rest...
            % (ie did not actually represent zero crossings once averaged...
            % across all 3 signals)


            % if there are points too close together, remove one of them.
            i = 1;
            l = numel(zerosECU);
            while i < l
                if (nzerosECU(i+1)-nzerosECU(i))/nRate < 0.5*tBeat
                    nzerosECU(i+1)=[];
                    zerosECU(i+1)=[];
                    i = i-1;
                    l = l-1;
                end
                i= i+1;
            end
            i = 1;
            l = numel(zerosFCU);
            while i < l
                if (nzerosFCU(i+1)-nzerosFCU(i))/nRate < 0.5*tBeat
                    nzerosFCU(i+1)=[];
                    zerosFCU(i+1)=[];
                    i = i-1;
                    l = l-1;
                end
                i= i+1;
            end
            i = 1;
            l = numel(zerosFCR);
            while i < l
                if (nzerosFCR(i+1)-nzerosFCR(i))/nRate < 0.5*tBeat
                    nzerosFCR(i+1)=[];
                    zerosFCR(i+1)=[];
                    i = i-1;
                    l = l-1;
                end
                i= i+1;
            end

            % place events where they should go on the velocity data
            eventsECU = zeros(numel(events),1);
            eventsFCU = zeros(numel(events),1);
            eventsFCR = zeros(numel(events),1);

            for i = 1:numel(events)
                eventsECU(i) = highpassECU(nevents(i));
                eventsFCU(i) = highpassFCU(nevents(i));
                eventsFCR(i) = highpassFCR(nevents(i));
            end


            startUp = [];
            startDown = [];
            % identify start direction
            % FCR is on the underside of the arm. The z-acceleration, 
            % which should dominate the signal, is
            % positive when pointing nearly straight down. So, when FCR
            % acceleration is positive it's a downward motion and when it's
            % negative it's an upward motion. Therefore if the movement
            % begins with positive velocity, it's a downward direction.
            diff = nevents(2)-nevents(1);
            direct = mean(highpassFCR(nevents(1):nevents(1)+round(0.25*diff,0)));
            odds = [];
            evens = [];
            if mod(numel(nevents),0)==0
                evens = nevents(2:2:end);
                odds = nevents(1:2:numel(nevents)-1);
            else
                evens = nevents(2:2:numel(nevents)-1);
                odds = nevents(1:2:end);
            end

            if direct > 0
                startDown = odds;
                startUp = evens;
            else
                startUp = odds;
                startDown = evens;
            end


            % Shift the indices so that the time calculation is right 
            nzerosECU = nzerosECU+nStart;
            nzerosFCU = nzerosFCU+nStart;
            nzerosFCR = nzerosFCR+nStart;

            nevents = nevents+nStart;
            startUp = startUp + nStart;
            startDown = startDown + nStart;

            if nzerosECU(end) > numel(nx)
                nzerosECU(end) = numel(nx);
            end
            if nzerosFCU(end) > numel(nx)
                nzerosFCU(end) = numel(nx);
            end
            if nzerosFCR(end) > numel(nx)
                nzerosFCR(end) = numel(nx);
            end
            if nevents(end) > numel(nx)
                nevents(end) = numel(nx);
            end


            % calculate time of each event
            tzerosECU = nzerosECU/nRate;
            tzerosFCU = nzerosFCU/nRate;
            tzerosFCR = nzerosFCR/nRate;

            tevents = nevents/nRate;
            tStartUp = startUp/nRate;
            tStartDown = startDown/nRate;


            % get the amount of time each movement takes (this should equal
            % tBeat)
            timeEventECU = [];
            for i = 1:numel(zerosECU)-1
                timeEventECU(i)= tzerosECU(i+1)-tzerosECU(i);
            end
            timeEventFCU = [];
            for i = 1:numel(zerosFCU)-1
                timeEventFCU(i)= tzerosFCU(i+1)-tzerosFCU(i);
            end
            timeEventFCR = [];
            for i = 1:numel(zerosFCR)-1
                timeEventFCR(i)= tzerosFCR(i+1)-tzerosFCR(i);
            end
            timeEvent = [];
            for i = 1:numel(events)-1
                timeEvent(i) = tevents(i+1)-tevents(i);
            end

            % since the difference arrays are 1 shorter than the event
            % arrays, the corresponding time arrays for them need to be one
            % shorter as well
            xECU = tzerosECU(2:end);
            xFCU = tzerosFCU(2:end);
            xFCR = tzerosFCR(2:end);
            x = tevents(2:end);

            % this is for plotting purposes. The following arrays represent
            % horizontal lines at the amount of time a movement should take
            avECU = tBeat*ones(1,numel(xECU));
            avFCU = tBeat*ones(1,numel(xFCU));
            avFCR = tBeat*ones(1,numel(xFCR));
            av = tBeat*ones(1,numel(x));


            


            figure
            subplot(3,1,1)
            plot(xECU,avECU,xECU,timeEventECU)
            ylabel('ECU')
            legend('Theoretical Difference','Experimental Difference',Location='best') %'Acceleration',

            subplot(3,1,2)
            plot(xFCU,avFCU,xFCU,timeEventFCU)
            ylabel('FCU')

            subplot(3,1,3)
            plot(xFCR,avFCR,xFCR,timeEventFCR)
            ylabel('FCR')
            xlabel('Time (s)')
            sgtitle(['Length of Movements idTrial ',num2str(idTrial)])

            % figure
            % plot(x,av,x,timeEvent)
            % ylabel('Difference (s)')
            % legend('Theoretical Difference','Experimental Difference',Location='best')
            % xlabel('Time (s)')
            % title(['Length of Movements idTrial ',num2str(idTrial)])


            figure
            subplot(3,1,1)
            plot(time,highpassECU)
            hold on
            %plot(time,ECU)
            % plot(tStart,highpassECU(1),'>')
            % plot(tStop,highpassECU(end),'>')
            % plot(tevents,eventsECU,'o')
            plot(tStartUp,highpassECU(startUp-nStart),'ro')
            plot(tStartDown,highpassECU(startDown-nStart),'ko')
            legend('Velocity','Up Events','Down Events',Location='best') %'Acceleration',
            ylabel('ECU')
            hold off

            subplot(3,1,2)
            plot(time,highpassFCU)
            hold on
            %plot(time,FCU)
            % plot(tStart,highpassFCU(1),'>')
            % plot(tStop,highpassFCU(end),'>')
            % plot(tevents,eventsFCU,'o')
            %plot(tzerosFCU,zerosFCU,'o')
            plot(tStartUp,highpassFCU(startUp-nStart),'ro')
            plot(tStartDown,highpassFCU(startDown-nStart),'ko')
            % legend('Velocity','Events',Location='best')%'Acceleration',
            ylabel('FCU')
            hold off

            subplot(3,1,3)
            plot(time,highpassFCR)
            hold on
            %plot(time,FCR)
            % plot(tStart,highpassFCR(1),'>')
            % plot(tStop,highpassFCR(end),'>')
            % plot(tevents,eventsFCR,'o')
            %plot(tzerosFCR,zerosFCR,'o')
            plot(tStartUp,highpassFCR(startUp-nStart),'ro')
            plot(tStartDown,highpassFCR(startDown-nStart),'ko')
            % legend('Velocity','Events',Location='best') %'Acceleration',
            ylabel('FCR')
            hold off
            xlabel('Time (s)')
            sgtitle(['Velocity and Acceleration idTrial ',num2str(idTrial)])


            
            % % Note to Katie on Event types: 1 is on, 2 is off, 3 is peak,
            % % and 4 is trough

            dbox.modEvent({'idTrial',idTrial,'idSignal',idSignalEvent},'bEvent',0);
            dbox.setEvent(tStartUp,idTrial,idSignalEvent,1);
            dbox.setEvent(tStartDown,idTrial,idSignalEvent,2);

            display(['Finished idTrial ',num2str(idTrial)])
            
        end
    end
end