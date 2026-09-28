% detect reach movements. Do not assign a direction to them. use the signal
% selected by selectRepresentativeSignal. This will be passed to this
% function from runReachOrientation Analysis.

clear
clc

%% load database -- this section will be removed when i convert the script into a function
sPathSource = "G:\Shared drives\LABS-DATASETS\DATASET_REACH_ORIENTATION";
dbox        = databox();
dbox.loadMeta(sPathSource);
%%

% uncomment the below when converting to function
% function [events] = detectReachMovements(dboxIn,...
% idSignalEventIn,sScriptIn,sTableIn,sTrialTypeListIn,sSignalIn,nSignalIn,sTrialTypeListIn)
% 
% dbox        = dboxIn;


idSubject       = [1]; % when it's finished it will run for all subjects, but while i'm writing it i'm doing 1 subject at a time [1,4,6:9];
idSignalEvent   = 57; % idSignalEventIn;
sScript         = 'nData = butterfilt(nData,nRate,6,''nOrder'',2);'; %sScriptIn;
sTable          = 'accraw'; % sTableIn;
idSignal        = [57]; % nSignalIn;
sSignal         = {'ECU_X'}; % sSignalIn;
sTrialTypeList  = {'UP_HF','UP_HS','SIDE_HF','SIDE_HS','SIDE_VF','SIDE_VS','UP_VF','UP_VS'}; % sTrialTypeListIn

events = [];

nRate = dbox.getMeta('metaSignal',{'sTable',sTable,...
    'sSignal',sSignal},'nRate');

for sub = idSubject
    for iTrialType = 1:numel(sTrialTypeList)
        idTrialList = dbox.getMeta('metaTrial',{'idSubject',sub,...
            'sTrialType',sTrialTypeList{iTrialType},'bTrial',1},'idTrial'); % read trials for a given subject
        if ~isempty(idTrialList)
            for idTrial = idTrialList

                idTrialType = dbox.getMeta('metaTrial',{'idTrial',idTrial},'idTrialType'); % read the movement type

                % Get data using passed selected signal
                nData      = dbox.getSignal(idSignal,idTrial,'sScript',sScript);

                nBeat = dbox.getMeta('metaTrialType',{'idTrialType',idTrialType},'nBeat');
                tBeat = 60/nBeat;

                x = 0:1:numel(nData)-1;
                t = x/nRate;


                % set up arrays to detect the first burst
                tStart = dbox.getEvent(idTrial,57,'on',1); % basic start/stop times were stored on signal 57
                nStart = round(tStart*nRate);
                tStop  = dbox.getEvent(idTrial,57,'off',1); % basic start/stop times were stored on signal 57
                nStop  = round(tStop*nRate);
                dataVals = nData(nStart:nStop);
                tVals = t(nStart:nStop);

                lowPassData = butterfilt(nData,nRate,nBeat/60,'nOrder',2,'sType','low');

                % get the max and mins of the filtered data
                bMax = islocalmax(lowPassData);
                bMin = islocalmin(lowPassData);

                peaks   = zeros(length(bMax),1);
                valleys = zeros(length(bMin),1);

                for i = 1:numel(lowPassData)
                    if bMax(i)
                        peaks(i) = i;
                    end
                    if bMin(i)
                        valleys(i) = i;
                    end
                end

                peaks   = nonzeros(peaks);
                valleys = nonzeros(valleys);


            end
        end
    end
end

% end
