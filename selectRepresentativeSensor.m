% determines the best sensor (FCR/FCU/ECU) to determine movement
% onset/offset times from.

% Scores FCR, FCU, and ECU for signal to noise ratio, cadence peak
% compatible with nBeat

clear
clc

%% load database
sPathSource = "G:\Shared drives\LABS-DATASETS\DATASET_REACH_ORIENTATION";
dbox        = databox();
dbox.loadMeta(sPathSource);
%%

% initialize score values to zero
% scores will be used to determine which signal is best for each subject
% and movement type
% Note: a maximum of 2 signals will be used for each subject, one per
% movement type (ie: ECUx for horizontal movements of the subject but ECUy
% for vertical movements of the same subject)
scoreECUx = 0;
scoreECUy = 0;
scoreECUz = 0;

scoreFCUx = 0;
scoreFCUy = 0;
scoreFCUz = 0;

scoreFCRx = 0;
scoreFCRy = 0;
scoreFCRz = 0;

% initialize vertical and horizontal scores to 0. Vertical and Horizontal
% scores reflect which signal shows clearest differences between peaks and
% valleys for different movement types
hECUx = 0;
hECUy = 0;
hECUz = 0;
vECUx = 0;
vECUy = 0;
vECUz = 0;

hFCUx = 0;
hFCUy = 0;
hFCUz = 0;
vFCUx = 0;
vFCUy = 0;
vFCUz = 0;

hFCRx = 0;
hFCRy = 0;
hFCRz = 0;
vFCRx = 0;
vFCRy = 0;
vFCRz = 0;

% initialize counters to zero
% I will be using these as a manual check on one or two subjects to make
% sure the scoring makes sense. They do not actually impact score
countBestNoiseECUx = 0;
countBestNoiseECUy = 0;
countBestNoiseECUz = 0;

countBestNoiseFCUx = 0;
countBestNoiseFCUy = 0;
countBestNoiseFCUz = 0;

countBestNoiseFCRx = 0;
countBestNoiseFCRy = 0;
countBestNoiseFCRz = 0;


countWorstNoiseECUx = 0;
countWorstNoiseECUy = 0;
countWorstNoiseECUz = 0;

countWorstNoiseFCUx = 0;
countWorstNoiseFCUy = 0;
countWorstNoiseFCUz = 0;

countWorstNoiseFCRx = 0;
countWorstNoiseFCRy = 0;
countWorstNoiseFCRz = 0;


% pull trial data
idSubject      = [6];
idSignalEvent   = [57];
sScript         = 'nData = butterfilt(nData,nRate,6,''nOrder'',2);';
sTable          = 'accraw';
sSignalList     = {'ECU_X','ECU_Y','ECU_Z'};
sSignalListFCU  = {'FCU_X','FCU_Y','FCU_Z'};
sSignalListFCR  = {'FCR_X','FCR_Y','FCR_Z'};
sTrialTypeList  = {'UP_HF','UP_HS','SIDE_HF','SIDE_HS','SIDE_VF','SIDE_VS','UP_VF','UP_VS'}; %'UP_HF','UP_HS','SIDE_HF','SIDE_HS','SIDE_VF','SIDE_VS','UP_VF','UP_VS'
idTrialTypeF   = [7,9,11,13]; %fast movements
idTrialTypeS   = [7,9,11,13]+1; %slow movements
idTrialTypeH   = [7:10]; %horizontal trial
idTrialTypeV   = [11:14]; %vertical trial

idSignalListECU = dbox.getMeta('metaSignal',{'sTable',sTable,...
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

            % Pull accelerometer data. Note: All matrices will have X
            % axis in row 1, Y axis in row 2, and Z axis in row 3

            % grab ECU data
            nDataECU      = dbox.getSignal(idSignalListECU(1),idTrial,'sScript',sScript);
            nDataECU(2,:) = dbox.getSignal(idSignalListECU(2),idTrial,'sScript',sScript);
            nDataECU(3,:) = dbox.getSignal(idSignalListECU(3),idTrial,'sScript',sScript);

            % grab FCU Data
            nDataFCU = dbox.getSignal(idSignalListFCU(1),idTrial,'sScript',sScript);
            nDataFCU(2,:) = dbox.getSignal(idSignalListFCU(2),idTrial,'sScript',sScript);
            nDataFCU(3,:) = dbox.getSignal(idSignalListFCU(3),idTrial,'sScript',sScript);

            % grab FCR Data
            nDataFCR = dbox.getSignal(idSignalListFCR(1),idTrial,'sScript',sScript);
            nDataFCR(2,:) = dbox.getSignal(idSignalListFCR(2),idTrial,'sScript',sScript);
            nDataFCR(3,:) = dbox.getSignal(idSignalListFCR(3),idTrial,'sScript',sScript);

            x = 0:1:length(nDataECU)-1;
            t = x/nRate;

            nBeat = dbox.getMeta('metaTrialType',{'idTrialType',idTrialType},'nBeat'); 


            % check that there are no nan values in any of the signals. If
            % there are, reduce that signal's score by 1000 to eliminate it
            % as an option
            for i = 1:length(nDataECU)-1
                if isnan(nDataECU(1,i))
                    scoreECUx = scoreECUx-1000;
                end
                if isnan(nDataECU(2,i))
                    scoreECUy = scoreECUy-1000;
                end
                if isnan(nDataECU(3,i))
                    scoreECUz = scoreECUz-1000;
                end
            end
            for i = 1:length(nDataFCU)-1
                if isnan(nDataFCU(1,i))
                    scoreFCUx = scoreFCUx-1000;
                end
                if isnan(nDataFCU(2,i))
                    scoreFCUy = scoreFCUy-1000;
                end
                if isnan(nDataFCU(3,i))
                    scoreFCUz = scoreFCUz-1000;
                end
            end
            for i = 1:length(nDataFCR)-1
                if isnan(nDataFCR(1,i))
                    scoreFCRx = scoreFCRx-1000;
                end
                if isnan(nDataFCR(2,i))
                    scoreFCRy = scoreFCRy-1000;
                end
                if isnan(nDataFCR(3,i))
                    scoreFCRz = scoreFCRz-1000;
                end
            end

            % Determine signal to noise ratio of each trial
            % Noise will be determined by lowpass filtering the data, then
            % subtracting the filtered data from the unfiltered data,
            % theoretically leaving the noise behind
            lowPassECUx = butterfilt(nDataECU(1,:),nRate,nBeat/60,'nOrder',2,'sType','low');
            lowPassECUy = butterfilt(nDataECU(2,:),nRate,nBeat/60,'nOrder',2,'sType','low');
            lowPassECUz = butterfilt(nDataECU(3,:),nRate,nBeat/60,'nOrder',2,'sType','low');

            lowPassFCUx = butterfilt(nDataFCU(1,:),nRate,nBeat/60,'nOrder',2,'sType','low');
            lowPassFCUy = butterfilt(nDataFCU(2,:),nRate,nBeat/60,'nOrder',2,'sType','low');
            lowPassFCUz = butterfilt(nDataFCU(3,:),nRate,nBeat/60,'nOrder',2,'sType','low');

            lowPassFCRx = butterfilt(nDataFCR(1,:),nRate,nBeat/60,'nOrder',2,'sType','low');
            lowPassFCRy = butterfilt(nDataFCR(2,:),nRate,nBeat/60,'nOrder',2,'sType','low');
            lowPassFCRz = butterfilt(nDataFCR(3,:),nRate,nBeat/60,'nOrder',2,'sType','low');


            noiseECUx = nDataECU(1,:)-lowPassECUx;
            noiseECUy = nDataECU(2,:)-lowPassECUy;
            noiseECUz = nDataECU(3,:)-lowPassECUz;

            noiseFCUx = nDataFCU(1,:)-lowPassFCUx;
            noiseFCUy = nDataFCU(2,:)-lowPassFCUy;
            noiseFCUz = nDataFCU(3,:)-lowPassFCUz;

            noiseFCRx = nDataFCR(1,:)-lowPassFCRx;
            noiseFCRy = nDataFCR(2,:)-lowPassFCRy;
            noiseFCRz = nDataFCR(3,:)-lowPassFCRz;


            % The comments below generate plots to show filtered and 
            % unfiltered data as well as noise for ECU as a manual check. I
            % have already checked it and it looks good, but I am leaving
            % the plotting in the code in case changes are made that
            % warrant rechecking

            % figure
            % subplot(3,2,1)
            % plot(t,nDataECU(1,:),t,lowPassECUx)
            % ylabel('ECU')
            % subplot(3,2,2)
            % plot(t,noiseECUx)
            % subplot(3,2,3)
            % plot(t,nDataECU(2,:),t,lowPassECUy)
            % ylabel('ECU')
            % subplot(3,2,4)
            % plot(t,noiseECUy)
            % subplot(3,2,5)
            % plot(t,nDataECU(3,:),t,lowPassECUz)
            % ylabel('ECU')
            % subplot(3,2,6)
            % plot(t,noiseECUz)
            % sgtitle(['idTrial ',num2str(idTrial)])
            % 
            % figure
            % subplot(3,2,1)
            % plot(t,nDataFCU(1,:),t,lowPassFCUx)
            % ylabel('FCU')
            % subplot(3,2,2)
            % plot(t,noiseFCUx)
            % subplot(3,2,3)
            % plot(t,nDataFCU(2,:),t,lowPassFCUy)
            % ylabel('FCU')
            % subplot(3,2,4)
            % plot(t,noiseFCUy)
            % subplot(3,2,5)
            % plot(t,nDataFCU(3,:),t,lowPassFCUz)
            % ylabel('FCU')
            % subplot(3,2,6)
            % plot(t,noiseFCUz)
            % sgtitle(['idTrial ',num2str(idTrial)])
            % 
            % figure
            % subplot(3,2,1)
            % plot(t,nDataFCR(1,:),t,lowPassFCRx)
            % ylabel('FCR')
            % subplot(3,2,2)
            % plot(t,noiseFCRx)
            % subplot(3,2,3)
            % plot(t,nDataFCR(2,:),t,lowPassFCRy)
            % ylabel('FCR')
            % subplot(3,2,4)
            % plot(t,noiseFCRy)
            % subplot(3,2,5)
            % plot(t,nDataFCR(3,:),t,lowPassFCRz)
            % ylabel('FCR')
            % subplot(3,2,6)
            % plot(t,noiseFCRz)
            % sgtitle(['idTrial ',num2str(idTrial)])
            

            % calculate the signal to noise ratio for each signal
            % using the matlab function snr()
            snrECUx = snr(nDataECU(1,:),noiseECUx);
            snrECUy = snr(nDataECU(2,:),noiseECUy);
            snrECUz = snr(nDataECU(3,:),noiseECUz);

            snrFCUx = snr(nDataFCU(1,:),noiseFCUx);
            snrFCUy = snr(nDataFCU(2,:),noiseFCUy);
            snrFCUz = snr(nDataFCU(3,:),noiseFCUz);

            snrFCRx = snr(nDataFCR(1,:),noiseFCRx);
            snrFCRy = snr(nDataFCR(2,:),noiseFCRy);
            snrFCRz = snr(nDataFCR(3,:),noiseFCRz);


            % get the max and min snr values
            maxSnr = max([snrECUx,snrECUy,snrECUz,snrFCUx,snrFCUy,snrFCUz,snrFCRx,snrFCRy,snrFCRz]);
            minSnr = min([snrECUx,snrECUy,snrECUz,snrFCUx,snrFCUy,snrFCUz,snrFCRx,snrFCRy,snrFCRz]);

            % assign points according to snr
            % add one point for the best snr
            % lose one point for the worst snr
            if snrECUx == maxSnr
                countBestNoiseECUx = countBestNoiseECUx+1;
                scoreECUx = scoreECUx+1;
            elseif snrECUy == maxSnr
                countBestNoiseECUy = countBestNoiseECUy+1;
                scoreECUy = scoreECUy+1;
            elseif snrECUz == maxSnr
                countBestNoiseECUz = countBestNoiseECUz+1;
                scoreECUz = scoreECUz+1;
            end

            if snrFCUx == maxSnr
                countBestNoiseFCUx = countBestNoiseFCUx+1;
                scoreFCUx = scoreFCUx+1;
            elseif snrFCUy == maxSnr
                countBestNoiseFCUy = countBestNoiseFCUy+1;
                scoreFCUy = scoreFCUy+1;
            elseif snrFCUz == maxSnr
                countBestNoiseFCUz = countBestNoiseFCUz+1;
                scoreFCUz = scoreFCUz+1;
            end

            if snrFCRx == maxSnr
                countBestNoiseFCRx = countBestNoiseFCRx+1;
                scoreFCRx = scoreFCRx+1;
            elseif snrFCRy == maxSnr
                countBestNoiseFCRy = countBestNoiseFCRy+1;
                scoreFCRy = scoreFCRy+1;
            elseif snrFCRz == maxSnr
                countBestNoiseFCRz = countBestNoiseFCRz+1;
                scoreFCRz = scoreFCRz+1;
            end


            if snrECUx == minSnr
                countWorstNoiseECUx = countWorstNoiseECUx+1;
                scoreECUx = scoreECUx-1;
            elseif snrECUy == minSnr
                countWorstNoiseECUy = countWorstNoiseECUy+1;
                scoreECUy = scoreECUy-1;
            elseif snrECUz == minSnr
                countWorstNoiseECUz = countWorstNoiseECUz+1;
                scoreECUz = scoreECUz-1;
            end

            if snrFCUx == minSnr
                countWorstNoiseFCUx = countWorstNoiseFCUx+1;
                scoreFCUx = scoreFCUx-1;
            elseif snrFCUy == minSnr
                countWorstNoiseFCUy = countWorstNoiseFCUy+1;
                scoreFCUy = scoreFCUy-1;
            elseif snrFCUz == minSnr
                countWorstNoiseFCUz = countWorstNoiseFCUz+1;
                scoreFCUz = scoreFCUz-1;
            end

            if snrFCRx == minSnr
                countWorstNoiseFCRx = countWorstNoiseFCRx+1;
                scoreFCRx = scoreFCRx-1;
            elseif snrFCRy == minSnr
                countWorstNoiseFCRy = countWorstNoiseFCRy+1;
                scoreFCRy = scoreFCRy-1;
            elseif snrFCRz == minSnr
                countWorstNoiseFCRz = countWorstNoiseFCRz+1;
                scoreFCRz = scoreFCRz-1;
            end


            % determine which signals have the greatest and least
            % differences between peaks and valleys. This will be used to
            % determine which axes are better for vertical vs horizontal
            % movements
            
            % I need to get the peaks and valleys (averaged) of the
            % movement. Pull the start and stop (approximate) times for
            % movement
            tStart = dbox.getEvent(idTrial,idSignalEvent,'on',1);
            tStop  = dbox.getEvent(idTrial,idSignalEvent,'off',1);

            nStart = round(tStart*nRate);
            nStop = round(tStop*nRate);

            % initialize peak and valley arrays to zeros
            ECUxpeaks = zeros(nStop,1);
            ECUypeaks = zeros(nStop,1);
            ECUzpeaks = zeros(nStop,1);

            FCUxpeaks = zeros(nStop,1);
            FCUypeaks = zeros(nStop,1);
            FCUzpeaks = zeros(nStop,1);

            FCRxpeaks = zeros(nStop,1);
            FCRypeaks = zeros(nStop,1);
            FCRzpeaks = zeros(nStop,1);

            ECUxvalleys = zeros(nStop,1);
            ECUyvalleys = zeros(nStop,1);
            ECUzvalleys = zeros(nStop,1);

            FCUxvalleys = zeros(nStop,1);
            FCUyvalleys = zeros(nStop,1);
            FCUzvalleys = zeros(nStop,1);

            FCRxvalleys = zeros(nStop,1);
            FCRyvalleys = zeros(nStop,1);
            FCRzvalleys = zeros(nStop,1);

            % get array of local maxes and mins (boolean values)
            maxesECUx = islocalmax(lowPassECUx);
            maxesECUy = islocalmax(lowPassECUy);
            maxesECUz = islocalmax(lowPassECUz);

            maxesFCUx = islocalmax(lowPassFCUx);
            maxesFCUy = islocalmax(lowPassFCUy);
            maxesFCUz = islocalmax(lowPassFCUz);

            maxesFCRx = islocalmax(lowPassFCRx);
            maxesFCRy = islocalmax(lowPassFCRy);
            maxesFCRz = islocalmax(lowPassFCRz);


            minsECUx = islocalmin(lowPassECUx);
            minsECUy = islocalmin(lowPassECUy);
            minsECUz = islocalmin(lowPassECUz);

            minsFCUx = islocalmin(lowPassFCUx);
            minsFCUy = islocalmin(lowPassFCUy);
            minsFCUz = islocalmin(lowPassFCUz);

            minsFCRx = islocalmin(lowPassFCRx);
            minsFCRy = islocalmin(lowPassFCRy);
            minsFCRz = islocalmin(lowPassFCRz);

            % go through the filtered movement data and add local max and 
            % min values to the arrays for peaks and valleys 
            for i = nStart:1:nStop
                if maxesECUx(i)
                    ECUxpeaks(i) = lowPassECUx(i);
                end
                if maxesECUy(i)
                    ECUypeaks(i) = lowPassECUy(i);
                end
                if maxesECUz(i)
                    ECUzpeaks(i) = lowPassECUz(i);
                end
                if maxesFCUx(i)
                    FCUxpeaks(i) = lowPassFCUx(i);
                end
                if maxesFCUy(i)
                    FCUypeaks(i) = lowPassFCUy(i);
                end
                if maxesFCUz(i)
                    FCUzpeaks(i) = lowPassFCUz(i);
                end
                if maxesFCRx(i)
                    FCRxpeaks(i) = lowPassFCRx(i);
                end
                if maxesFCRy(i)
                    FCRypeaks(i) = lowPassFCRy(i);
                end
                if maxesFCRz(i)
                    FCRzpeaks(i) = lowPassFCRz(i);
                end

                if minsECUx(i)
                    ECUxvalleys(i) = lowPassECUx(i);
                end
                if minsECUy(i)
                    ECUyvalleys(i) = lowPassECUy(i);
                end
                if minsECUz(i)
                    ECUzvalleys(i) = lowPassECUz(i);
                end
                if minsFCUx(i)
                    FCUxvalleys(i) = lowPassFCUx(i);
                end
                if minsFCUy(i)
                    FCUyvalleys(i) = lowPassFCUy(i);
                end
                if minsFCUz(i)
                    FCUzvalleys(i) = lowPassFCUz(i);
                end
                if minsFCRx(i)
                    FCRxvalleys(i) = lowPassFCRx(i);
                end
                if minsFCRy(i)
                    FCRyvalleys(i) = lowPassFCRy(i);
                end
                if minsFCRz(i)
                    FCRzvalleys(i) = lowPassFCRz(i);
                end
            end

            % get rid of any indices that don't have a max or min
            ECUxpeaks = nonzeros(ECUxpeaks);
            ECUypeaks = nonzeros(ECUypeaks);
            ECUzpeaks = nonzeros(ECUzpeaks);

            FCUxpeaks = nonzeros(FCUxpeaks);
            FCUypeaks = nonzeros(FCUypeaks);
            FCUzpeaks = nonzeros(FCUzpeaks);

            FCRxpeaks = nonzeros(FCRxpeaks);
            FCRypeaks = nonzeros(FCRypeaks);
            FCRzpeaks = nonzeros(FCRzpeaks);

            ECUxvalleys = nonzeros(ECUxvalleys);
            ECUyvalleys = nonzeros(ECUyvalleys);
            ECUzvalleys = nonzeros(ECUzvalleys);

            FCUxvalleys = nonzeros(FCUxvalleys);
            FCUyvalleys = nonzeros(FCUyvalleys);
            FCUzvalleys = nonzeros(FCUzvalleys);

            FCRxvalleys = nonzeros(FCRxvalleys);
            FCRyvalleys = nonzeros(FCRxvalleys);
            FCRzvalleys = nonzeros(FCRxvalleys);


            % get the average peak and valley values
            ECUxpeaksAve = mean(ECUxpeaks);
            ECUypeaksAve = mean(ECUypeaks);
            ECUzpeaksAve = mean(ECUzpeaks);

            FCUxpeaksAve = mean(FCUxpeaks);
            FCUypeaksAve = mean(FCUypeaks);
            FCUzpeaksAve = mean(FCUzpeaks);

            FCRxpeaksAve = mean(FCRxpeaks);
            FCRypeaksAve = mean(FCRypeaks);
            FCRzpeaksAve = mean(FCRzpeaks);


            ECUxvalleysAve = mean(ECUxvalleys);
            ECUyvalleysAve = mean(ECUyvalleys);
            ECUzvalleysAve = mean(ECUzvalleys);

            FCUxvalleysAve = mean(FCUxvalleys);
            FCUyvalleysAve = mean(FCUyvalleys);
            FCUzvalleysAve = mean(FCUzvalleys);

            FCRxvalleysAve = mean(FCRxvalleys);
            FCRyvalleysAve = mean(FCRyvalleys);
            FCRzvalleysAve = mean(FCRzvalleys);
            
            % calculate the difference between average peaks and average
            % valleys
            diffECUx = ECUxpeaksAve-ECUxvalleysAve;
            diffECUy = ECUypeaksAve-ECUyvalleysAve;
            diffECUz = ECUzpeaksAve-ECUzvalleysAve;

            diffFCUx = FCUxpeaksAve-FCUxvalleysAve;
            diffFCUy = FCUypeaksAve-FCUyvalleysAve;
            diffFCUz = FCUzpeaksAve-FCUzvalleysAve;

            diffFCRx = FCRxpeaksAve-FCRxvalleysAve;
            diffFCRy = FCRypeaksAve-FCRyvalleysAve;
            diffFCRz = FCRzpeaksAve-FCRzvalleysAve;


            % grab the maximum and minimum differences
            maxDiff = max([diffECUx,diffECUy,diffECUz,diffFCUx,diffFCUy, ...
                diffFCUz,diffFCRx,diffFCRy,diffFCRz]);
            minDiff = min([diffECUx,diffECUy,diffECUz,diffFCUx,diffFCUy, ...
                diffFCUz,diffFCRx,diffFCRy,diffFCRz]);


            % assign points based on max/min differences
            % the best options may differ according to horizontal and
            % vertical movements, so assignments are divided along those
            % lines
            % Bigger differences should make analysis easier, so get +1
            if ismember(idTrialType,[7:10])
                if maxDiff == diffECUx
                    hECUx = hECUx+1;
                elseif minDiff == diffECUx
                    hECUx = hECUx-1;
                end
                if maxDiff == diffECUy
                    hECUy = hECUy+1;
                elseif minDiff == diffECUy
                    hECUy = hECUy-1;
                end
                if maxDiff == diffECUz
                    hECUz = hECUz+1;
                elseif minDiff == diffECUz
                    hECUz = hECUz-1;
                end

                if maxDiff == diffFCUx
                    hFCUx = hFCUx+1;
                elseif minDiff == diffFCUx
                    hFCUx = hFCUx-1;
                end
                if maxDiff == diffFCUy
                    hFCUy = hFCUy+1;
                elseif minDiff == diffFCUy
                    hFCUy = hFCUy-1;
                end
                if maxDiff == diffFCUz
                    hFCUz = hFCUz+1;
                elseif minDiff == diffFCUz
                    hFCUz = hFCUz-1;
                end

                if maxDiff == diffFCRx
                    hFCRx = hFCRx+1;
                elseif minDiff == diffFCRx
                    hFCRx = hFCRx-1;
                end
                if maxDiff == diffFCUy
                    hFCRy = hFCRy+1;
                elseif minDiff == diffFCRy
                    hFCRy = hFCRy-1;
                end
                if maxDiff == diffFCRz
                    hFCRz = hFCRz+1;
                elseif minDiff == diffFCRz
                    hFCRz = hFCRz-1;
                end
            else
                if maxDiff == diffECUx
                    vECUx = vECUx+1;
                elseif minDiff == diffECUx
                    vECUx = vECUx-1;
                end
                if maxDiff == diffECUy
                    vECUy = vECUy+1;
                elseif minDiff == diffECUy
                    vECUy = vECUy-1;
                end
                if maxDiff == diffECUz
                    vECUz = vECUz+1;
                elseif minDiff == diffECUz
                    vECUz = vECUz-1;
                end

                if maxDiff == diffFCUx
                    vFCUx = vFCUx+1;
                elseif minDiff == diffFCUx
                    vFCUx = vFCUx-1;
                end
                if maxDiff == diffFCUy
                    vFCUy = vFCUy+1;
                elseif minDiff == diffFCUy
                    vFCUy = vFCUy-1;
                end
                if maxDiff == diffFCUz
                    vFCUz = vFCUz+1;
                elseif minDiff == diffFCUz
                    vFCUz = vFCUz-1;
                end

                if maxDiff == diffFCRx
                    vFCRx = vFCRx+1;
                elseif minDiff == diffFCRx
                    vFCRx = vFCRx-1;
                end
                if maxDiff == diffFCUy
                    vFCRy = vFCRy+1;
                elseif minDiff == diffFCRy
                    vFCRy = vFCRy-1;
                end
                if maxDiff == diffFCRz
                    vFCRz = vFCRz+1;
                elseif minDiff == diffFCRz
                    vFCRz = vFCRz-1;
                end
            end
            
        end
    end
end


% print out a table of score values for me to look at
Signal = ["ECUx";"ECUy";"ECUz";"FCUx";"FCUy";"FCUz";"FCRx";"FCRy";"FCRz"];
Scores = [scoreECUx;scoreECUy;scoreECUz;scoreFCUx;scoreFCUy;scoreFCUz;scoreFCRx;scoreFCRy;scoreFCRz];
horizontalScores = [hECUx;hECUy;hECUz;hFCUx;hFCUy;hFCUz;hFCRx;hFCRy;hFCRz];
verticalScores = [vECUx;vECUy;vECUz;vFCUx;vFCUy;vFCUz;vFCRx;vFCRy;vFCRz];
NumberWorstNoise = [countWorstNoiseECUx;countWorstNoiseECUy;countWorstNoiseECUz;
    countWorstNoiseFCUx;countWorstNoiseFCUy;countWorstNoiseFCUz;
    countWorstNoiseFCRx;countWorstNoiseFCRy;countWorstNoiseFCRz];
NumberBestNoise = [countBestNoiseECUx;countBestNoiseECUy;countBestNoiseECUz;
    countBestNoiseFCUx;countBestNoiseFCUy;countBestNoiseFCUz;
    countBestNoiseFCRx;countBestNoiseFCRy;countBestNoiseFCRz];
scoreboard = table(Signal,Scores,horizontalScores,verticalScores) %NumberWorstNoise,NumberBestNoise,
