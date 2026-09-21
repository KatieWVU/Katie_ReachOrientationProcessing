% determines the best sensor (FCR/FCU/ECU) to determine movement
% onset/offset times from.

% Scores FCR, FCU, and ECU for signal to noise ratio, cadence peak, and
% compatibility with nBeat

function [hSignal,vSignal,shSignal,svSignal] = selectRepresentativeSensor(dboxIn,idSubjectIn,idSignalEventIn,sScriptIn,sTableIn,sSignalListIn,sSignalListFCUIn,sSignalListFCRIn,sTrialTypeListIn)

dbox        = dboxIn;

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

% initialize cadence scores to zero
cadECUx = 0;
cadECUy = 0;
cadECUz = 0;

cadFCUx = 0;
cadFCUy = 0;
cadFCUz = 0;

cadFCRx = 0;
cadFCRy = 0;
cadFCRz = 0;


% initialize the variables to hold the selected signal choices
hSignal = 0;
vSignal = 0;
shSignal = '';
svSignal = '';


% pull trial data (this is given as input to the function, but I am leaving
% the way it would be called if not a function in comments at the end of
% each line)
idSubject      = idSubjectIn; %[1];
idSignalEvent   = idSignalEventIn; % 57;
sScript         = sScriptIn; % 'nData = butterfilt(nData,nRate,6,''nOrder'',2);';
sTable          = sTableIn; % 'accraw';
sSignalList     = sSignalListIn; % {'ECU_X','ECU_Y','ECU_Z'};
sSignalListFCU  = sSignalListFCUIn; % {'FCU_X','FCU_Y','FCU_Z'};
sSignalListFCR  = sSignalListFCRIn; % {'FCR_X','FCR_Y','FCR_Z'};
sTrialTypeList  = sTrialTypeListIn; % {'UP_HF','UP_HS','SIDE_HF','SIDE_HS','SIDE_VF','SIDE_VS','UP_VF','UP_VS'};


idSignalListECU = dbox.getMeta('metaSignal',{'sTable',sTable,...
    'sSignal',sSignalList},'idSignal');
idSignalListFCU = dbox.getMeta('metaSignal',{'sTable',sTable,...
    'sSignal',sSignalListFCU},'idSignal');
idSignalListFCR = dbox.getMeta('metaSignal',{'sTable',sTable,...
    'sSignal',sSignalListFCR},'idSignal');
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
            nDataFCU      = dbox.getSignal(idSignalListFCU(1),idTrial,'sScript',sScript);
            nDataFCU(2,:) = dbox.getSignal(idSignalListFCU(2),idTrial,'sScript',sScript);
            nDataFCU(3,:) = dbox.getSignal(idSignalListFCU(3),idTrial,'sScript',sScript);

            % grab FCR Data
            nDataFCR      = dbox.getSignal(idSignalListFCR(1),idTrial,'sScript',sScript);
            nDataFCR(2,:) = dbox.getSignal(idSignalListFCR(2),idTrial,'sScript',sScript);
            nDataFCR(3,:) = dbox.getSignal(idSignalListFCR(3),idTrial,'sScript',sScript);

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

            % assign points according to snr: add one point for the best 
            % snr, lose one point for the worst snr
            if snrECUx == maxSnr
                scoreECUx = scoreECUx+1;
            elseif snrECUy == maxSnr
                scoreECUy = scoreECUy+1;
            elseif snrECUz == maxSnr
                scoreECUz = scoreECUz+1;
            elseif snrFCUx == maxSnr
                scoreFCUx = scoreFCUx+1;
            elseif snrFCUy == maxSnr
                scoreFCUy = scoreFCUy+1;
            elseif snrFCUz == maxSnr
                scoreFCUz = scoreFCUz+1;
            elseif snrFCRx == maxSnr
                scoreFCRx = scoreFCRx+1;
            elseif snrFCRy == maxSnr
                scoreFCRy = scoreFCRy+1;
            elseif snrFCRz == maxSnr
                scoreFCRz = scoreFCRz+1;
            end


            if snrECUx == minSnr
                scoreECUx = scoreECUx-1;
            elseif snrECUy == minSnr
                scoreECUy = scoreECUy-1;
            elseif snrECUz == minSnr
                scoreECUz = scoreECUz-1;
            elseif snrFCUx == minSnr
                scoreFCUx = scoreFCUx-1;
            elseif snrFCUy == minSnr
                scoreFCUy = scoreFCUy-1;
            elseif snrFCUz == minSnr
                scoreFCUz = scoreFCUz-1;
            elseif snrFCRx == minSnr
                scoreFCRx = scoreFCRx-1;
            elseif snrFCRy == minSnr
                scoreFCRy = scoreFCRy-1;
            elseif snrFCRz == minSnr
                scoreFCRz = scoreFCRz-1;
            end


       % determine which signals have the greatest and least
            % differences between peaks and valleys. This will be used to
            % determine which axes are better for vertical vs horizontal
            % movements

            % Because I only want to get the peaks and valleys for data
            % were movement was occurring, this requires I pull approximate
            % start and stop points for motion
            tStart = dbox.getEvent(idTrial,idSignalEvent,'on',1);
            tStop  = dbox.getEvent(idTrial,idSignalEvent,'off',1);

            nStart = round(tStart*nRate);
            nStop = round(tStop*nRate);

            % initialize peak and valley arrays to zeros
            ECUxpeaks = zeros(nStop-nStart,1);
            ECUypeaks = zeros(nStop-nStart,1);
            ECUzpeaks = zeros(nStop-nStart,1);

            FCUxpeaks = zeros(nStop-nStart,1);
            FCUypeaks = zeros(nStop-nStart,1);
            FCUzpeaks = zeros(nStop-nStart,1);

            FCRxpeaks = zeros(nStop-nStart,1);
            FCRypeaks = zeros(nStop-nStart,1);
            FCRzpeaks = zeros(nStop-nStart,1);

            ECUxvalleys = zeros(nStop-nStart,1);
            ECUyvalleys = zeros(nStop-nStart,1);
            ECUzvalleys = zeros(nStop-nStart,1);

            FCUxvalleys = zeros(nStop-nStart,1);
            FCUyvalleys = zeros(nStop-nStart,1);
            FCUzvalleys = zeros(nStop-nStart,1);

            FCRxvalleys = zeros(nStop-nStart,1);
            FCRyvalleys = zeros(nStop-nStart,1);
            FCRzvalleys = zeros(nStop-nStart,1);

            % Get the indices of peaks and valleys.
            % the arrays below will be used for calculating cadence, not
            % peak distance
            ECUxpeaksi = zeros(nStop-nStart,1);
            ECUypeaksi = zeros(nStop-nStart,1);
            ECUzpeaksi = zeros(nStop-nStart,1);

            FCUxpeaksi = zeros(nStop-nStart,1);
            FCUypeaksi = zeros(nStop-nStart,1);
            FCUzpeaksi = zeros(nStop-nStart,1);

            FCRxpeaksi = zeros(nStop-nStart,1);
            FCRypeaksi = zeros(nStop-nStart,1);
            FCRzpeaksi = zeros(nStop-nStart,1);

            ECUxvalleysi = zeros(nStop-nStart,1);
            ECUyvalleysi = zeros(nStop-nStart,1);
            ECUzvalleysi = zeros(nStop-nStart,1);

            FCUxvalleysi = zeros(nStop-nStart,1);
            FCUyvalleysi = zeros(nStop-nStart,1);
            FCUzvalleysi = zeros(nStop-nStart,1);

            FCRxvalleysi = zeros(nStop-nStart,1);
            FCRyvalleysi = zeros(nStop-nStart,1);
            FCRzvalleysi = zeros(nStop-nStart,1);


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
                    ECUxpeaksi(i) = i;
                end
                if maxesECUy(i)
                    ECUypeaks(i) = lowPassECUy(i);
                    ECUypeaksi(i) = i;
                end
                if maxesECUz(i)
                    ECUzpeaks(i) = lowPassECUz(i);
                    ECUzpeaksi(i) = i;
                end
                if maxesFCUx(i)
                    FCUxpeaks(i) = lowPassFCUx(i);
                    FCUxpeaksi(i) = i;
                end
                if maxesFCUy(i)
                    FCUypeaks(i) = lowPassFCUy(i);
                    FCUypeaksi(i) = i;
                end
                if maxesFCUz(i)
                    FCUzpeaks(i) = lowPassFCUz(i);
                    FCUzpeaksi(i) = i;
                end
                if maxesFCRx(i)
                    FCRxpeaks(i) = lowPassFCRx(i);
                    FCRxpeaksi(i) = i;
                end
                if maxesFCRy(i)
                    FCRypeaks(i) = lowPassFCRy(i);
                    FCRypeaksi(i) = i;
                end
                if maxesFCRz(i)
                    FCRzpeaks(i) = lowPassFCRz(i);
                    FCRzpeaksi(i) = i;
                end

                if minsECUx(i)
                    ECUxvalleys(i) = lowPassECUx(i);
                    ECUxvalleysi(i) = i;
                end
                if minsECUy(i)
                    ECUyvalleys(i) = lowPassECUy(i);
                    ECUyvalleysi(i) = i;
                end
                if minsECUz(i)
                    ECUzvalleys(i) = lowPassECUz(i);
                    ECUzvalleysi(i) = i;
                end
                if minsFCUx(i)
                    FCUxvalleys(i) = lowPassFCUx(i);
                    FCUxvalleysi(i) = i;
                end
                if minsFCUy(i)
                    FCUyvalleys(i) = lowPassFCUy(i);
                    FCUyvalleysi(i) = i;
                end
                if minsFCUz(i)
                    FCUzvalleys(i) = lowPassFCUz(i);
                    FCUzvalleysi(i) = i;
                end
                if minsFCRx(i)
                    FCRxvalleys(i) = lowPassFCRx(i);
                    FCRxvalleysi(i) = i;
                end
                if minsFCRy(i)
                    FCRyvalleys(i) = lowPassFCRy(i);
                    FCRyvalleysi(i) = i;
                end
                if minsFCRz(i)
                    FCRzvalleys(i) = lowPassFCRz(i);
                    FCRzvalleysi(i) = i;
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
            FCRyvalleys = nonzeros(FCRyvalleys);
            FCRzvalleys = nonzeros(FCRzvalleys);

            % get rid of any indices that are zero
            ECUxpeaksi = nonzeros(ECUxpeaksi);
            ECUypeaksi = nonzeros(ECUypeaksi);
            ECUzpeaksi = nonzeros(ECUzpeaksi);

            FCUxpeaksi = nonzeros(FCUxpeaksi);
            FCUypeaksi = nonzeros(FCUypeaksi);
            FCUzpeaksi = nonzeros(FCUzpeaksi);

            FCRxpeaksi = nonzeros(FCRxpeaksi);
            FCRypeaksi = nonzeros(FCRypeaksi);
            FCRzpeaksi = nonzeros(FCRzpeaksi);

            ECUxvalleysi = nonzeros(ECUxvalleysi);
            ECUyvalleysi = nonzeros(ECUyvalleysi);
            ECUzvalleysi = nonzeros(ECUzvalleysi);

            FCUxvalleysi = nonzeros(FCUxvalleysi);
            FCUyvalleysi = nonzeros(FCUyvalleysi);
            FCUzvalleysi = nonzeros(FCUzvalleysi);

            FCRxvalleysi = nonzeros(FCRxvalleysi);
            FCRyvalleysi = nonzeros(FCRyvalleysi);
            FCRzvalleysi = nonzeros(FCRzvalleysi);

            % get the average peak and valley values
            diffECUx = [];
            diffECUy = [];
            diffECUz = [];

            diffFCUx = [];
            diffFCUy = [];
            diffFCUz = [];

            diffFCRx = [];
            diffFCRy = [];
            diffFCRz = [];

            for i = 1:min(length(ECUxpeaks),length(ECUxvalleys))
                diffECUx(i) = ECUxpeaks(i)-ECUxvalleys(i);
            end
            for i = 1:min(length(ECUypeaks),length(ECUyvalleys))
                diffECUy(i) = ECUypeaks(i)-ECUyvalleys(i);
            end
            for i = 1:min(length(ECUzpeaks),length(ECUzvalleys))
                diffECUz(i) = ECUzpeaks(i)-ECUzvalleys(i);
            end

            for i = 1:min(length(FCUxpeaks),length(FCUxvalleys))
                diffFCUx(i) = FCUxpeaks(i)-FCUxvalleys(i);
            end
            for i = 1:min(length(FCUypeaks),length(FCUyvalleys))
                diffFCUy(i) = FCUypeaks(i)-FCUyvalleys(i);
            end
            for i = 1:min(length(FCUzpeaks),length(FCUzvalleys))
                diffFCUz(i) = FCUzpeaks(i)-FCUzvalleys(i);
            end

            for i = 1:min(length(FCRxpeaks),length(FCRxvalleys))
                diffFCRx(i) = FCRxpeaks(i)-FCRxvalleys(i);
            end
            for i = 1:min(length(FCRypeaks),length(FCRyvalleys))
                diffFCRy(i) = FCRypeaks(i)-FCRyvalleys(i);
            end
            for i = 1:min(length(FCRzpeaks),length(FCRzvalleys))
                diffFCRz(i) = FCRzpeaks(i)-FCRzvalleys(i);
            end
            
            diffECUxAve = abs(mean(diffECUx));
            diffECUyAve = abs(mean(diffECUy));
            diffECUzAve = abs(mean(diffECUz));

            diffFCUxAve = abs(mean(diffFCUx));
            diffFCUyAve = abs(mean(diffFCUy));
            diffFCUzAve = abs(mean(diffFCUz));

            diffFCRxAve = abs(mean(diffFCRx));
            diffFCRyAve = abs(mean(diffFCRy));
            diffFCRzAve = abs(mean(diffFCRz));
            

            % grab the maximum and minimum differences
            maxDiff = max([diffECUxAve,diffECUyAve,diffECUzAve,diffFCUxAve,diffFCUyAve, ...
                diffFCUzAve,diffFCRxAve,diffFCRyAve,diffFCRzAve]);
            minDiff = min([diffECUxAve,diffECUyAve,diffECUzAve,diffFCUxAve,diffFCUyAve, ...
                diffFCUzAve,diffFCRxAve,diffFCRyAve,diffFCRzAve]);


            % assign points based on max/min differences
            % the best options may differ according to horizontal and
            % vertical movements, so assignments are divided along those
            % lines
            % Bigger differences should make analysis easier, so get +1
            if ismember(idTrialType,[7:10])
                if maxDiff == diffECUxAve
                    hECUx = hECUx+1;
                elseif minDiff == diffECUxAve
                    hECUx = hECUx-1;
                end
                if maxDiff == diffECUyAve
                    hECUy = hECUy+1;
                elseif minDiff == diffECUyAve
                    hECUy = hECUy-1;
                end
                if maxDiff == diffECUzAve
                    hECUz = hECUz+1;
                elseif minDiff == diffECUzAve
                    hECUz = hECUz-1;
                end

                if maxDiff == diffFCUxAve
                    hFCUx = hFCUx+1;
                elseif minDiff == diffFCUxAve
                    hFCUx = hFCUx-1;
                end
                if maxDiff == diffFCUyAve
                    hFCUy = hFCUy+1;
                elseif minDiff == diffFCUyAve
                    hFCUy = hFCUy-1;
                end
                if maxDiff == diffFCUzAve
                    hFCUz = hFCUz+1;
                elseif minDiff == diffFCUzAve
                    hFCUz = hFCUz-1;
                end

                if maxDiff == diffFCRxAve
                    hFCRx = hFCRx+1;
                elseif minDiff == diffFCRxAve
                    hFCRx = hFCRx-1;
                end
                if maxDiff == diffFCUyAve
                    hFCRy = hFCRy+1;
                elseif minDiff == diffFCRyAve
                    hFCRy = hFCRy-1;
                end
                if maxDiff == diffFCRzAve
                    hFCRz = hFCRz+1;
                elseif minDiff == diffFCRzAve
                    hFCRz = hFCRz-1;
                end
            else
                if maxDiff == diffECUxAve
                    vECUx = vECUx+1;
                elseif minDiff == diffECUxAve
                    vECUx = vECUx-1;
                end
                if maxDiff == diffECUyAve
                    vECUy = vECUy+1;
                elseif minDiff == diffECUyAve
                    vECUy = vECUy-1;
                end
                if maxDiff == diffECUzAve
                    vECUz = vECUz+1;
                elseif minDiff == diffECUzAve
                    vECUz = vECUz-1;
                end

                if maxDiff == diffFCUxAve
                    vFCUx = vFCUx+1;
                elseif minDiff == diffFCUxAve
                    vFCUx = vFCUx-1;
                end
                if maxDiff == diffFCUyAve
                    vFCUy = vFCUy+1;
                elseif minDiff == diffFCUyAve
                    vFCUy = vFCUy-1;
                end
                if maxDiff == diffFCUzAve
                    vFCUz = vFCUz+1;
                elseif minDiff == diffFCUzAve
                    vFCUz = vFCUz-1;
                end

                if maxDiff == diffFCRxAve
                    vFCRx = vFCRx+1;
                elseif minDiff == diffFCRxAve
                    vFCRx = vFCRx-1;
                end
                if maxDiff == diffFCUyAve
                    vFCRy = vFCRy+1;
                elseif minDiff == diffFCRyAve
                    vFCRy = vFCRy-1;
                end
                if maxDiff == diffFCRzAve
                    vFCRz = vFCRz+1;
                elseif minDiff == diffFCRzAve
                    vFCRz = vFCRz-1;
                end
            end


            % check that the cadence approximates nBeat

            tBeat = 60/nBeat;

            % grab starting indices
            indECUx = min(ECUxpeaksi(1),ECUxvalleysi(1));
            indECUy = min(ECUypeaksi(1),ECUyvalleysi(1));
            indECUz = min(ECUzpeaksi(1),ECUzvalleysi(1));

            indFCUx = min(FCUxpeaksi(1),FCUxvalleysi(1));
            indFCUy = min(FCUypeaksi(1),FCUyvalleysi(1));
            indFCUz = min(FCUzpeaksi(1),FCUzvalleysi(1));

            indFCRx = min(FCRxpeaksi(1),FCRxvalleysi(1));
            indFCRy = min(FCRypeaksi(1),FCRyvalleysi(1));
            indFCRz = min(FCRzpeaksi(1),FCRzvalleysi(1));

            % create arrays of differences between where the beat is and
            % where the beat should be

            diffiECUx = zeros(max(length(ECUxpeaks),length(ECUxvalleys)),1);
            diffiECUy = zeros(max(length(ECUypeaks),length(ECUyvalleys)),1);
            diffiECUz = zeros(max(length(ECUzpeaks),length(ECUzvalleys)),1);

            diffiFCUx = zeros(max(length(FCUxpeaks),length(FCUxvalleys)),1);
            diffiFCUy = zeros(max(length(FCUypeaks),length(FCUyvalleys)),1);
            diffiFCUz = zeros(max(length(FCUzpeaks),length(FCUzvalleys)),1);

            diffiFCRx = zeros(max(length(FCRxpeaks),length(FCRxvalleys)),1);
            diffiFCRy = zeros(max(length(FCRypeaks),length(FCRyvalleys)),1);
            diffiFCRz = zeros(max(length(FCRzpeaks),length(FCRzvalleys)),1);


            step = round(tBeat*nRate);

            if indECUx == ECUxpeaksi(1)
                i = 1;
                while i < length(ECUxpeaksi)-1
                    diffiECUx(i) = (indECUx + step)-ECUxpeaksi(i+1);
                    indECUx = ECUxpeaksi(i+1);
                    i = i+1;
                end
            elseif indECUx == ECUxvalleysi(1)
                i = 1;
                while i < length(ECUxvalleysi)-1
                    diffiECUx(i) = (indECUx + step)-ECUxvalleysi(i+1);
                    indECUx = ECUxvalleysi(i+1);
                    i = i+1;
                end
            end
            if indECUy == ECUypeaksi(1)
                i = 1;
                while i < length(ECUypeaksi)-1
                    diffiECUy(i) = (indECUy + step)-ECUypeaksi(i+1);
                    indECUy = ECUypeaksi(i+1);
                    i = i+1;
                end
            elseif indECUy == ECUyvalleysi(1)
                i = 1;
                while i < length(ECUyvalleysi)-1
                    diffiECUy(i) = (indECUy + step)-ECUyvalleysi(i+1);
                    indECUy = ECUyvalleysi(i+1);
                    i = i+1;
                end
            end
            if indECUz == ECUzpeaksi(1)
                i = 1;
                while i < length(ECUzpeaksi)-1
                    diffiECUz(i) = (indECUz + step)-ECUzpeaksi(i+1);
                    indECUz = ECUzpeaksi(i+1);
                    i = i+1;
                end
            elseif indECUz == ECUzvalleysi(1)
                i = 1;
                while i < length(ECUzvalleysi)-1
                    diffiECUz(i) = (indECUz + step)-ECUzvalleysi(i+1);
                    indECUz = ECUzvalleysi(i+1);
                    i = i+1;
                end
            end

            if indFCUx == FCUxpeaksi(1)
                i = 1;
                while i < length(FCUxpeaksi)-1
                    diffiFCUx(i) = (indFCUx + step)-FCUxpeaksi(i+1);
                    indFCUx = FCUxpeaksi(i+1);
                    i = i+1;
                end
            elseif indFCUx == FCUxvalleysi(1)
                i = 1;
                while i < length(FCUxvalleysi)-1
                    diffiFCUx(i) = (indFCUx + step)-FCUxvalleysi(i+1);
                    indFCUx = FCUxvalleysi(i+1);
                    i = i+1;
                end
            end
            if indFCUy == FCUypeaksi(1)
                i = 1;
                while i < length(FCUypeaksi)-1
                    diffiFCUy(i) = (indFCUy + step)-FCUypeaksi(i+1);
                    indFCUy = FCUypeaksi(i+1);
                    i = i+1;
                end
            elseif indFCUy == FCUyvalleysi(1)
                i = 1;
                while i < length(FCUyvalleysi)-1
                    diffiFCUy(i) = (indFCUy + step)-FCUyvalleysi(i+1);
                    indFCUy = FCUyvalleysi(i+1);
                    i = i+1;
                end
            end
            if indFCUz == FCUzpeaksi(1)
                i = 1;
                while i < length(FCUzpeaksi)-1
                    diffiFCUz(i) = (indFCUz + step)-FCUzpeaksi(i+1);
                    indFCUz = FCUzpeaksi(i+1);
                    i = i+1;
                end
            elseif indFCUz == FCUzvalleysi(1)
                i = 1;
                while i < length(FCUzvalleysi)-1
                    diffiFCUz(i) = (indFCUz + step)-FCUzvalleysi(i+1);
                    indFCUz = FCUzvalleysi(i+1);
                    i = i+1;
                end
            end

            if indFCRx == FCRxpeaksi(1)
                i = 1;
                while i < length(FCRxpeaksi)-1
                    diffiFCRx(i) = (indFCRx + step)-FCRxpeaksi(i+1);
                    indFCRx = FCRxpeaksi(i+1);
                    i = i+1;
                end
            elseif indFCRx == FCRxvalleysi(1)
                i = 1;
                while i < length(FCRxvalleysi)-1
                    diffiFCRx(i) = (indFCRx + step)-FCRxvalleysi(i+1);
                    indFCRx = FCRxvalleysi(i+1);
                    i = i+1;
                end
            end
            if indFCRy == FCRypeaksi(1)
                i = 1;
                while i < length(FCRypeaksi)-1
                    diffiFCRy(i) = (indFCRy + step)-FCRypeaksi(i+1);
                    indFCRy = FCRypeaksi(i+1);
                    i = i+1;
                end
            elseif indFCRy == FCRyvalleysi(1)
                i = 1;
                while i < length(FCRyvalleysi)-1
                    diffiFCRy(i) = (indFCRy + step)-FCRyvalleysi(i+1);
                    indFCRy = FCRyvalleysi(i+1);
                    i = i+1;
                end
            end
            if indFCRz == FCRzpeaksi(1)
                i = 1;
                while i < length(FCRzpeaksi)-1
                    diffiFCRz(i) = (indFCRz + step)-FCRzpeaksi(i+1);
                    indFCRz = FCRzpeaksi(i+1);
                    i = i+1;
                end
            elseif indFCRz == FCRzvalleysi(1)
                i = 1;
                while i < length(FCRzvalleysi)-1
                    diffiFCRz(i) = (indFCRz + step)-FCRzvalleysi(i+1);
                    indFCRz = FCRzvalleysi(i+1);
                    i = i+1;
                end
            end

            %remove extra zeros
            diffiECUx = nonzeros(diffiECUx);
            diffiECUy = nonzeros(diffiECUy);
            diffiECUz = nonzeros(diffiECUz);

            diffiFCUx = nonzeros(diffiFCUx);
            diffiFCUy = nonzeros(diffiFCUy);
            diffiFCUz = nonzeros(diffiFCUz);

            diffiFCRx = nonzeros(diffiFCRx);
            diffiFCRy = nonzeros(diffiFCRy);
            diffiFCRz = nonzeros(diffiFCRz);

            % get the standard deviation of the difference values
            diffiECUxstd = std((diffiECUx));
            diffiECUystd = std((diffiECUy));
            diffiECUzstd = std((diffiECUz));

            diffiFCUxstd = std((diffiFCUx));
            diffiFCUystd = std((diffiFCUy));
            diffiFCUzstd = std((diffiFCUz));

            diffiFCRxstd = std((diffiFCRx));
            diffiFCRystd = std((diffiFCRy));
            diffiFCRzstd = std((diffiFCRz));

            % assign points based on standard deviation
            % gain a point for lowest std, lose a point for highest

            minstd = min([diffiECUxstd,diffiECUystd,diffiECUzstd,...
                diffiFCUxstd,diffiFCUystd,diffiFCUzstd,...
                diffiFCRxstd,diffiFCRystd,diffiFCRzstd]);
            maxstd = max([diffiECUxstd,diffiECUystd,diffiECUzstd,...
                diffiFCUxstd,diffiFCUystd,diffiFCUzstd,...
                diffiFCRxstd,diffiFCRystd,diffiFCRzstd]);

            if minstd == diffiECUxstd
                cadECUx = cadECUx + 1;
            elseif minstd == diffiECUystd
                cadECUy = cadECUy+1;
            elseif minstd == diffiECUzstd
                cadECUz = cadECUz+1;
            elseif minstd == diffiFCUxstd
                cadFCUx = cadFCUx + 1;
            elseif minstd == diffiFCUystd
                cadFCUy = cadFCUy+1;
            elseif minstd == diffiFCUzstd
                cadFCUz = cadFCUz+1;
            elseif minstd == diffiFCRxstd
                cadFCRx = cadFCRx + 1;
            elseif minstd == diffiFCRystd
                cadFCRy = cadFCRy+1;
            elseif minstd == diffiFCRzstd
                cadFCRz = cadFCRz+1;
            end


            if maxstd == diffiECUxstd
                cadECUx = cadECUx - 1;
            elseif maxstd == diffiECUystd
                cadECUy = cadECUy-1;
            elseif maxstd == diffiECUzstd
                cadECUz = cadECUz-1;
            elseif maxstd == diffiFCUxstd
                cadFCUx = cadFCUx - 1;
            elseif maxstd == diffiFCUystd
                cadFCUy = cadFCUy-1;
            elseif maxstd == diffiFCUzstd
                cadFCUz = cadFCUz-1;
            elseif maxstd == diffiFCRxstd
                cadFCRx = cadFCRx - 1;
            elseif maxstd == diffiFCRystd
                cadFCRy = cadFCRy-1;
            elseif maxstd == diffiFCRzstd
                cadFCRz = cadFCRz-1;
            end


        end
    end
end


% print out a table of score values for me to look at
Signal = ["ECU_X";"ECU_Y";"ECU_Z";"FCU_X";"FCU_Y";"FCU_Z";"FCR_X";"FCR_Y";"FCR_Z"];
Scores = [scoreECUx;scoreECUy;scoreECUz;scoreFCUx;scoreFCUy;scoreFCUz;scoreFCRx;scoreFCRy;scoreFCRz];
horizontalScores = [hECUx;hECUy;hECUz;hFCUx;hFCUy;hFCUz;hFCRx;hFCRy;hFCRz];
verticalScores = [vECUx;vECUy;vECUz;vFCUx;vFCUy;vFCUz;vFCRx;vFCRy;vFCRz];
CadenceScores = [cadECUx;cadECUy;cadECUz;cadFCUx;cadFCUy;cadFCUz;cadFCRx;cadFCRy;cadFCRz];
scoreboard = table(Signal,Scores,CadenceScores,horizontalScores,verticalScores);


% total up the scores

htotalECUx = scoreECUx+hECUx+cadECUx;
htotalECUy = scoreECUy+hECUy+cadECUy;
htotalECUz = scoreECUz+hECUz+cadECUz;

htotalFCUx = scoreFCUx+hFCUx+cadFCUx;
htotalFCUy = scoreFCUy+hFCUy+cadFCUy;
htotalFCUz = scoreFCUz+hFCUz+cadFCUz;

htotalFCRx = scoreFCRx+hFCRx+cadFCRx;
htotalFCRy = scoreFCRy+hFCRy+cadFCRy;
htotalFCRz = scoreFCRz+hFCRz+cadFCRz;

vtotalECUx = scoreECUx+vECUx+cadECUx;
vtotalECUy = scoreECUy+vECUy+cadECUy;
vtotalECUz = scoreECUz+vECUz+cadECUz;

vtotalFCUx = scoreFCUx+vFCUx+cadFCUx;
vtotalFCUy = scoreFCUy+vFCUy+cadFCUy;
vtotalFCUz = scoreFCUz+vFCUz+cadFCUz;

vtotalFCRx = scoreFCRx+vFCRx+cadFCRx;
vtotalFCRy = scoreFCRy+vFCRy+cadFCRy;
vtotalFCRz = scoreFCRz+vFCRz+cadFCRz;


% if any individual score value is negative, remove that signal as an
% option
if scoreECUx < 0
    htotalECUx = htotalECUx - 1000;
    vtotalECUx = vtotalECUx -1000;
end
if scoreECUy < 0
    htotalECUy = htotalECUy - 1000;
    vtotalECUy = vtotalECUy -1000;
end
if scoreECUz < 0
    htotalECUz = htotalECUz - 1000;
    vtotalECUz = vtotalECUz -1000;
end

if scoreFCUx < 0
    htotalFCUx = htotalFCUx - 1000;
    vtotalFCUx = vtotalFCUx -1000;
end
if scoreFCUy < 0
    htotalFCUy = htotalFCUy - 1000;
    vtotalFCUy = vtotalFCUy -1000;
end
if scoreFCUz < 0
    htotalFCUz = htotalFCUz - 1000;
    vtotalFCUz = vtotalFCUz -1000;
end

if scoreFCRx < 0
    htotalFCRx = htotalFCRx - 1000;
    vtotalFCRx = vtotalFCRx -1000;
end
if scoreFCRy < 0
    htotalFCRy = htotalFCRy - 1000;
    vtotalFCRy = vtotalFCRy -1000;
end
if scoreFCRz < 0
    htotalFCRz = htotalFCRz - 1000;
    vtotalFCRz = vtotalFCRz -1000;
end



if cadECUx < 0
    htotalECUx = htotalECUx - 1000;
    vtotalECUx = vtotalECUx -1000;
end
if cadECUy < 0
    htotalECUy = htotalECUy - 1000;
    vtotalECUy = vtotalECUy -1000;
end
if cadECUz < 0
    htotalECUz = htotalECUz - 1000;
    vtotalECUz = vtotalECUz -1000;
end

if cadFCUx < 0
    htotalFCUx = htotalFCUx - 1000;
    vtotalFCUx = vtotalFCUx -1000;
end
if cadFCUy < 0
    htotalFCUy = htotalFCUy - 1000;
    vtotalFCUy = vtotalFCUy -1000;
end
if cadFCUz < 0
    htotalFCUz = htotalFCUz - 1000;
    vtotalFCUz = vtotalFCUz -1000;
end

if cadFCRx < 0
    htotalFCRx = htotalFCRx - 1000;
    vtotalFCRx = vtotalFCRx -1000;
end
if cadFCRy < 0
    htotalFCRy = htotalFCRy - 1000;
    vtotalFCRy = vtotalFCRy -1000;
end
if cadFCRz < 0
    htotalFCRz = htotalFCRz - 1000;
    vtotalFCRz = vtotalFCRz -1000;
end



if hECUx < 0
    htotalECUx = htotalECUx - 1000;
end
if hECUy < 0
    htotalECUy = htotalECUy - 1000;
end
if hECUz < 0
    htotalECUz = htotalECUz - 1000;
end

if hFCUx < 0
    htotalFCUx = htotalFCUx - 1000;
end
if hFCUy < 0
    htotalFCUy = htotalFCUy - 1000;
end
if hFCUz < 0
    htotalFCUz = htotalFCUz - 1000;
end

if hFCRx < 0
    htotalFCRx = htotalFCRx - 1000;
end
if hFCRy < 0
    htotalFCRy = htotalFCRy - 1000;
end
if hFCRz < 0
    htotalFCRz = htotalFCRz - 1000;
end



if vECUx < 0
    vtotalECUx = vtotalECUx - 1000;
end
if vECUy < 0
    vtotalECUy = vtotalECUy - 1000;
end
if vECUz < 0
    vtotalECUz = vtotalECUz - 1000;
end

if vFCUx < 0
    vtotalFCUx = vtotalFCUx - 1000;
end
if vFCUy < 0
    vtotalFCUy = vtotalFCUy - 1000;
end
if vFCUz < 0
    vtotalFCUz = vtotalFCUz - 1000;
end

if vFCRx < 0
    vtotalFCRx = vtotalFCRx - 1000;
end
if vFCRy < 0
    vtotalFCRy = vtotalFCRy - 1000;
end
if vFCRz < 0
    vtotalFCRz = vtotalFCRz - 1000;
end


% Updated score totals
htotals = [htotalECUx,htotalECUy,htotalECUz,htotalFCUx,htotalFCUy,htotalFCUz,...
    htotalFCRx,htotalFCRy,htotalFCRz]';
vtotals = [vtotalECUx,vtotalECUy,vtotalECUz,vtotalFCUx,vtotalFCUy,vtotalFCUz,...
    vtotalFCRx,vtotalFCRy,vtotalFCRz]';

finalScores = table(Signal,htotals,vtotals);

% assign the best signals to the variables hSignal and vSignal

maxhtotal = max(htotals);
maxvtotal = max(vtotals);
signalVals = [57,58,59,44,45,46,47,48,49];

for i = 1:length(signalVals)
    if htotals(i) == maxhtotal
        hSignal = signalVals(i);
        shSignal = Signal(i);
        % disp(["hSignal: ",Signal(i)]);
    end
    if vtotals(i) == maxvtotal
        vSignal = signalVals(i);
        svSignal = Signal(i);
        % disp(["vSignal: ",Signal(i)]);
    end
end
end