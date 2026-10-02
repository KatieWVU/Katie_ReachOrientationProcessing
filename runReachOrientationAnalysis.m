

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
[sideVEventsS1,sideVEventsF1,sideVEventsS4,sideVEventsF4,sideVEventsS6,...
    sideVEventsF6,sideVEventsS7,sideVEventsF7,sideVEventsS8,sideVEventsF8,...
    sideVEventsS9,sideVEventsF9] = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListSideV,idTrialTypeSideV,sSignalSideV,nSignalSideV);

sSignalSideH = "FCR_Y";
nSignalSideH = 48;
% sideways horizontal trials
[sideHEventsS1,sideHEventsF1,sideHEventsS4,sideHEventsF4,sideHEventsS6,...
    sideHEventsF6,sideHEventsS7,sideHEventsF7,sideHEventsS8,sideHEventsF8,...
    sideHEventsS9,sideHEventsF9] = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListSideH,idTrialTypeSideH,sSignalSideH,nSignalSideH);

% upright vertical trials
[upVEventsS1,upVEventsF1,upVEventsS4,upVEventsF4,upVEventsS6,upVEventsF6,...
    upVEventsS7,upVEventsF7,upVEventsS8,upVEventsF8,upVEventsS9,...
    upVEventsF9] = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListUpV,idTrialTypeUpV,sSignalUpV,nSignalUpV);

sSignalUpH = "FCR_Z";
nSignalUpH = 49;
% upright horizontal trials
[upHEventsS1,upHEventsF1,upHEventsS4,upHEventsF4,upHEventsS6,upHEventsF6,...
    upHEventsS7,upHEventsF7,upHEventsS8,upHEventsF8,upHEventsS9,...
    upHEventsF9] = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListUpH,idTrialTypeUpH,sSignalUpH,nSignalUpH);