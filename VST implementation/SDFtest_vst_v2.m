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
        pSR
        pOctFiltBank
    end
    methods
        % --------constructor---------
        function plugin = SDFtest_vst_v2
            % get sample rate of input
            plugin.pSR = getSampleRate(plugin);
            fs = plugin.pSR;
            
            % ocatave filter bank
            plugin.pOctFiltBank = octaveFilterBank('SampleRate', fs, FrequencyRange=[18 22000]);
        end
        % ----------------------------

        % --------main function--------
        function out = process(plugin, in)
            % config
            fs = plugin.pSR;
            frameSize = length(in);
            
            % set input signal to mono
            inMono = sum(in,2)/2;
            
            % octave filterring
            inFiltered = plugin.pOctFiltBank(inMono);
            [~, numFilters, ~] = size(inFiltered); % [number of samples, number of bands, number of channels]
             
            % initialize inDelayFiltered
            inDelayFiltered = zeros(size(inFiltered));

            % --------delay signal in each channel--------
            for i = 1 : numFilters
                % inDelayFiltered = delaySignal(plugin,inMono,frameSize);
                delaySamples = i * round(plugin.Distance);
                inDelayFiltered(:,i,:) = delaySignal(plugin,inFiltered(:,i,:),frameSize,delaySamples,numFilters,i);
            end
            %---------------------------------------------

            % --------reconstract audio--------
            reconstructedAudio = squeeze(sum(inDelayFiltered, 2));
            % reconstructedAudio = reconstructedAudio/max(abs(reconstructedAudio(:))); % normalization
            % ---------------------------------

            % --------main process---------
            if plugin.Enable
                out = reconstructedAudio;
            else % bypass
                out = in;
            end
            % -----------------------------
        end

        % --------reset when sampling rate changes--------
        function reset(plugin)
            % plugin.pFractionalDelay.SampleRate = getSampleRate(plugin);
            % reset(plugin.pFractionalDelay);
        end
        % ------------------------------------------------

        % --------delay function--------
        function delayOut = delaySignal(~,in,frameSize,delaySamples,numFilters,i)
            
            %buffer sizeの定義
            buffSize = 661500; % maximum 15sec in fs=44100

            if delaySamples > buffSize - frameSize % delay samples must not exceed frame size
                delaySamples = buffSize - frameSize;
            end

            %永続変数としてbuffを定義
            persistent buff

            % buffの初期化 numFiltersの数だけbuffを用意する
            if isempty(buff)
                buff = zeros(buffSize,numFilters);
            end

            %buffをframe_size分動かす
            buff(frameSize+1:buffSize,i)=buff(1:buffSize-frameSize,i);

            %現在の入力信号をbuffの先頭に保存
            buff(1:frameSize,i)=flip(in);

            %tサンプル前の音を取り出す
            delayOut = flip(buff(delaySamples+1:delaySamples+frameSize,i));
        end
        % ------------------------------

        % --------parameter modification--------
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