

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


% [meanS1,stdS1] = getEventDuration(sideVEventsS1);
% [meanS4,stdS4] = getEventDuration(sideVEventsS4);
% [meanS6,stdS6] = getEventDuration(sideVEventsS6);
% [meanS7,stdS7] = getEventDuration(sideVEventsS7);
% [meanS8,stdS8] = getEventDuration(sideVEventsS8);
% [meanS9,stdS9] = getEventDuration(sideVEventsS9);
% 
% averagesSlow = [meanS1,meanS4,meanS6,meanS7,meanS8,meanS9];
% stdsSlow = [stdS1,stdS4,stdS6,stdS7,stdS8,stdS9];
% 
% SlowValuesSideV = table(averagesSlow',stdsSlow')
% 
% [meanF1,stdF1] = getEventDuration(sideVEventsF1);
% [meanF4,stdF4] = getEventDuration(sideVEventsF4);
% [meanF6,stdF6] = getEventDuration(sideVEventsF6);
% [meanF7,stdF7] = getEventDuration(sideVEventsF7);
% [meanF8,stdF8] = getEventDuration(sideVEventsF8);
% [meanF9,stdF9] = getEventDuration(sideVEventsF9);
% 
% averagesFast = [meanF1,meanF4,meanF6,meanF7,meanF8,meanF9];
% stdsFast = [stdF1,stdF4,stdF6,stdF7,stdF8,stdF9];
% 
% FastValuesSideV = table(averagesFast',stdsFast')


% sideways horizontal trials
sSignalSideH = "FCR_Y";
nSignalSideH = 48;
[sideHEventsS1,sideHEventsF1,sideHEventsS4,sideHEventsF4,sideHEventsS6,...
    sideHEventsF6,sideHEventsS7,sideHEventsF7,sideHEventsS8,sideHEventsF8,...
    sideHEventsS9,sideHEventsF9] = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListSideH,idTrialTypeSideH,sSignalSideH,nSignalSideH);

% [meanS1,stdS1] = getEventDuration(sideHEventsS1);
% [meanS4,stdS4] = getEventDuration(sideHEventsS4);
% [meanS6,stdS6] = getEventDuration(sideHEventsS6);
% [meanS7,stdS7] = getEventDuration(sideHEventsS7);
% [meanS8,stdS8] = getEventDuration(sideHEventsS8);
% [meanS9,stdS9] = getEventDuration(sideHEventsS9);
% 
% averagesSlow = [meanS1,meanS4,meanS6,meanS7,meanS8,meanS9];
% stdsSlow = [stdS1,stdS4,stdS6,stdS7,stdS8,stdS9];
% 
% SlowValuesSideH = table(averagesSlow',stdsSlow')
% 
% [meanF1,stdF1] = getEventDuration(sideHEventsF1);
% [meanF4,stdF4] = getEventDuration(sideHEventsF4);
% [meanF6,stdF6] = getEventDuration(sideHEventsF6);
% [meanF7,stdF7] = getEventDuration(sideHEventsF7);
% [meanF8,stdF8] = getEventDuration(sideHEventsF8);
% [meanF9,stdF9] = getEventDuration(sideHEventsF9);
% 
% averagesFast = [meanF1,meanF4,meanF6,meanF7,meanF8,meanF9];
% stdsFast = [stdF1,stdF4,stdF6,stdF7,stdF8,stdF9];
% 
% FastValuesSideH = table(averagesFast',stdsFast')

% upright vertical trials
[upVEventsS1,upVEventsF1,upVEventsS4,upVEventsF4,upVEventsS6,upVEventsF6,...
    upVEventsS7,upVEventsF7,upVEventsS8,upVEventsF8,upVEventsS9,...
    upVEventsF9] = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListUpV,idTrialTypeUpV,sSignalUpV,nSignalUpV);

% [meanS1,stdS1] = getEventDuration(upVEventsS1);
% [meanS4,stdS4] = getEventDuration(upVEventsS4);
% [meanS6,stdS6] = getEventDuration(upVEventsS6);
% [meanS7,stdS7] = getEventDuration(upVEventsS7);
% [meanS8,stdS8] = getEventDuration(upVEventsS8);
% [meanS9,stdS9] = getEventDuration(upVEventsS9);
% 
% averagesSlow = [meanS1,meanS4,meanS6,meanS7,meanS8,meanS9];
% stdsSlow = [stdS1,stdS4,stdS6,stdS7,stdS8,stdS9];
% 
% SlowValuesUpV = table(averagesSlow',stdsSlow')
% 
% [meanF1,stdF1] = getEventDuration(upVEventsF1);
% [meanF4,stdF4] = getEventDuration(upVEventsF4);
% [meanF6,stdF6] = getEventDuration(upVEventsF6);
% [meanF7,stdF7] = getEventDuration(upVEventsF7);
% [meanF8,stdF8] = getEventDuration(upVEventsF8);
% [meanF9,stdF9] = getEventDuration(upVEventsF9);
% 
% averagesFast = [meanF1,meanF4,meanF6,meanF7,meanF8,meanF9];
% stdsFast = [stdF1,stdF4,stdF6,stdF7,stdF8,stdF9];
% 
% FastValuesUpV = table(averagesFast',stdsFast')

% upright horizontal trials
sSignalUpH = "FCR_Z";
nSignalUpH = 49;
[upHEventsS1,upHEventsF1,upHEventsS4,upHEventsF4,upHEventsS6,upHEventsF6,...
    upHEventsS7,upHEventsF7,upHEventsS8,upHEventsF8,upHEventsS9,...
    upHEventsF9] = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListUpH,idTrialTypeUpH,sSignalUpH,nSignalUpH);

% [meanS1,stdS1] = getEventDuration(upHEventsS1);
% [meanS4,stdS4] = getEventDuration(upHEventsS4);
% [meanS6,stdS6] = getEventDuration(upHEventsS6);
% [meanS7,stdS7] = getEventDuration(upHEventsS7);
% [meanS8,stdS8] = getEventDuration(upHEventsS8);
% [meanS9,stdS9] = getEventDuration(upHEventsS9);
% 
% averagesSlow = [meanS1,meanS4,meanS6,meanS7,meanS8,meanS9];
% stdsSlow = [stdS1,stdS4,stdS6,stdS7,stdS8,stdS9];
% 
% SlowValuesUpH = table(averagesSlow',stdsSlow')
% 
% [meanF1,stdF1] = getEventDuration(upHEventsF1);
% [meanF4,stdF4] = getEventDuration(upHEventsF4);
% [meanF6,stdF6] = getEventDuration(upHEventsF6);
% [meanF7,stdF7] = getEventDuration(upHEventsF7);
% [meanF8,stdF8] = getEventDuration(upHEventsF8);
% [meanF9,stdF9] = getEventDuration(upHEventsF9);
% 
% averagesFast = [meanF1,meanF4,meanF6,meanF7,meanF8,meanF9];
% stdsFast = [stdF1,stdF4,stdF6,stdF7,stdF8,stdF9];
% 
% FastValuesUpV = table(averagesFast',stdsFast')