

clear
clc

%% load database
sPathSource = "G:\Shared drives\LABS-DATASETS\DATASET_REACH_ORIENTATION";
dbox        = databox();
dbox.loadMeta(sPathSource);
%%
idSubject       = [1];
idSignalEvent   = 57;
sScript         = 'nData = butterfilt(nData,nRate,6,''nOrder'',2);';
sTable          = 'accraw';
sSignalList     = {'ECU_X','ECU_Y','ECU_Z'};
sSignalListFCU  = {'FCU_X','FCU_Y','FCU_Z'};
sSignalListFCR  = {'FCR_X','FCR_Y','FCR_Z'};
sTrialTypeList  = {'UP_HF','UP_HS','SIDE_HF','SIDE_HS','SIDE_VF','SIDE_VS','UP_VF','UP_VS'};
sTrialTypeListSideV = {'SIDE_VF','SIDE_VS'};
sTrialTypeListUpV   = {'UP_VF','UP_VS'};
sTrialTypeListSideH = {'SIDE_HF','SIDE_HS'};
sTrialTypeListUpH = {'UP_HF','UP_HS'};
idTrialTypeF   = [7,9,11,13]; %fast movements
idTrialTypeS   = [7,9,11,13]+1; %slow movements
idTrialTypeH   = [7:10]; %horizontal trial
idTrialTypeV   = [11:14]; %vertical trial



% Get the representative signals using selectRepresentativeSensor.m
% signal for sideways vertical movements
[nSignalSideV,sSignalSideV] = selectRepresentativeSensor(dbox,sScript,sTable,idSignalEvent,sSignalList,sSignalListFCU,sSignalListFCR,sTrialTypeListSideV);

% signal for sideways horizontal movements
[nSignalSideH,sSignalSideH] = selectRepresentativeSensor(dbox,sScript,sTable,idSignalEvent,sSignalList,sSignalListFCU,sSignalListFCR,sTrialTypeListSideH);

% signal for upright vertical movements
[nSignalUpV,sSignalUpV] = selectRepresentativeSensor(dbox,sScript,sTable,idSignalEvent,sSignalList,sSignalListFCU,sSignalListFCR,sTrialTypeListUpV);

% signal for sideways horizontal movements
[nSignalUpH,sSignalUpH] = selectRepresentativeSensor(dbox,sScript,sTable,idSignalEvent,sSignalList,sSignalListFCU,sSignalListFCR,sTrialTypeListUpH);


% % create events for the vertical trials
% 
% vTrials = detectReachMovements(dbox,idSubject,idSignalEvent,sScript,...
%     sTable,sTrialTypeListV,svSignal,vSignal,idTrialTypeV);
% 
% % create events for the horizontal trials
% 
% hTrials = detectReachMovements(dbox,idSubject,idSignalEvent,sScript,...
%     sTable,sTrialTypeListH,shSignal,hSignal,idTrialTypeH);