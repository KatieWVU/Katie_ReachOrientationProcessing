

clear
clc

%%  load database
sPathSource = "G:\Shared drives\LABS-DATASETS\DATASET_REACH_ORIENTATION";
dbox        = databox();
dbox.loadMeta(sPathSource);
%%  Define Input variables
idSubject       = [1,4,6:9];
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
% this selects 57 and ECU_X


% signal for sideways horizontal movements
[nSignalSideH,sSignalSideH] = selectRepresentativeSensor(dbox,sScript,sTable,idSignalEvent,sSignalList,sSignalListFCU,sSignalListFCR,sTrialTypeListSideH);

% signal for upright vertical movements
[nSignalUpV,sSignalUpV] = selectRepresentativeSensor(dbox,sScript,sTable,idSignalEvent,sSignalList,sSignalListFCU,sSignalListFCR,sTrialTypeListUpV);
% this selects 46 and FCU_Z


% signal for sideways horizontal movements
[nSignalUpH,sSignalUpH] = selectRepresentativeSensor(dbox,sScript,sTable,idSignalEvent,sSignalList,sSignalListFCU,sSignalListFCR,sTrialTypeListUpH);

%%  Grab event times using detectReachMovements.m (do not include directions)

sSignalSideV = "ECU_X";
nSignalSideV = 57;
% sideways vertical trials
[sideVEventsS1,sideVEventsF1,sideVEventsS4,sideVEventsF4,sideVEventsS6,...
    sideVEventsF6,sideVEventsS7,sideVEventsF7,sideVEventsS8,sideVEventsF8,...
    sideVEventsS9,sideVEventsF9] = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListSideV,idTrialTypeSideV,sSignalSideV,nSignalSideV);


% sideways horizontal trials
sSignalSideH = "FCR_Y";
nSignalSideH = 48;
[sideHEventsS1,sideHEventsF1,sideHEventsS4,sideHEventsF4,sideHEventsS6,...
    sideHEventsF6,sideHEventsS7,sideHEventsF7,sideHEventsS8,sideHEventsF8,...
    sideHEventsS9,sideHEventsF9] = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListSideH,idTrialTypeSideH,sSignalSideH,nSignalSideH);

sSignalUpV = "ECU_X";
nSignalUpV = 57;
% upright vertical trials
[upVEventsS1,upVEventsF1,upVEventsS4,upVEventsF4,upVEventsS6,upVEventsF6,...
    upVEventsS7,upVEventsF7,upVEventsS8,upVEventsF8,upVEventsS9,...
    upVEventsF9] = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListUpV,idTrialTypeUpV,sSignalUpV,nSignalUpV);


% upright horizontal trials
sSignalUpH = "ECU_X";
nSignalUpH = 57;
[upHEventsS1,upHEventsF1,upHEventsS4,upHEventsF4,upHEventsS6,upHEventsF6,...
    upHEventsS7,upHEventsF7,upHEventsS8,upHEventsF8,upHEventsS9,...
    upHEventsF9] = detectReachMovements(dbox,idSignalEvent,sScript,...
    sTable,sTrialTypeListUpH,idTrialTypeUpH,sSignalUpH,nSignalUpH);



% the below is a function check for appropriate times of events (ie, check
% that the movements last approximately as long as the should)

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

%%
% commented out assignments have already been done and adjusted. Rerunning
% will make new events without the manual adjustments.


% sideways vertical trials
% assignTempEvents(dbox,nSignalSideV,sideVEventsF1,5);
% assignTempEvents(dbox,nSignalSideV,sideVEventsF4,29);
% assignTempEvents(dbox,nSignalSideV,sideVEventsS4,28);
% assignTempEvents(dbox,nSignalSideV,sideVEventsF6,45);
% assignTempEvents(dbox,nSignalSideV,sideVEventsS6,44);
% assignTempEvents(dbox,nSignalSideV,sideVEventsF7,53);
% assignTempEvents(dbox,nSignalSideV,sideVEventsS7,52);
% assignTempEvents(dbox,nSignalSideV,sideVEventsF8,61);
% assignTempEvents(dbox,nSignalSideV,sideVEventsS8,60);
% assignTempEvents(dbox,nSignalSideV,sideVEventsF9,69);
% assignTempEvents(dbox,nSignalSideV,sideVEventsS9,68);


% Sideways horizontal
% assignTempEvents(dbox,nSignalSideH,sideHEventsF1,3);
% assignTempEvents(dbox,nSignalSideH,sideHEventsS1,4);
% assignTempEvents(dbox,nSignalSideH,sideHEventsF4,25);
% assignTempEvents(dbox,nSignalSideH,sideHEventsS4,24);
% assignTempEvents(dbox,nSignalSideH,sideHEventsF6,41);
% assignTempEvents(dbox,nSignalSideH,sideHEventsS6,40);
% assignTempEvents(dbox,nSignalSideH,sideHEventsF7,49);
% assignTempEvents(dbox,nSignalSideH,sideHEventsS7,48);
% assignTempEvents(dbox,nSignalSideH,sideHEventsF8,57);
% assignTempEvents(dbox,nSignalSideH,sideHEventsS8,56);
% assignTempEvents(dbox,nSignalSideH,sideHEventsF9,65);
% assignTempEvents(dbox,nSignalSideH,sideHEventsS9,64);

% upright vertical trials
% assignTempEvents(dbox,nSignalUpV,upVEventsF4,27);
% assignTempEvents(dbox,nSignalUpV,upVEventsS4,26);
% assignTempEvents(dbox,nSignalUpV,upVEventsF6,43);
% assignTempEvents(dbox,nSignalUpV,upVEventsS6,42);
% assignTempEvents(dbox,nSignalUpV,upVEventsF7,51);
% assignTempEvents(dbox,nSignalUpV,upVEventsS7,50);
% assignTempEvents(dbox,nSignalUpV,upVEventsF8,59);
% assignTempEvents(dbox,nSignalUpV,upVEventsS8,58);
% assignTempEvents(dbox,nSignalUpV,upVEventsF9,67);
% assignTempEvents(dbox,nSignalUpV,upVEventsS9,66);

% upright horizontal
% assignTempEvents(dbox,nSignalUpH,upHEventsF1,1);
% assignTempEvents(dbox,nSignalUpH,upHEventsS1,2);
% assignTempEvents(dbox,nSignalUpH,upHEventsS4,22);
% assignTempEvents(dbox,nSignalUpH,upHEventsF6,39);
% assignTempEvents(dbox,nSignalUpH,upHEventsS6,38);
% assignTempEvents(dbox,nSignalUpH,upHEventsF7,47);
% assignTempEvents(dbox,nSignalUpH,upHEventsS7,46);
% assignTempEvents(dbox,nSignalUpH,upHEventsF8,55);
% assignTempEvents(dbox,nSignalUpH,upHEventsS8,54);
% assignTempEvents(dbox,nSignalUpH,upHEventsF9,63);
%%

% check the temporary events to make sure none got skipped. Add any
% which were skipped.

%%

% if you needed to add events, there will be back to back events of the
% same type. The following will reorder all events so that they alternate
% between event type

nSignalUpH = 57;
nSignalSideH = 48;
nSignalUpV = 57;
nSignalSideV = 57;

% sideways vertical trials
iSV = [5,28,29,44,45,52,53,60,61,68,69];
for i = iSV
    alternateTempEvents(dbox,nSignalSideV,i)
end

% sideways horizontal trials
iSH = [3,4,24,25,40,41,48,49,56,57,64,65];
for i = iSH
    alternateTempEvents(dbox,nSignalSideH,i)
end

% upright vertical trials
iUV = [26,27,42,43,50,51,58,59,66,67];
for i = iUV
    alternateTempEvents(dbox,nSignalUpV,i)
end

% Upright horizontal trials
iUH = [1,2,22,38,39,46,47,54,55,63];
for i = iUH
    alternateTempEvents(dbox,nSignalUpH,i)
end


%%

% at this point you need to make any necessary adjustments in monitor
% session

%%
% run classifyReachDirection to get events specific to reach direction

classifyReachDirection([])
