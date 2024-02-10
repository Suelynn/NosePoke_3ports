function NosePoke_3ports()
% Learning to Nose Poke side ports

global BpodSystem
global TaskParameters

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    %general
    TaskParameters.GUI.Ports_M = '4';
    TaskParameters.GUI.BackPorts_LMR = '123';
    TaskParameters.GUI.FI = 0.5; % (s)
    TaskParameters.GUI.PreITI=1.5;
    TaskParameters.GUI.VI = false;
    TaskParameters.GUI.DrinkingTime=0.3;
    TaskParameters.GUI.DrinkingGrace=0.05;
    TaskParameters.GUIMeta.VI.Style = 'checkbox';
    TaskParameters.GUI.ChoiceDeadline = 10;
    TaskParameters.GUIPanels.General = {'Ports_M','BackPorts_LMR', 'FI','PreITI', 'VI', 'DrinkingTime'...
        'DrinkingGrace','ChoiceDeadline'};
    
    %"stimulus"
    TaskParameters.GUI.MinSampleTime = 0.01;
    TaskParameters.GUI.MaxSampleTime = 1;
    TaskParameters.GUI.AutoIncrSample = true;
    TaskParameters.GUIMeta.AutoIncrSample.Style = 'checkbox';
    TaskParameters.GUI.MinSampleIncr = 0.01;
    TaskParameters.GUI.MinSampleDecr = 0.005;
    TaskParameters.GUI.EarlyWithdrawalTimeOut = 3;
    TaskParameters.GUI.EarlyWithdrawalNoise = false;
    TaskParameters.GUIMeta.EarlyWithdrawalNoise.Style='checkbox';
    TaskParameters.GUI.GracePeriod = 0;
    TaskParameters.GUI.SampleTime = TaskParameters.GUI.MinSampleTime;
    TaskParameters.GUIMeta.SampleTime.Style = 'text';
    TaskParameters.GUIPanels.Sampling = {'MinSampleTime','MaxSampleTime','AutoIncrSample','MinSampleIncr','MinSampleDecr','EarlyWithdrawalTimeOut','EarlyWithdrawalNoise','GracePeriod','SampleTime'};
    
    %Reward
    TaskParameters.GUI.rewardAmountL = 15;
    TaskParameters.GUI.rewardAmountC = 30;
    TaskParameters.GUI.rewardAmountR = 50;
    TaskParameters.GUIMeta.CenterReward.Style = 'checkbox';
    TaskParameters.GUI.CenterReward=true;
    TaskParameters.GUI.CenterRewardAmount=10;
    
    TaskParameters.GUIPanels.Reward = {'rewardAmountL','rewardAmountC','rewardAmountR','CenterReward','CenterRewardAmount'};
        
    %Reward Delay
    TaskParameters.GUI.RewardDelay = 0;
    TaskParameters.GUIMeta.RewardDelayExp.Style = 'checkbox';
    TaskParameters.GUI.RewardDelayExp = false;
    TaskParameters.GUIMeta.TimeInvestment.Style = 'checkbox';
    TaskParameters.GUI.TimeInvestment = false;
    TaskParameters.GUI.FeedbackDelay1=0.1;
    TaskParameters.GUI.FeedbackDelay2=0.5;
    TaskParameters.GUI.FeedbackDelay3=1;
    
    TaskParameters.GUIPanels.RewardDelay = {'RewardDelay','RewardDelayExp','TimeInvestment','FeedbackDelay1','FeedbackDelay2','FeedbackDelay3'};
  

        
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
    TaskParameters.Figures.OutcomePlot.Position = [200, 200, 1000, 400];
end
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors and first values
BpodSystem.Data.Custom.ChoiceLCR(1,:) = [NaN,NaN,NaN];
BpodSystem.Data.Custom.SampleTime(1) = TaskParameters.GUI.MinSampleTime;
BpodSystem.Data.Custom.EarlyWithdrawal(1) = false;

BpodSystem.Data.Custom.RewardMagnitude(1,:) = [TaskParameters.GUI.rewardAmountL,TaskParameters.GUI.rewardAmountC...,
    TaskParameters.GUI.rewardAmountR];
BpodSystem.Data.Custom.TotalReward = 0;


BpodSystem.Data.Custom.Rewarded(1) = NaN;
BpodSystem.Data.Custom.Correct(1) = NaN;

BpodSystem.Data.Custom.GracePeriod(1) = TaskParameters.GUI.GracePeriod;
BpodSystem.Data.Custom.LightOn(1,:) =Shuffle([1,0,0], 2);
BpodSystem.Data.Custom.RewardDelay = TaskParameters.GUI.RewardDelay;
BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);
%server data
[~,BpodSystem.Data.Custom.Rig] = system('hostname');
[~,BpodSystem.Data.Custom.Subject] = fileparts(fileparts(fileparts(fileparts(BpodSystem.DataPath))));
BpodSystem.Data.Custom.PsychtoolboxStartup=false;

%% Configuring PulsePal
load PulsePalParamStimulus.mat
load PulsePalParamFeedback.mat
BpodSystem.Data.Custom.PulsePalParamStimulus=PulsePalParamStimulus;
BpodSystem.Data.Custom.PulsePalParamFeedback=PulsePalParamFeedback;
clear PulsePalParamFeedback PulsePalParamStimulus

BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler';

%% Initialize plots
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', TaskParameters.Figures.OutcomePlot.Position,'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot.HandleOutcome = axes('Position',    [  .055            .15 .91 .3]);
BpodSystem.GUIHandles.OutcomePlot.HandleGracePeriod = axes('Position',  [1*.05           .6  .1  .3], 'Visible', 'off');
BpodSystem.GUIHandles.OutcomePlot.HandleTrialRate = axes('Position',    [3*.05 + 2*.08   .6  .1  .3], 'Visible', 'off');
BpodSystem.GUIHandles.OutcomePlot.HandleST = axes('Position',           [5*.05 + 4*.08   .6  .1  .3], 'Visible', 'off');
BpodSystem.GUIHandles.OutcomePlot.HandleMT = axes('Position',           [6*.05 + 6*.08   .6  .1  .3], 'Visible', 'off');
NosePoke_PlotSideOutcome(BpodSystem.GUIHandles.OutcomePlot,'init');

%% Main loop
RunSession = true;
iTrial = 1;

while RunSession
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    
    sma = stateMatrix(iTrial);
    SendStateMatrix(sma);
    
    %% Run Trial
    RawEvents = RunStateMatrix;
    
    %% Bpod save
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        SaveBpodSessionData;
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
    
    %% update fields
    updateCustomDataFields(iTrial)
    
    %% update figures
    NosePoke_PlotSideOutcome(BpodSystem.GUIHandles.OutcomePlot,'update',iTrial);


    iTrial = iTrial + 1;    
end

end

function sma = stateMatrix(iTrial)
global BpodSystem
global TaskParameters
%% Define ports
CenterPort = TaskParameters.GUI.Ports_M;
CenterPortIn = strcat('Port',num2str(CenterPort),'In');
CenterPortOut = strcat('Port',num2str(CenterPort),'Out');


bLeftPort = floor(mod(TaskParameters.GUI.BackPorts_LMR/100,10));
bCenterPort = floor(mod(TaskParameters.GUI.BackPorts_LMR/10,10));
bRightPort = mod(TaskParameters.GUI.BackPorts_LMR,10);

bLeftPortout = strcat('Port',num2str(bLeftPort),'Out');
bCenterPortout = strcat('Port',num2str(bCenterPort),'Out');
bRightPortout = strcat('Port',num2str(bRightPort),'Out');

bLeftPortIn = strcat('Port',num2str(bLeftPort),'In');
bCenterPortIn = strcat('Port',num2str(bCenterPort),'In');
bRightPortIn = strcat('Port', num2str(bRightPort),'In');

bLeftValve = 2^(bLeftPort-1);
bCenterValve = 2^(bCenterPort-1);
bRightValve = 2^(bRightPort-1);
CenterValve = 2^(CenterPort-1);




%%


bLeftValveTime  = GetValveTimes(TaskParameters.GUI.rewardAmountL, bLeftPort);
bCenterValveTime  = GetValveTimes(TaskParameters.GUI.rewardAmountC, bCenterPort);
bRightValveTime  = GetValveTimes(TaskParameters.GUI.rewardAmountR, bRightPort);

if TaskParameters.GUI.CenterReward
    CenterValveTime  = GetValveTimes(TaskParameters.GUI.CenterRewardAmount, CenterPort);
    
end



if TaskParameters.GUI.EarlyWithdrawalNoise
    PunishSoundAction=11;
else
    PunishSoundAction=0;
end

if find(BpodSystem.Data.Custom.LightOn(iTrial,:))==1
    operantState='left_on';
    operantAction=bLeftPortIn;
    operantLight=strcat('PWM',num2str(bLeftPort));
    beep={'SoftCode',13};
    
    rewardState='bLeftPort_Reward';
    gracePokeOutAction=bLeftPortout;
    gracePokeInAction=bLeftPortIn;
    FeedbackDelay=TaskParameters.GUI.FeedbackDelay1;
    
elseif find(BpodSystem.Data.Custom.LightOn(iTrial,:))==2
    operantState='center_on';
    operantAction=bCenterPortIn;
    operantLight=strcat('PWM',num2str(bCenterPort));
    beep={'SoftCode',14};
    
    rewardState='bCenterPort_Reward';
    gracePokeOutAction=bCenterPortout;
    gracePokeInAction=bCenterPortIn;
    FeedbackDelay=TaskParameters.GUI.FeedbackDelay2;
    
elseif find(BpodSystem.Data.Custom.LightOn(iTrial,:))==3
    operantState='right_on';
    operantAction=bRightPortIn;
    operantLight=strcat('PWM',num2str(bRightPort));
    beep={'SoftCode',15};
    
    rewardState='bRightPort_Reward';
    gracePokeOutAction=bRightPortout;
    gracePokeInAction=bRightPortIn;
    FeedbackDelay=TaskParameters.GUI.FeedbackDelay2;
    
else
    operantState='left_on';
    operantAction=bLeftPortIn;
    operantLight=strcat('PWM',num2str(bLeftPort));
    
    rewardState='bLeftPort_Reward';
    gracePokeOutAction=bLeftPortout;
    gracePokeInAction=bLeftPortIn;
   
end


if TaskParameters.GUI.RewardDelayExp
    BpodSystem.Data.rewardDelay(iTrial)=exprnd(TaskParameters.GUI.RewardDelay);
else
    BpodSystem.Data.rewardDelay(iTrial)=TaskParameters.GUI.RewardDelay;
    
end

sma = NewStateMatrix();

if TaskParameters.GUI.TimeInvestment
    sma = SetGlobalTimer(sma,1,FeedbackDelay);
else
    sma = SetGlobalTimer(sma,1,TaskParameters.GUI.SampleTime);
end
sma = SetGlobalTimer(sma,2,BpodSystem.Data.rewardDelay(iTrial));
sma = AddState(sma, 'Name', 'state_0',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'PreITI'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'PreITI',...
    'Timer', TaskParameters.GUI.PreITI,...
    'StateChangeConditions', {'Tup', 'wait_Cin'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'wait_Cin',...
    'Timer', 0,...
    'StateChangeConditions', {CenterPortIn, 'StartSampling'},...
    'OutputActions', {strcat('PWM',num2str(CenterPort)),255});

if TaskParameters.GUI.CenterReward
    
sma = AddState(sma, 'Name', 'StartSampling',...
    'Timer', CenterValveTime,...
    'StateChangeConditions', {'Tup', 'Sampling'},...
    'OutputActions', {'GlobalTimerTrig',1, 'ValveState', CenterValve});

else
    
sma = AddState(sma, 'Name', 'StartSampling',...
    'Timer', 0.01,...
    'StateChangeConditions', {'Tup', 'Sampling'},...S
    'OutputActions', {'GlobalTimerTrig',1});
end

if TaskParameters.GUI.TimeInvestment
    
    sma = AddState(sma, 'Name', 'Sampling',...
    'Timer',FeedbackDelay,...
    'StateChangeConditions', {CenterPortOut, 'GracePeriod','Tup','wait_action','GlobalTimer1_End','wait_action'},...
    'OutputActions', {});
    sma = AddState(sma, 'Name', 'GracePeriod',...
        'Timer', TaskParameters.GUI.GracePeriod,...
        'StateChangeConditions', {CenterPortIn, 'Sampling','Tup','EarlyWithdrawal','GlobalTimer1_End','EarlyWithdrawal'...,
        bLeftPortIn,'EarlyWithdrawal',bCenterPortIn,'EarlyWithdrawal',bRightPortIn,'EarlyWithdrawal'},...
        'OutputActions',{});
else

    sma = AddState(sma, 'Name', 'Sampling',...
        'Timer', TaskParameters.GUI.SampleTime,...
        'StateChangeConditions', {CenterPortOut, 'GracePeriod','Tup','wait_action','GlobalTimer1_End','wait_action'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'GracePeriod',...
        'Timer', TaskParameters.GUI.GracePeriod,...
        'StateChangeConditions', {CenterPortIn, 'Sampling','Tup','EarlyWithdrawal','GlobalTimer1_End','EarlyWithdrawal'...,
        bLeftPortIn,'EarlyWithdrawal',bCenterPortIn,'EarlyWithdrawal',bRightPortIn,'EarlyWithdrawal'},...
        'OutputActions',{});
end

%%
sma = AddState(sma, 'Name', 'wait_action',...
    'Timer',TaskParameters.GUI.ChoiceDeadline,...
    'StateChangeConditions', {operantAction,operantState},...
    'OutputActions',[{operantLight,255}, beep]);

sma = AddState(sma, 'Name', 'left_on',...
    'Timer',0,...
    'StateChangeConditions', {'Tup','wait_reward'},...
    'OutputActions',{'GlobalTimerTrig',2});

sma = AddState(sma, 'Name', 'center_on',...
    'Timer',0,...
    'StateChangeConditions', {'Tup','wait_reward'},...
    'OutputActions',{'GlobalTimerTrig',2});

sma = AddState(sma, 'Name', 'right_on',...
    'Timer',0,...
    'StateChangeConditions', {'Tup','wait_reward'},...
    'OutputActions',{'GlobalTimerTrig',2});

sma = AddState(sma, 'Name', 'wait_reward',...
    'Timer',BpodSystem.Data.rewardDelay(iTrial),...
    'StateChangeConditions', {'Tup',rewardState,'GlobalTimer2_End', rewardState, gracePokeOutAction, 'wait_reward_grace'},...
    'OutputActions',{});

sma = AddState(sma, 'Name', 'wait_reward_grace',...
    'Timer',TaskParameters.GUI.GracePeriod/2,...
    'StateChangeConditions', {'Tup','EarlyWithdrawal', 'GlobalTimer2_End', 'EarlyWithdrawal',gracePokeInAction,'wait_reward'},...
    'OutputActions',{});




%% Reward States

sma = AddState(sma, 'Name', 'bLeftPort_Reward',...
    'Timer',bLeftValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions',{'ValveState', bLeftValve});
sma = AddState(sma, 'Name', 'bCenterPort_Reward',...
    'Timer',bCenterValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions',{'ValveState', bCenterValve});
sma = AddState(sma, 'Name', 'bRightPort_Reward',...
    'Timer',bRightValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions',{'ValveState', bRightValve});

%% EndTrial States


sma = AddState(sma, 'Name', 'EarlyWithdrawal',...
    'Timer', TaskParameters.GUI.EarlyWithdrawalTimeOut,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {'SoftCode',PunishSoundAction});
if TaskParameters.GUI.VI
    sma = AddState(sma, 'Name', 'ITI',...
        'Timer',exprnd(TaskParameters.GUI.FI),...
        'StateChangeConditions',{'Tup','exit'},...
        'OutputActions',{});
else
    sma = AddState(sma, 'Name', 'ITI',...
        'Timer',TaskParameters.GUI.FI,...
        'StateChangeConditions',{'Tup','exit'},...
        'OutputActions',{});
end

end

function updateCustomDataFields(iTrial)
global BpodSystem
global TaskParameters
BpodSystem.Data.TrialTypes(iTrial)=1;
%% OutcomeRecord
statesThisTrial = BpodSystem.Data.RawData.OriginalStateNamesByNumber{iTrial}(BpodSystem.Data.RawData.OriginalStateData{iTrial});
BpodSystem.Data.Custom.ST(iTrial) = NaN;
BpodSystem.Data.Custom.MT(iTrial) = NaN;
BpodSystem.Data.Custom.DT(iTrial) = NaN;
BpodSystem.Data.Custom.GracePeriod(1:50,iTrial) = NaN(50,1);
if any(contains(statesThisTrial,'Sampling'))
    BpodSystem.Data.Custom.ST(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.Sampling(1,end) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.StartSampling(1,1); 
    
end

% Compute grace period:
if any(contains(statesThisTrial,'GracePeriod'))
    for nb_graceperiod =  1: size(BpodSystem.Data.RawEvents.Trial{iTrial}.States.GracePeriod,1)
        BpodSystem.Data.Custom.GracePeriod(nb_graceperiod,iTrial) = (BpodSystem.Data.RawEvents.Trial{iTrial}.States.GracePeriod(nb_graceperiod,2)...
            -BpodSystem.Data.RawEvents.Trial{iTrial}.States.GracePeriod(nb_graceperiod,1));
    end
end  


if any(contains(statesThisTrial,'bLeftPort_Reward'))
    BpodSystem.Data.Custom.ChoiceLCR(iTrial,:) = [1, 0, 0];
    BpodSystem.Data.Custom.MT(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.bLeftPort_Reward(1,1)-BpodSystem.Data.RawEvents.Trial{iTrial}.States.wait_action(1,end);
elseif  any(contains(statesThisTrial,'bCenterPort_Reward'))
    BpodSystem.Data.Custom.ChoiceLCR(iTrial,:) = [0, 1, 0];
    BpodSystem.Data.Custom.MT(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.bCenterPort_Reward(1,1)-BpodSystem.Data.RawEvents.Trial{iTrial}.States.wait_action(1,end);
elseif  any(contains(statesThisTrial,'bRightPort_Reward'))
    BpodSystem.Data.Custom.ChoiceLCR(iTrial,:) = [0, 0, 1];
    BpodSystem.Data.Custom.MT(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.bCenterPort_Reward(1,1)-BpodSystem.Data.RawEvents.Trial{iTrial}.States.wait_action(1,end);
elseif any(contains(statesThisTrial,'EarlyWithdrawal'))
    BpodSystem.Data.Custom.ChoiceLCR(iTrial,:) = [0, 0, 0];
    BpodSystem.Data.Custom.EarlyWithdrawal(iTrial) = true;
end



if any(contains(statesThisTrial,'bLeftPort_Reward'))
    BpodSystem.Data.Custom.Rewarded(iTrial) = true;

elseif any(contains(statesThisTrial,'bCenterPort_Reward'))
    BpodSystem.Data.Custom.Rewarded(iTrial) = true;
    
elseif any(contains(statesThisTrial,'bRightPort_Reward'))
    BpodSystem.Data.Custom.Rewarded(iTrial) = true;
else
    BpodSystem.Data.Custom.Rewarded(iTrial) = false;
end

if (sum(BpodSystem.Data.Custom.ChoiceLCR(iTrial,:)==BpodSystem.Data.Custom.LightOn(iTrial,:))==3)&& BpodSystem.Data.Custom.Rewarded(iTrial)
    BpodSystem.Data.Custom.Correct(iTrial) = true;
elseif (sum(BpodSystem.Data.Custom.ChoiceLCR(iTrial,:)==BpodSystem.Data.Custom.LightOn(iTrial,:))==3)
    BpodSystem.Data.Custom.Correct(iTrial) = true;
else
    BpodSystem.Data.Custom.Correct(iTrial) = false;
end

%% initialize next trial values
BpodSystem.Data.Custom.LightOn(iTrial+1,:)=datasample([1, 0,0;0,1,0; 0, 0, 1],1,1);

BpodSystem.Data.Custom.RewardMagnitude(iTrial+1,:) = [TaskParameters.GUI.rewardAmountL,TaskParameters.GUI.rewardAmountC...,
    TaskParameters.GUI.rewardAmountR];


BpodSystem.Data.Custom.ChoiceLMR(iTrial+1,:) = [NaN,NaN,NaN];
BpodSystem.Data.Custom.EarlyWithdrawal(iTrial+1) = false;
BpodSystem.Data.Custom.ST(iTrial+1) = NaN;
BpodSystem.Data.Custom.MT(iTrial+1) = NaN;
BpodSystem.Data.Custom.Rewarded(iTrial+1) = false;
BpodSystem.Data.Custom.GracePeriod(1:50,iTrial+1) = NaN(50,1);

BpodSystem.Data.Custom.RewardDelay(iTrial+1) = NaN;
BpodSystem.Data.Custom.Correct(iTrial+1) = NaN;
BpodSystem.Data.Custom.Rewarded(iTrial+1) = NaN;

%%REWARD

%% depletion
%if a random reward appears - it does not disrupt the previous depletion
%train and depletion is calculated by multiplying from the normal reward
%increase sample time
if TaskParameters.GUI.AutoIncrSample
    History = 50; % Rat: History = 50
    Crit = 0.8; % Rat: Crit = 0.8
    if iTrial<5
        ConsiderTrials = iTrial;
    else
        ConsiderTrials = max(1,iTrial-History):1:iTrial;
    end
    ConsiderTrials = ConsiderTrials(~isnan(BpodSystem.Data.Custom.Correct(ConsiderTrials))|BpodSystem.Data.Custom.EarlyWithdrawal(ConsiderTrials));
    if sum(~BpodSystem.Data.Custom.EarlyWithdrawal(ConsiderTrials))/length(ConsiderTrials) > Crit % If SuccessRate > crit (80%)
        if ~BpodSystem.Data.Custom.EarlyWithdrawal(iTrial) % If last trial is not EWD
            BpodSystem.Data.Custom.SampleTime(iTrial+1) = min(TaskParameters.GUI.MaxSampleTime,max(TaskParameters.GUI.MinSampleTime,BpodSystem.Data.Custom.SampleTime(iTrial) + TaskParameters.GUI.MinSampleIncr)); % SampleTime increased
        else % If last trial = EWD
            BpodSystem.Data.Custom.SampleTime(iTrial+1) = min(TaskParameters.GUI.MaxSampleTime,max(TaskParameters.GUI.MinSampleTime,BpodSystem.Data.Custom.SampleTime(iTrial))); % SampleTime = max(MinSampleTime or SampleTime)
        end
    elseif sum(~BpodSystem.Data.Custom.EarlyWithdrawal(ConsiderTrials))/length(ConsiderTrials) < Crit/2  % If SuccessRate < crit/2 (40%)
        if BpodSystem.Data.Custom.EarlyWithdrawal(iTrial) % If last trial = EWD
            BpodSystem.Data.Custom.SampleTime(iTrial+1) = max(TaskParameters.GUI.MinSampleTime,min(TaskParameters.GUI.MaxSampleTime,BpodSystem.Data.Custom.SampleTime(iTrial) - TaskParameters.GUI.MinSampleDecr)); % SampleTime decreased
        else
            BpodSystem.Data.Custom.SampleTime(iTrial+1) = min(TaskParameters.GUI.MaxSampleTime,max(TaskParameters.GUI.MinSampleTime,BpodSystem.Data.Custom.SampleTime(iTrial))); % SampleTime = max(MinSampleTime or SampleTime)
        end
    else % If crit/2 < SuccessRate < crit
        BpodSystem.Data.Custom.SampleTime(iTrial+1) =  BpodSystem.Data.Custom.SampleTime(iTrial); % SampleTime unchanged
    end
else
    BpodSystem.Data.Custom.SampleTime(iTrial+1) = TaskParameters.GUI.MinSampleTime;
end

TaskParameters.GUI.SampleTime = BpodSystem.Data.Custom.SampleTime(iTrial+1); % update SampleTime

%send bpod status to server
% try
% script = 'receivebpodstatus.php';
% %create a common "outcome" vector
% outcome = BpodSystem.Data.Custom.ChoiceLeft(1:iTrial); %1=left, 0=right
% outcome(BpodSystem.Data.Custom.EarlyWithdrawal(1:iTrial))=3; %early withdrawal=3
% outcome(BpodSystem.Data.Custom.Jackpot(1:iTrial))=4;%jackpot=4
% SendTrialStatusToServer(script,BpodSystem.Data.Custom.Rig,outcome,BpodSystem.Data.Custom.Subject,BpodSystem.CurrentProtocolName);
% catch
% end

end