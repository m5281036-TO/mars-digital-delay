classdef delayTest < audioPlugin
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
        pFractionalDelay
        pOctFiltBank
        pSR % sample rate
    end
    methods
        % ----constructor----
        function plugin = delayTest
            plugin.pSR = getSampleRate(plugin);
            fs = plugin.pSR;
            plugin.pFractionalDelay = dsp.VariableFractionalDelay(...
                'MaximumDelay',4000);

            % ----ocatave filter bank----
            plugin.pOctFiltBank = octaveFilterBank('SampleRate', fs, FrequencyRange=[18 22000]);
            % ------------
        end

        % ----main----
        function out = process(plugin, in)
            % config
            fs = plugin.pSR;
            frameSize = length(in);

            % set input signal to mono
            inMono = sum(in,2)/2;


            % % ----delay----
            % % define the number of delay samples
            % delaySamples = round(plugin.Distance * 10);
            % 
            % %buffer sizeの定義
            % buffSize = 10000;
            % 
            % if delaySamples > buffSize % delay samples must not exceed frame size
            %     delaySamples = buffSize - frameSize;
            % end
            % 
            % %永続変数としてbuffを定義
            % persistent buff
            % 
            % %buffの初期化
            % if isempty(buff)
            %     buff = zeros(buffSize,1);
            % end
            % 
            % %buffをframe_size分動かす
            % buff(frameSize+1:buffSize)=buff(1:buffSize-frameSize);
            % 
            % %現在の入力信号をbuffの先頭に保存
            % buff(1:frameSize)=flip(inMono);
            % 
            % %tサンプル前の音を取り出す
            % inDelayed = flip(buff(delaySamples+1:delaySamples+frameSize));
            % 
            % % -------------------------

            % ----main process----
            if plugin.Enable
                % out = reconstructedAudio;
                out = delaySignal(plugin,inMono,frameSize)*0.6 + inMono*0.4;
            else % bypass
                out = in;
            end
            % --------------------
        end

        % ---reset----
        % when sampling rate changes
        function reset(plugin)
            % plugin.pFractionalDelay.SampleRate = getSampleRate(plugin);
            reset(plugin.pFractionalDelay);
        end

        %----delay function----
        function delayOut = delaySignal(plugin,in,frameSize)
            delaySamples = round(plugin.Distance * 10);

            %buffer sizeの定義
            buffSize = 10000;

            if delaySamples > buffSize % delay samples must not exceed frame size
                delaySamples = buffSize - frameSize;
            end

            %永続変数としてbuffを定義
            persistent buff

            %buffの初期化
            if isempty(buff)
                buff = zeros(buffSize,1);
            end

            %buffをframe_size分動かす
            buff(frameSize+1:buffSize)=buff(1:buffSize-frameSize);

            %現在の入力信号をbuffの先頭に保存
            buff(1:frameSize)=flip(in);

            %tサンプル前の音を取り出す
            inDelayed = flip(buff(delaySamples+1:delaySamples+frameSize));

            delayOut = inDelayed;
        end
        % ----delay end----

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