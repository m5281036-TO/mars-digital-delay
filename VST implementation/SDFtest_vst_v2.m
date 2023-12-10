classdef SDFtest_vst_v2 < audioPlugin
    properties
        Freq_F1 = sqrt(20*500)
        Speed_F1 = 0
        Freq_F2 = sqrt(3e3*20e3)
        Speed_F2 = 0
        Distance = 1
        DelayMode = 'Linear'
        Enable = true
    end
    properties (Constant)
        PluginInterface = audioPluginInterface( ...
            audioPluginParameter('Freq_F1', ...
            'Label','Hz', ...
            'Mapping',{'log',20,2200}), ...
            audioPluginParameter('Speed_F1', ...
            'Label','m/s', ...
            'Mapping',{'lin',-20,20}), ...
            audioPluginParameter('Freq_F2', ...
            'Label','Hz', ...
            'Mapping',{'log',2201,22000}), ...
            audioPluginParameter('Speed_F2', ...
            'Label','m/s', ...
            'Mapping',{'lin',-20,20}), ...
            audioPluginParameter('Distance', ...
            'DisplayName', 'Distance', ...
            'Label', 'm', ...
            'Mapping',{'log',0.1,10000}, ...
            'Style','hslider'), ...
            audioPluginParameter('DelayMode', ...
            'DisplayName', 'Delay Mode', ...
            'Mapping',{'enum','Linear', 'Logarithmic', 'Sigmoid', 'Stepwise'}), ...
            audioPluginParameter('Enable'))
    end
    properties (Access = private)
        pSpectralDelay
        pOctFiltBank
        pSR % sample rate
    end
    methods
        % ----constructor----
        function plugin = SDFtest_vst_v2
            fs = getSampleRate(plugin);
            plugin.pSpectralDelay = dsp.VariableFractionalDelay(...
                'MaximumDelay',65000);

            % ----ocatave filter bank----
            plugin.pOctFiltBank = octaveFilterBank('SampleRate', 441000, FrequencyRange=[18 22000]);
            % ------------

            plugin.pSR = fs;
        end
        % ----main----
        function out = process(plugin, in)
            % config
            fs = plugin.pSR;
            inMono = sum(in,2)/2; % set input signal to mono
            
            % ocatave filtering
            filterOut = plugin.pOctFiltBank(inMono);
            [N, numFilters, numChannels] = size(filterOut);

            

            % ----delaying the signal here----
            delaySamples = round(plugin.Distance * fs / 340); % [samples]
            delayVector = [delaySamples delaySamples]; %
            %--------------

            % main process
            if plugin.Enable
                %out = plugin.pSpectralDelay(in,delayVector);
                num = round (plugin.Distance);
                out = filterOut(:,num,:);
            else % bypass
                out = in;
            end
        end
        % ---reset----
        % when sampling rate changes
        function reset(plugin)
            % plugin.pSpectralDelay.SampleRate = getSampleRate(plugin);
            reset(plugin.pSpectralDelay);
        end
        % ----parameter modification----
        % function set.Freq_F1(plugin,val)
        %     plugin.Freq_F1 = val;
        %     plugin.mPEQ.Frequencies(1) = val; %#ok<*MCSUP>
        % end
        % function set.Speed_F1(plugin,val)
        %     plugin.Speed_F1 = val;
        %     plugin.mPEQ.PeakGains(1) = val;
        % end
        % function set.Freq_F2(plugin,val)
        %     plugin.Freq_F2 = val;
        %     plugin.mPEQ.Frequencies(3) = val;
        % end
        % function set.Speed_F2(plugin,val)
        %     plugin.Speed_F2 = val;
        %     plugin.mPEQ.PeakGains(3) = val;
        % end
        function set.Distance (plugin, val)
            plugin.Distance = val;
        end
    end
end