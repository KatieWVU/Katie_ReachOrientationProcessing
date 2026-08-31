% created 8/19/2026
% Purpose: create a graph showing the theoretical time between events for a
% certain movement and the actual time as determined by a
% velocity_PlaceEvents run.


clear
clc
%% load database
sPathSource = "G:\Shared drives\LABS-DATASETS\DATASET_REACH_ORIENTATION";
dbox        = databox();
dbox.loadMeta(sPathSource);
%%
idSubject       = [6];
idSignalEvent   = 10;
sScript         = 'nData = butterfilt(nData,nRate,6,''nOrder'',2);';
sTable          = 'accraw';
sSignalList     = {'ECU_X','ECU_Y','ECU_Z'};
sSignalListFCU  = {'FCU_X','FCU_Y','FCU_Z'};
sSignalListFCR  = {'FCR_X','FCR_Y','FCR_Z'};
sTrialTypeList  = {'UP_HF','UP_HS','SIDE_HF','SIDE_HS','SIDE_VF','SIDE_VS','UP_VF','UP_VS'}; %'UP_HF','UP_HS','SIDE_HF','SIDE_HS','SIDE_VF','SIDE_VS','UP_VF','UP_VS'
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
           
            nBeat = dbox.getMeta('metaTrialType',{'idTrialType',idTrialType},'nBeat'); % read beat at which the subject was paced
            tBeat = (60/nBeat); % time one beat takes, in s
            
            
            
            tUp = dbox.getEvent(idTrial,idSignalEvent,'on',[]);
            tDown  = dbox.getEvent(idTrial,idSignalEvent,'off',[]);

            times = cat(1,tUp, tDown);
            times = sort(times);

            diff = zeros(numel(times)-1,1);


            for i = 1:numel(times)-1
                diff(i) = times(i+1)-times(i);
            end

            x = 1:numel(diff);

            theo = ones(numel(diff),1) * tBeat;
            
            figure
            plot(x,theo,x,diff)
            ylabel('Time of Movement')
            legend('Theoretical','Experimental')
            title(['idTrial ',num2str(idTrial)])


            display(['Finished idTrial ',num2str(idTrial)])


        end
    end
end