% Purpose: Fit sinusoidal function to data sets, calculate RMSE between
% data and sinusoid, use RMSE to determine start and stop times of motion
%
% NOTES:
% good subjects [1,4,6:9]
% idSubject 2, idTrial 6 is the only good one; the rest do not have
%       movements recorded; accelerations and touch signals are not regular
% idSubject 2, 3, 5 are not good
% idSubject 6, idTrial 39 unequal ACC and EMG signals
% idSubject 10 does not have emgraw.Touch, accraw.TagretC, accraw.TagretU,
%       accraw.TagretS, accraw.FCRX, accraw.FCRY,and accraw.FCRZ signals
%
clear
clc
%% load database
sPathSource = "G:\Shared drives\LABS-DATASETS\DATASET_REACH_ORIENTATION";
dbox        = databox();
dbox.loadMeta(sPathSource);
%% 
idSubject       = [8]; % finished for idSubjects 1, 4, 6:9
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
            tStart = dbox.getEvent(idTrial,idSignalEvent,'peak',1);
            tStop  = dbox.getEvent(idTrial,idSignalEvent,'off',1);


            % get the datapoint values associated with start and stop
            % points
            nStart = round(tStart*nRate,0);
            nStop = round(tStop*nRate,0);

            % make sure nStop doesn't go past the number of datapoints we
            % have
            if nStop > numel(nVecF)
                nStop = numel(nVecF);
                tStop = nStop/nRate;
            end

            % select range of data to fit sinusoid to

            move = nStart:nStop;
            nMove = numel(move);
            nSegment = round(nMove/40,0); % adding/subtracting 1/40 of the data to each side should leave me with 95% of the dataset to fit the sinusoid to
            y = nVecF(nStart+nSegment:nStop-nSegment); %trying to fit to just segments that are towards the middle
            x = nStart+nSegment:nStop-nSegment;
            

            %fit data
            fitoutput = fit(x',y','sin8');

            nx = 0:numel(nVecF)-1;

            fitted = fitoutput(nx);

            
            %error between fitted curve and real data
            errUF = rmse(fitted',nVecF,1); %unfiltered error

            errMoveUF = errUF(nStart+nSegment:nStop-nSegment);
            errMoveAveUF = mean(errMoveUF);
            stdMoveUF = std(errMoveUF);

            errBefore = errUF(1+round(nRate,0):nStart-30); % get the error before the start point, excluding the very beginning
            errBeforeAve = mean(errBefore);
            stdBefore = std(errBefore);


            %filter error signal

            if errBeforeAve > errMoveAveUF + 3*stdMoveUF % if error before and error during are too close, filtering makes things worse
                err = butterfilt(errUF,nRate,1,'nOrder',2); % if messing with this doesn't help, return the cutoff freq to 3Hz
            else
                err = errUF; % this keeps the error unfiltered if error before and during are too close
            end

            %get error from the middle section of the movement
            errMove = err(nStart+nSegment:nStop-nSegment);
            errMoveAve = mean(errMove);
            stdMove = std(errMove);

            % assume that the halfway point between the estimated start and
            % stop points is within the actual movement
            nHalf = nStart + round(nMove/2,0);

            nStopPro = nStop;


            if nStopPro < (numel(nVecF)-35) %if nStop is right at the end of the signal, we don't need to move it
                if errBeforeAve > errMoveAveUF + 3*stdMoveUF % if error before is much greater than error during, threshold for moving is 2 stds
                    for i = nStop:-1:nHalf
                        if err(i)>2*stdMove+errMoveAve
                            nStopPro= nStopPro-1;
                        end
                    end
                else % if error before is not much greater than error during, threshold for moving is 3 stds
                    for i = nStop:-1:nHalf
                        if err(i)>3*stdMove+errMoveAve
                            nStopPro= nStopPro-1;
                        end
                    end
                end
            end

            
            % BELOW THIS LINE IS FCU SIGNAL WORK


 nData      = dbox.getSignal(idSignalListFCU(1),idTrial,'sScript',sScript);
            nData(2,:) = dbox.getSignal(idSignalListFCU(2),idTrial,'sScript',sScript);
            nData(3,:) = dbox.getSignal(idSignalListFCU(3),idTrial,'sScript',sScript);
            nVec     = sqrt(sum(nData.^2,1));
            nVecFFCU    = butterfilt(abs(nVec-mean(nVec)),nRate,3,'nOrder',2);

            % select range of data to fit sinusoid to
            y = nVecFFCU(nStart+nSegment:nStop-nSegment);
            x = nStart+nSegment:nStop-nSegment;


            %fit data
            fitoutputFCU = fit(x',y','sin8');

            nx = 0:numel(nVecFFCU)-1;

            fittedFCU = fitoutputFCU(nx);


            %error between fitted curve and real data
            errFCUUF = rmse(fittedFCU',nVecFFCU,1);


            errFCUMoveUF = errFCUUF(nStart+nSegment:nStop-nSegment);
            errFCUMoveAveUF = mean(errFCUMoveUF);
            stdFCUMoveUF = std(errFCUMoveUF);

            errBeforeFCU = errFCUUF(1+round(nRate,0)):nStart-30;
            errBeforeFCUAve = mean(errBeforeFCU);
            stdBeforeFCU = std(errBeforeFCU);

            if errBeforeFCUAve > errFCUMoveAveUF+3*stdFCUMoveUF
                errFCU = butterfilt(errFCUUF,nRate,1,'nOrder',2);
            else
                errFCU = errFCUUF;
            end


            %get error from the middle section of the movement
            errMoveFCU = errFCU(nStart+nSegment:nStop-nSegment);
            errMoveAveFCU = mean(errMoveFCU);
            stdMoveFCU = std(errMoveFCU);

            nStopProFCU = nStop;

            if nStopProFCU < (numel(nVecF)-35) % if nStop is right at the end it doesn't need to move
                if errBeforeFCUAve>errMoveAveFCU+3*stdMoveFCU
                    for i = nStop:-1:nHalf
                        if errFCU(i)>2.5*stdMoveFCU+errMoveAveFCU
                            nStopProFCU= nStopProFCU-1;
                        end
                    end
                else
                    for i = nStop:-1:nHalf
                        if errFCU(i)>3.5*stdMoveFCU+errMoveAveFCU
                            nStopProFCU= nStopProFCU-1;
                        end
                    end
                end
            end


            % BELOW THIS LINE IS FCR SIGNAL WORK


 nData      = dbox.getSignal(idSignalListFCR(1),idTrial,'sScript',sScript);
            nData(2,:) = dbox.getSignal(idSignalListFCR(2),idTrial,'sScript',sScript);
            nData(3,:) = dbox.getSignal(idSignalListFCR(3),idTrial,'sScript',sScript);
            nVec     = sqrt(sum(nData.^2,1));
            nVecFFCR    = butterfilt(abs(nVec-mean(nVec)),nRate,3,'nOrder',2);

            % select range of data to fit sinusoid to
            y = nVecFFCR(nStart+nSegment:nStop-nSegment);
            x = nStart+nSegment:nStop-nSegment;


            %fit data
            fitoutputFCR = fit(x',y','sin8');

            nx = 0:numel(nVecFFCR)-1;

            fittedFCR = fitoutputFCR(nx);


            %error between fitted curve and real data
            errFCRUF = rmse(fittedFCR',nVecFFCR,1);


            errFCRMoveUF = errFCRUF(nStart+nSegment:nStop-nSegment);
            errFCRMoveAveUF = mean(errFCRMoveUF);
            stdFCRMoveUF = std(errFCRMoveUF);

            errBeforeFCR = errFCRUF(1+round(nRate,0)):nStart-30;
            errBeforeFCRAve = mean(errBeforeFCR);
            stdBeforeFCR = std(errBeforeFCR);

            if errBeforeFCRAve > errFCRMoveAveUF+3*stdFCRMoveUF
                errFCR = butterfilt(errFCRUF,nRate,1,'nOrder',2);
            else
                errFCR = errFCRUF;
            end


            %get error from the middle section of the movement
            errMoveFCR = errFCU(nStart+nSegment:nStop-nSegment);
            errMoveAveFCR = mean(errMoveFCR);
            stdMoveFCR = std(errMoveFCR);


            nStopProFCR = nStop;

            if nStopPro < (numel(nVecF)-35) % if nStop is right at the end it doesn't need to move
                if errBeforeFCRAve>errMoveAveFCR+3*stdMoveFCR
                    for i = nStop:-1:nHalf
                        if errFCR(i)>2.5*stdMoveFCR+errMoveAveFCR
                            nStopProFCR= nStopProFCR-1;
                        end
                    end
                else
                    for i = nStop:-1:nHalf
                        if errFCR(i)>3.5*stdMoveFCR+errMoveAveFCR
                            nStopProFCR= nStopProFCR-1;
                        end
                    end
                end
            end

            nStopNew = round((nStopPro+nStopProFCR+nStopProFCU)/3,0);

            tStopNew = nStopNew/nRate;
            

            % figure
            % subplot(3,1,1)
            % plot(nx/nRate,nVecF)
            % hold on
            % plot(tStart,nVecF(nStart),'>')
            % plot(tStopNew,nVecF(nStopNew),'>')
            % ylabel('ECU Signal')
            % hold off
            % 
            % subplot(3,1,2)
            % plot(nx/nRate,nVecFFCU)
            % hold on
            % plot(tStart,nVecFFCU(nStart),'>')
            % plot(tStopNew,nVecFFCU(nStopNew),'>')
            % ylabel('FCU Signal')
            % hold off
            % 
            % subplot(3,1,3)
            % plot(nx/nRate, nVecFFCR)
            % hold on
            % plot(tStart,nVecFFCR(nStart),'>')
            % plot(tStopNew,nVecFFCU(nStopNew),'>')
            % ylabel('FCR Signal')
            % hold off
            % xlabel('Time (s)')
            % sgtitle(['idTrial ',num2str(idTrial)])

            if (nStart-2*nSegment) > 0
                if tBeat == 0.75
                    [tEvent,idType,out] = getBurst(nx(nStart-2*nSegment:nHalf)/nRate, ...
                        nVecF(nStart-2*nSegment:nHalf),'Tbmin',(tBeat/2),'Tbmax',(tBeat*2.5), ...
                        'T0min',tBeat);

                    [tEventFCU,idTypeFCU,outFCU] = getBurst(nx(nStart-2*nSegment:nHalf)/nRate, ...
                        nVecFFCU(nStart-2*nSegment:nHalf),'Tbmin',(tBeat/2),'Tbmax',(tBeat*2.5), ...
                        'T0min',tBeat);

                    [tEventFCR,idTypeFCR,outFCR] = getBurst(nx(nStart-2*nSegment:nHalf)/nRate, ...
                        nVecFFCR(nStart-2*nSegment:nHalf),'Tbmin',(tBeat/2),'Tbmax',(tBeat*2.5), ...
                        'T0min',tBeat);
                else
                    [tEvent,idType,out] = getBurst(nx(nStart-3*nSegment:nHalf)/nRate, ...
                        nVecF(nStart-3*nSegment:nHalf),'Tbmin',(tBeat/4),'Tbmax',(tBeat*2));

                    [tEventFCU,idTypeFCU,outFCU] = getBurst(nx(nStart-3*nSegment:nHalf)/nRate, ...
                        nVecFFCU(nStart-3*nSegment:nHalf),'Tbmin',(tBeat/4),'Tbmax',(tBeat*2));

                    [tEventFCR,idTypeFCR,outFCR] = getBurst(nx(nStart-3*nSegment:nHalf)/nRate, ...
                        nVecFFCR(nStart-3*nSegment:nHalf),'Tbmin',(tBeat/4),'Tbmax',(tBeat*2));
                end
            end


            % initialize minimum values to large numbers so that if certain
            % signals don't have burst events there is still a 'min value'
            % but it won't be the minimum of all 3 signals
            minECU = nx(end);
            minFCU = nx(end);
            minFCR = nx(end);

            tMinECU = nx(end);
            tMinFCU = nx(end);
            tMinFCR = nx(end);

            nMinECU = nx(end);
            nMinFCU = nx(end);
            nMinFCR = nx(end);

            % for each non empty list of events, we get the minimum
            % distance between an event and tStart, the index of tEvent at
            % which that event takes place, and the time at which that
            % event takes place. This gives us the burst closest to tStart
            % for that signal
            if ~isempty(tEvent)
                diffECU = inf(1,length(tEvent));
                for i = 1:length(tEvent)
                    diffECU(i) = abs(tStart-tEvent(i));
                end
                [minECU,nMinECU] = min(diffECU);
                tMinECU = tEvent(nMinECU);
            end
            if ~isempty(tEventFCU)
                diffFCU = inf(1,length(tEventFCU));
                for i = 1:length(tEventFCU)
                    diffFCU(i) = abs(tStart-tEventFCU(i));
                end
                [minFCU,nMinFCU] = min(diffFCU);
                tMinFCU = tEventFCU(nMinFCU);
            end
            if ~isempty(tEventFCR)
                diffFCR = inf(1,length(tEventFCR));
                for i = 1:length(tEventFCR)
                    diffFCR(i) = abs(tStart-tEventFCR(i));
                end
                [minFCR,nMinFCR] = min(diffFCR);
                tMinFCR = tEventFCR(nMinFCR);
            end

            % place the burst of interest at the time where the distance
            % between the burst and tStart is the smallest.

            minimums = [minECU,minFCU,minFCR];
            burst1 = min(minimums);
            if burst1 == minECU
                tBurst1 = tMinECU;
            elseif burst1 == minFCU
                tBurst1 = tMinFCU;
            else
                tBurst1 = tMinFCR;
            end

            if (isempty(tEvent) && isempty(tEventFCU) && isempty(tEventFCR)) || (nStart-2*nSegment) < 0
                tBurst1 = tStart;
            end

            if idTrial == 63
                tBurst1 = 10;
            end

            % for plotting all of the bursts
            indexECU = round(tEvent*nRate,0);
            pointsECU = nx(indexECU);

            indexFCU = round(tEventFCU*nRate,0);
            pointsFCU = nx(indexFCU);

            indexFCR = round(tEventFCR*nRate,0);
            pointsFCR = nx(indexFCR);

            figure
            subplot(3,1,1)
            plot(nx/nRate,nVecF)
            hold on
            plot(tStopNew,nVecF(nStopNew),'>')
            plot(tStart,nVecF(nStart),'^')
            plot(tBurst1,nVecF(round(tBurst1*nRate,0)),'o')
            plot(tEvent,nVecF(indexECU),'*')
            ylabel('ECU Signal')
            hold off
            subplot(3,1,2)
            plot(nx/nRate,nVecFFCU)
            hold on
            plot(tStopNew,nVecFFCU(nStopNew),'>')
            plot(tStart,nVecFFCU(nStart),'^')
            plot(tBurst1,nVecFFCU(round(tBurst1*nRate,0)),'o')
            plot(tEventFCU,nVecFFCU(indexFCU),'*')
            ylabel('FCU Signal')
            hold off
            subplot(3,1,3)
            plot(nx/nRate,nVecFFCR)
            hold on
            plot(tStopNew,nVecFFCR(nStopNew),'>')
            plot(tStart,nVecFFCR(nStart),'^')
            plot(tBurst1,nVecFFCR(round(tBurst1*nRate,0)),'o')
            plot(tEventFCR,nVecFFCR(indexFCR),'*')
            ylabel('FCR Signal')
            hold off
            xlabel('Time (s)')
            sgtitle(['idTrial ',num2str(idTrial)])


            
            % % Note to Katie on Event types: 1 is on, 2 is off, 3 is peak,
            % % and 4 is trough

            dbox.modEvent({'idTrial',idTrial,'idSignal',idSignalEvent},'bEvent',0);
            dbox.setEvent(tBurst1,idTrial,idSignalEvent,1);
            dbox.setEvent(tStopNew,idTrial,idSignalEvent,2);

            display(['Finished idTrial ',num2str(idTrial)])
            
        end
    end
end