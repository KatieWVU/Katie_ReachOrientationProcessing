
function classifyReachDirection(dboxIn,idTrialsIn)

dbox        = dboxIn;

sScript         = 'nData = butterfilt(nData,nRate,6,''nOrder'',2);';
sTable          = 'accraw';
sSignalList     = {'ECU_X','ECU_Y','ECU_Z'};
sTrialTypeList  = {'UP_HF','UP_HS'}; %'UP_HF','UP_HS','SIDE_HF','SIDE_HS','SIDE_VF','SIDE_VS','UP_VF','UP_VS'

idTrials = idTrialsIn;


nRate = dbox.getMeta('metaSignal',{'sTable',sTable,...
    'sSignal',sSignalList{1}},'nRate');

if isequal(idTrials,[1,2,22,38,39,46,47,54,55,63])
    for i = 1:numel(idTrials)
        signal = dbox.getSignal(46,nums(i));

        filSignal = butterfilt(signal,nRate,1);

        tOn = dbox.getEvent(nums(i),57,'on',[]);
        yOn = filSignal(round(tOn*nRate,0));

        tOff = dbox.getEvent(nums(i),57,'peak',[]);
        yOff = filSignal(round(tOff*nRate,0));

        len = min(numel(yOn),numel(yOff));

        diff = zeros(len,1);
        for j = 1:len-1
            diff(j) = tOn(j)-tOff(j);
        end

        aveDiff = mean(diff);

        if aveDiff < 1

        x = 0:numel(signal)-1;
        t = x/nRate;

        figure
        plot(t,filSignal)
        hold on
        plot(tOn,yOn,'ko')
        plot(tOff,yOff,'ro')
        hold off
        title(['FCU_Z filtered Trial ', num2str(nums(i))])
    end
end




end