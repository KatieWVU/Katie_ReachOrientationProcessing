clear
clc
%% load database
sPathSource = "G:\Shared drives\LABS-DATASETS\DATASET_REACH_ORIENTATION";
dbox        = databox();
dbox.loadMeta(sPathSource);
%%
idSubject       = [9]; 
idSignalEvent   = 10;
sScript         = 'nData = butterfilt(nData,nRate,6,''nOrder'',2);';
sTable          = 'accraw';
sSignalList     = {'ECU_X','ECU_Y','ECU_Z'};
sSignalListFCU  = {'FCU_X','FCU_Y','FCU_Z'};
sSignalListFCR  = {'FCR_X','FCR_Y','FCR_Z'};
sTrialTypeList  = {'SIDE_VF','SIDE_VS','UP_VF','UP_VS'}; %'UP_HF','UP_HS','SIDE_HF','SIDE_HS','SIDE_VF','SIDE_VS','UP_VF','UP_VS'
idTrialTypeF   = [7,9,11,13]; %fast movements
idTrialTypeS   = [7,9,11,13]+1; %slow movements
idTrialTypeH   = [7:10]; %horizontal trial
idTrialTypeV   = [11:14]; %vertical trial

idSignalList = dbox.getMeta('metaSignal',{'sTable',sTable,...
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
           
            % nBeat = dbox.getMeta('metaTrialType',{'idTrialType',idTrialType},'nBeat'); % read beat at which the subject was paced
            % tBeat = (60/nBeat); % time one beat takes, in s
            % 
            % tSync = dbox.getMeta('metaSync',{'idTrial',idTrial},sTable); % read the movement type

            % Get ECU data
            nData      = dbox.getSignal(idSignalList(1),idTrial,'sScript',sScript);
            nData(2,:) = dbox.getSignal(idSignalList(2),idTrial,'sScript',sScript);
            nData(3,:) = dbox.getSignal(idSignalList(3),idTrial,'sScript',sScript);
            nVec     = sqrt(sum(nData.^2,1));
            nVecF    = butterfilt(abs(nVec-mean(nVec)),nRate,3,'nOrder',2);
            
            
            tUp = dbox.getEvent(idTrial,idSignalEvent,'on',[]);
            tDown  = dbox.getEvent(idTrial,idSignalEvent,'off',[]);

            nUp = round(tUp*nRate,0);
            nDown = round(tDown*nRate,0);

            nFirst = round((min(tUp(1),tDown(1)))*nRate,0);
            nLast = round((max(tUp(end),tDown(end))*nRate),0);



            nx = 0:numel(nVecF)-1;
            time = nx./nRate; %nFirst:nLast
            zero = zeros(size(time));

            ECU = nVecF(); % nFirst:nLast

            velECU = cumtrapz(time,ECU);

            highpassECU = butterfilt(velECU,nRate,0.5,'nOrder',2,'sType','high');

            % Get FCU Data

            nData      = dbox.getSignal(idSignalListFCU(1),idTrial,'sScript',sScript);
            nData(2,:) = dbox.getSignal(idSignalListFCU(2),idTrial,'sScript',sScript);
            nData(3,:) = dbox.getSignal(idSignalListFCU(3),idTrial,'sScript',sScript);
            nVec     = sqrt(sum(nData.^2,1));
            nVecFFCU    = butterfilt(abs(nVec-mean(nVec)),nRate,3,'nOrder',2);

            FCU = nVecFFCU;

            velFCU = cumtrapz(time,FCU);

            highpassFCU = butterfilt(velFCU,nRate,0.5,'nOrder',2,'sType','high');

            % Get FCR Data

            nData      = dbox.getSignal(idSignalListFCR(1),idTrial,'sScript',sScript);
            nData(2,:) = dbox.getSignal(idSignalListFCR(2),idTrial,'sScript',sScript);
            nData(3,:) = dbox.getSignal(idSignalListFCR(3),idTrial,'sScript',sScript);
            nVec     = sqrt(sum(nData.^2,1));
            nVecFFCR    = butterfilt(abs(nVec-mean(nVec)),nRate,3,'nOrder',2);

            FCR = nVecFFCR();

            velFCR = cumtrapz(time,FCR);

            highpassFCR = butterfilt(velFCR,nRate,0.5,'nOrder',2,'sType','high');



            figure
            subplot(3,1,1)
            plot(time,highpassECU)
            hold on
            plot(tUp,highpassECU(nUp),'^') %-nFirst+1
            plot(tDown,highpassECU(nDown),'v')
            ylabel('ECU Velocity')
            hold off

            subplot(3,1,2)
            plot(time,highpassFCU)
            hold on
            plot(tUp,highpassFCU(nUp),'^')
            plot(tDown,highpassFCU(nDown),'v')
            ylabel('FCU Velocity')
            hold off

            subplot(3,1,3)
            plot(time,highpassFCR)
            hold on
            plot(tUp,highpassFCR(nUp),'^')
            plot(tDown,highpassFCR(nDown),'v')
            ylabel('FCR Velocity')
            xlabel('Time (s)')
            hold off

            sgtitle(['idTrial ',num2str(idTrial)])


            display(['Finished idTrial ',num2str(idTrial)])


        end
    end
end