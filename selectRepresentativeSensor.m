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

% initialize counters to zero
% I will be using these as a manual check on one or two subjects to make
% sure the scoring makes sense
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
idSubject      = [7];
idSignalEvent   = [10]; % not sure I need this remove it later if i don't
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
            lowPassECUx = butterfilt(nDataECU(1,:),nRate,1,'nOrder',2,'sType','low');
            lowPassECUy = butterfilt(nDataECU(2,:),nRate,1,'nOrder',2,'sType','low');
            lowPassECUz = butterfilt(nDataECU(3,:),nRate,1,'nOrder',2,'sType','low');

            lowPassFCUx = butterfilt(nDataFCU(1,:),nRate,1,'nOrder',2,'sType','low');
            lowPassFCUy = butterfilt(nDataFCU(2,:),nRate,1,'nOrder',2,'sType','low');
            lowPassFCUz = butterfilt(nDataFCU(3,:),nRate,1,'nOrder',2,'sType','low');

            lowPassFCRx = butterfilt(nDataFCR(1,:),nRate,1,'nOrder',2,'sType','low');
            lowPassFCRy = butterfilt(nDataFCR(2,:),nRate,1,'nOrder',2,'sType','low');
            lowPassFCRz = butterfilt(nDataFCR(3,:),nRate,1,'nOrder',2,'sType','low');


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
            % subplot(3,2,2)
            % plot(t,noiseECUx)
            % subplot(3,2,3)
            % plot(t,nDataECU(2,:),t,lowPassECUy)
            % subplot(3,2,4)
            % plot(t,noiseECUy)
            % subplot(3,2,5)
            % plot(t,nDataECU(3,:),t,lowPassECUz)
            % subplot(3,2,6)
            % plot(t,noiseECUz)

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

            % Signal = ["ECU";"FCU";"FCR"];
            % X = [snrECUx;snrFCUx;snrFCRx];
            % Y = [snrECUy;snrFCUy;snrFCRy];
            % Z = [snrECUz;snrFCUz;snrFCRz];
            % snrTable = table(Signal,X,Y,Z)

            snrECU = mean([snrECUx,snrECUy,snrECUz]);
            snrFCU = mean([snrFCUx,snrFCUy,snrFCUz]);
            snrFCR = mean([snrFCRx,snrFCRy,snrFCRz]);

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
                countWorstNoiseECUx = countBestNoiseECUx+1;
                scoreECUx = scoreECUx-1;
            elseif snrECUy == minSnr
                countWorstNoiseECUy = countBestNoiseECUy+1;
                scoreECUy = scoreECUy-1;
            elseif snrECUz == minSnr
                countWorstNoiseECUz = countBestNoiseECUz+1;
                scoreECUz = scoreECUz-1;
            end

            if snrFCUx == minSnr
                countWorstNoiseFCUx = countBestNoiseFCUx+1;
                scoreFCUx = scoreFCUx-1;
            elseif snrFCUy == minSnr
                countWorstNoiseFCUy = countBestNoiseFCUy+1;
                scoreFCUy = scoreFCUy-1;
            elseif snrFCUz == minSnr
                countWorstNoiseFCUz = countBestNoiseFCUz+1;
                scoreFCUz = scoreFCUz-1;
            end

            if snrFCRx == minSnr
                countWorstNoiseFCRx = countBestNoiseFCRx+1;
                scoreFCRx = scoreFCRx-1;
            elseif snrFCRy == minSnr
                countWorstNoiseFCRy = countBestNoiseFCRy+1;
                scoreFCRy = scoreFCRy-1;
            elseif snrFCRz == minSnr
                countWorstNoiseFCRz = countBestNoiseFCRz+1;
                scoreFCRz = scoreFCRz-1;
            end


            % if snrECU > snrFCU && snrFCU > snrFCR
            %     countBestNoiseECU = countBestNoiseECU+1;
            %     countWorstNoiseFCR = countWorstNoiseFCR+1;
            %     scoreECU = scoreECU+1;
            %     scoreFCR = scoreFCR-1;
            % elseif snrECU > snrFCR && snrFCR > snrFCU
            %     countBestNoiseECU = countBestNoiseECU+1;
            %     countWorstNoiseFCU = countWorstNoiseFCU+1;
            %     scoreECU = scoreECU+1;
            %     scoreFCU = scoreFCU-1;
            % elseif snrFCU > snrECU && snrECU > snrFCR
            %     countBestNoiseFCU = countBestNoiseFCU+1;
            %     countWorstNoiseFCR = countWorstNoiseFCR+1;
            %     scoreFCU = scoreFCU+1;
            %     scoreFCR = scoreFCR-1;
            % elseif snrFCU > snrFCR && snrFCR > snrECU
            %     countBestNoiseFCU = countBestNoiseFCU+1;
            %     countWorstNoiseECU = countWorstNoiseECU+1;
            %     scoreFCU = scoreFCU+1;
            %     scoreECU = scoreECU-1;
            % elseif snrFCR > snrECU && snrECU > snrFCU
            %     countBestNoiseFCR = countBestNoiseFCR+1;
            %     countWorstNoiseFCU = countWorstNoiseFCU+1;
            %     scoreFCR = scoreFCR+1;
            %     scoreFCU = scoreFCU-1;
            % else
            %     countBestNoiseFCR = countBestNoiseFCR+1;
            %     countWorstNoiseECU = countWorstNoiseECU+1;
            %     scoreFCR = scoreFCR+1;
            %     scoreECU = scoreECU-1;
            % end

        end
    end
end

Signal = ["ECUx";"ECUy";"ECUz";"FCUx";"FCUy";"FCUz";"FCRx";"FCRy";"FCRz"];
Scores = [scoreECUx;scoreECUy;scoreECUz;scoreFCUx;scoreFCUy;scoreFCUz;scoreFCRx;scoreFCRy;scoreFCRz];
% NumberWorstNoise = [countWorstNoiseECU;countWorstNoiseFCU;countWorstNoiseFCR];
% NumberBestNoise = [countBestNoiseECU;countBestNoiseFCU;countBestNoiseFCR];
% scoreboard = table(Signal,Scores,NumberWorstNoise,NumberBestNoise)
scoreboard = table(Signal,Scores)