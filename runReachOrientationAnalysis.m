

clear
clc

%%  load database
sPathSource = "G:\Shared drives\LABS-DATASETS\DATASET_REACH_ORIENTATION";
dbox        = databox();
dbox.loadMeta(sPathSource);
%%  Define Input variables
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
sTrialTypeListUpH   = {'UP_HF','UP_HS'};
idTrialTypeSideV = [11,12];
idTrialTypeSideH = [9,10];
idTrialTypeUpV   = [13,14];
idTrialTypeUpH   = [7,8];
% idTrialTypeF   = [7,9,11,13]; %fast movements
% idTrialTypeS   = [7,9,11,13]+1; %slow movements
% idTrialTypeH   = [7:10]; %horizontal trial
% idTrialTypeV   = [11:14]; %vertical trial


%%  Get the representative signals using selectRepresentativeSensor.m


% signal for sideways vertical movements
[nSignalSideV,sSignalSideV] = selectRepresentativeSensor(dbox,sScript,sTable,idSignalEvent,sSignalList,sSignalListFCU,sSignalListFCR,sTrialTypeListSideV);

% signal for sideways horizontal movements
[nSignalSideH,sSignalSideH] = selectRepresentativeSensor(dbox,sScript,sTable,idSignalEvent,sSignalList,sSignalListFCU,sSignalListFCR,sTrialTypeListSideH);

% signal for upright vertical movements
[nSignalUpV,sSignalUpV] = selectRepresentativeSensor(dbox,sScript,sTable,idSignalEvent,sSignalList,sSignalListFCU,sSignalListFCR,sTrialTypeListUpV);

% signal for sideways horizontal movements
[nSignalUpH,sSignalUpH] = selectRepresentativeSensor(dbox,sScript,sTable,idSignalEvent,sSignalList,sSignalListFCU,sSignalListFCR,sTrialTypeListUpH);

%%  Grab event times using detectReachMovements.m (do not include directions)


% sideways vertical trials
sideVTrials = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListSideV,sSignalSideV,nSignalSideV,idTrialTypeSideV);

% sideways horizontal trials
sideHTrials = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListSideH,sSignalSideH,nSignalSideH,idTrialTypeSideH);

% upright vertical trials
upVTrials = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListUpV,sSignalUpV,nSignalUpV,idTrialTypeUpV);

% upright horizontal trials
upHTrials = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListUpH,sSignalUpH,nSignalUpH,idTrialTypeUpH);