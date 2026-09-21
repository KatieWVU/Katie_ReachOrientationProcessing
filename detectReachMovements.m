% detect reach movements. Do not assign a direction to them. use the signal
% selected by selectRepresentativeSignal (this will be passed to this
% function from runReachOrientation Analysis).

clear
clc

%% load database -- this section will be removed when i convert the script into a function
sPathSource = "G:\Shared drives\LABS-DATASETS\DATASET_REACH_ORIENTATION";
dbox        = databox();
dbox.loadMeta(sPathSource);
%%

% uncomment the below when converting to function
% function [hTrials,vTrials] = detectReachMovements(dboxIn,idSubjectIn,...
% idSignalEventIn,sScriptIn,sTableIn,sTrialTypeListIn,sSignalIn,nSignalIn,sTrialTypeListIn)
% 
% dbox        = dboxIn;


idSubject       = [1]; % idSubjectIn;
idSignalEvent   = 57; % idSignalEventIn;
sScript         = 'nData = butterfilt(nData,nRate,6,''nOrder'',2);'; %sScriptIn;
sTable          = 'accraw'; % sTableIn;
idSignal        = [57]; % nSignalIn;
sSignal         = {'ECU_X'}; % sSignalIn;
sTrialTypeList  = {'UP_HF','UP_HS','SIDE_HF','SIDE_HS','SIDE_VF','SIDE_VS','UP_VF','UP_VS'}; % sTrialTypeListIn


nRate = dbox.getMeta('metaSignal',{'sTable',sTable,...
    'sSignal',sSignal},'nRate');

for iTrialType = 1:numel(sTrialTypeList)
    idTrialList = dbox.getMeta('metaTrial',{'idSubject',idSubject,...
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

            % get bursts
            minBurst = tBeat/4;
            [tBursts,idType,out] = getBurst(tVals,dataVals,'bPlot',1,...
                'bManualThr',0,'Tbmin',minBurst,'T0min',.001,'bVerbose',1);


        end
    end
end


% end
