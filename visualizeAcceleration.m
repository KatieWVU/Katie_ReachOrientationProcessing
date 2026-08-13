clear
clc
%% load database
sPathSource = "G:\Shared drives\LABS-DATASETS\DATASET_REACH_ORIENTATION";
dbox        = databox();
dbox.loadMeta(sPathSource);
%%
idSubject       = [1]; 
idSignalEvent   = 10;
sScript         = 'nData = butterfilt(nData,nRate,6,''nOrder'',2);';
sTable          = 'accraw';
sSignalList     = {'ECU_X','ECU_Y','ECU_Z'};
sTrialTypeList  = {'UP_HF','UP_HS','SIDE_HF','SIDE_HS','SIDE_VF','SIDE_VS','UP_VF','UP_VS'};
idTrialTypeF   = [7,9,11,13]; %fast movements
idTrialTypeS   = [7,9,11,13]+1; %slow movements
idTrialTypeH   = [7:10]; %horizontal trial
idTrialTypeV   = [11:14]; %vertical trial

idSignalList = dbox.getMeta('metaSignal',{'sTable',sTable,...
    'sSignal',sSignalList},'idSignal'); % read signal IDs
nRate = dbox.getMeta('metaSignal',{'sTable',sTable,...
    'sSignal',sSignalList{1}},'nRate');
for iTrialType = 1:numel(sTrialTypeList)
    idTrialList = dbox.getMeta('metaTrial',{'idSubject',idSubject,...
        'sTrialType',sTrialTypeList{iTrialType},'bTrial',1},'idTrial'); % read trials for a given subject
    if ~isempty(idTrialList)
        for idTrial = idTrialList
            idTrialType = dbox.getMeta('metaTrial',{'idTrial',idTrial},'idTrialType'); % read the movement type
            nBeat = dbox.getMeta('metaTrialType',{'idTrialType',idTrialType},'nBeat'); % read beat at which the subject was paced
            tBeat = (60/nBeat); % time one beat takes, in s

            tSync = dbox.getMeta('metaSync',{'idTrial',idTrial},sTable); % read the movement type

            nData      = dbox.getSignal(idSignalList(1),idTrial,'sScript',sScript);
            nData(2,:) = dbox.getSignal(idSignalList(2),idTrial,'sScript',sScript);
            nData(3,:) = dbox.getSignal(idSignalList(3),idTrial,'sScript',sScript);

            tStart = dbox.getEvent(idTrial,idSignalEvent,'peak',1);
            tStop  = dbox.getEvent(idTrial,idSignalEvent,'off',1);
            tMove  = dbox.getEvent(idTrial,idSignalEvent,'on',[]);

            if isnan(tStop)
                tStop = tMove(end);
            end

            nx = 0:numel(nData(1,:))-1;
            t = nx/nRate;

            % The below formats the graph as three subplots

            % figure
            % subplot(3,1,1)
            % plot(t,nData(1,:))
            % hold on
            % ylabel('ECU X Acceleration')
            % hold off
            % 
            % subplot(3,1,2)
            % plot(t,nData(2,:))
            % hold on
            % ylabel('ECU Y Acceleration')
            % hold off
            % 
            % subplot(3,1,3)
            % plot(t,nData(3,:))
            % hold on
            % ylabel('ECU Z Acceleration')
            % xlabel('Time (s)')
            % hold off
            % 
            % sgtitle(['idTrial ',num2str(idTrial)])


            % the below formats the graph as a single plot with three lines

            figure
            plot(t,nData(1,:))
            hold on
            plot(t, nData(2,:))
            plot(t,nData(3,:))
            hold off
            ylabel('Acceleration Signal (ECU)')
            xlabel('Time (s)')
            legend('X','Y','Z')
            title(['idTrial ',num2str(idTrial)])
            saveas(gcf,['Acceleration idTrial ',num2str(idTrial),'.png'])


            display(['Finished idTrial ',num2str(idTrial)])


        end
    end
end