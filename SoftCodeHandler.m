function SoftCodeHandler(softCode)
%soft code 11-20 reserved for PulsePal sound delivery

global BpodSystem

if softCode > 10 && softCode < 21 %for auditory clicks
    if ~BpodSystem.EmulatorMode
        if softCode == 11 %noise on chan 1
            ProgramPulsePal(BpodSystem.Data.Custom.PulsePalParamFeedback);
            SendCustomPulseTrain(1,cumsum(randi(9,1,601))/10000,(rand(1,601)-.5)*20); % White(?) noise on channel 1+2
            SendCustomPulseTrain(2,cumsum(randi(9,1,601))/10000,(rand(1,601)-.5)*20);
            TriggerPulsePal(1,2);
            ProgramPulsePal(BpodSystem.Data.Custom.PulsePalParamStimulus);
        elseif softCode == 12 %beep on chan 2
            ProgramPulsePal(BpodSystem.Data.Custom.PulsePalParamFeedback);
            SendCustomPulseTrain(2,0:.00:.3,(ones(1,301)*3));  % Beep on channel 1+2
            SendCustomPulseTrain(1,0:.001:.3,(ones(1,301)*3));
            TriggerPulsePal(1,2);
            ProgramPulsePal(BpodSystem.Data.Custom.PulsePalParamStimulus);
            
        elseif softCode==15 %highest beep corresponds to largest reward
            ProgramPulsePal(BpodSystem.Data.Custom.PulsePalParamFeedback);
            SendCustomPulseTrain(2,0:.0004:.3,(ones(1,751)*3));  % Beep on channel 1+2
            SendCustomPulseTrain(1,0:.0004:.3,(ones(1,751)*3));  % Beep on channel 1+2
            TriggerPulsePal(1,2);
            
        elseif softCode==14 
            ProgramPulsePal(BpodSystem.Data.Custom.PulsePalParamFeedback);
            SendCustomPulseTrain(2,0:.0006:.3,(ones(1,501)*3));  % Beep on channel 1+2
            SendCustomPulseTrain(1,0:.0006:.3,(ones(1,501)*3));
            TriggerPulsePal(1,2);
            
        elseif softCode==13
            ProgramPulsePal(BpodSystem.Data.Custom.PulsePalParamFeedback);
            SendCustomPulseTrain(2,0:.0009:.3,(ones(1,334)*3));  % Beep on channel 1+2
            SendCustomPulseTrain(1,0:.0009:.3,(ones(1,334)*3));
            TriggerPulsePal(1,2);
         
        end
    end
end

if softCode > 20 && softCode < 31 %for auditory freq
    if softCode == 21 
        if BpodSystem.Data.Custom.PsychtoolboxStartup
            PsychToolboxSoundServer('Play', 1);
        end
    end
    if softCode == 22
        if BpodSystem.Data.Custom.PsychtoolboxStartup
            PsychToolboxSoundServer('Stop', 1);
        end
    end    
end

end

