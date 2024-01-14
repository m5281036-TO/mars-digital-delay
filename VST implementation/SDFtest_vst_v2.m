classdef SDFtest_vst_v2 < audioPlugin
    properties
        Freq_F1 = 200;
        Freq_F2 = 2000;
        Speed_F1 = 340;
        Speed_F2 = 680;
        Distance = 50;
        DelayMode = OperatingMode.linear;
        Enable = true;
    end


    properties (Constant)
        PluginInterface = audioPluginInterface( ...
            'PluginName','Mars Spectral Delay', ...
            'VendorName', 'Takuto Odaira', ...
            'VendorVersion', '1.0.1', ...
            audioPluginParameter('Freq_F1', ... % Freq_F1
            'Label','Hz', ...
            'Mapping',{'log',20,22000}, ...
            'Style','rotaryknob', ...
            'DisplayName','Freq', ...
            'Layout',[5,1;7,1]), ...
            audioPluginParameter('Freq_F2', ...% Freq_F2
            'Label','Hz', ...
            'Mapping',{'log',20,22000}, ...
            'Style','rotaryknob', ...
            'DisplayName','Freq', ...
            'Layout',[5,2;7,2]), ...
            audioPluginParameter('Speed_F1', ... % Speed_F1
            'Label','m/s', ...
            'Mapping',{'lin',40,1200}, ...
            'Style','vslider', ...
            'DisplayName','Frequency1','DisplayNameLocation','Above', ...
            'Layout',[2,1;4,1]), ...
            audioPluginParameter('Speed_F2', ... % Speed_F2
            'Label','m/s', ...
            'Mapping',{'lin',40,1200}, ...
            'Style','vslider', ...
            'DisplayName','Frequency2','DisplayNameLocation','Above', ...
            'Layout',[2,2;4,2]), ...
            audioPluginParameter('Distance', ... % Distance
            'Label', 'm', ...
            'Mapping',{'log',0.1,4000}, ...
            'Style','rotaryknob', ...
            'DisplayName','Distance','DisplayNameLocation','Above', ...
            'Layout',[3,3;4,3]), ...
            audioPluginParameter('DelayMode', ...% DelayMode
            'Mapping',{'enum','Linear','Linear (non-freqency-related)', 'Logarithmic', 'Sigmoid', 'Stepwise', 'none'}, ...
            'DisplayName','Delay Mode','DisplayNameLocation','Above', ...
            'Layout',[6,3;7,3]), ...
            audioPluginParameter('Enable', ... % Enable
            'DisplayName','Plugin Enable', ...
            'Layout',[8,3]), ...
            audioPluginGridLayout( ...
            'RowHeight',[20,20,180,20,20,40,30,40,40], ...
            'ColumnWidth',[130,130,170]) ...
            );
    end


    properties (Access = private)
        pSR
        pOctFiltBank
        pCf
    end


    methods
        % --------constructor---------
        function plugin = SDFtest_vst_v2
            % get sample rate of input
            plugin.pSR = getSampleRate(plugin);
            fs = plugin.pSR;

            % filtering via ocatave filter bank
            plugin.pOctFiltBank = octaveFilterBank("1 octave", fs, ...
                FrequencyRange=[20 22000]);
        end
        % ----------------------------


        % ----------------------------------------
        % main function
        % ----------------------------------------
        function out = process(plugin, in)
            % get sampling rate
            fs = plugin.pSR;

            % size(in) = [frame_length number_of_channels]
            frameSize = size(in,1);
            numChannels = size(in, 2);

            % config
            speed1 = plugin.Speed_F1;
            speed2 = plugin.Speed_F2;
            freq1 = plugin.Freq_F1;
            freq2 = plugin.Freq_F2;
            dist = plugin.Distance;
            modeNum = getOperatingnMode(plugin);


            % set input signal to monoral
            inMono = sum(in,numChannels)/numChannels;
            oRMS = rms(inMono);


            % --------octave filtering--------
            inFiltered = plugin.pOctFiltBank(inMono);
            [~, numFilters, ~] = size(inFiltered); % [number of samples, number of bands, number of channels]

            % center freq. of each band in octave filter bank
            cf = getCenterFrequencies(plugin.pOctFiltBank);
            % --------------------------------


            % initialize array for filtered & delayed input signal
            inDelayFiltered = zeros(size(inFiltered));


            % --------delay signal in each channel--------
            for i = 1 : numFilters
                % delaySamples = i * round(plugin.Distance);
                delaySamples = getDelaySamples(plugin,fs,numFilters,speed1,speed2,freq1,freq2,dist,modeNum,cf(i),i);
                if delaySamples ~= 0 % delay signal except when 0
                    inDelayFiltered(:,i,:) = delaySignal(plugin,inFiltered(:,i,:),frameSize,delaySamples,numFilters,i);
                end
            end

            %---------------------------------------------


            % --------reconstract audio--------
            % reconstruction
            reconstructedAudio = squeeze(sum(inDelayFiltered, 2));

            % normalization
            % normalizedAudio = normalizeSignal(plugin,reconstructedAudio);
            % ---------------------------------


            % --------output signal---------
            if plugin.Enable
                out = [reconstructedAudio reconstructedAudio];
            else % bypass
                out = [inMono inMono]; % output is monaural
            end
            % -------------------------------
        end
        % ----------------------------------------
        % main function end
        % ----------------------------------------



        % --------reset when sampling rate changes--------
        function reset(plugin)
            fs = getSampleRate(plugin);
            plugin.pSR = fs;
            plugin.pOctFiltBank.SampleRate = getSampleRate(plugin);
            reset(plugin.pOctFiltBank);
        end
        % ------------------------------------------------


        % --------delay function--------
        function delayOut = delaySignal(~,in,frameSize,delaySamples,numFilters,i)

            % define buffSize -- this affects maximum size of delaySamples
            buffSize = 100000; % ≈ 2.26sec

            % make sure that delaySamples does not exceed frameSize
            if delaySamples > buffSize - frameSize
                delaySamples = buffSize - frameSize;
            end

            % define buff as persistent variable
            persistent buff

            % initialize buff -- prepare buff as many as numFilters
            if isempty(buff)
                buff = zeros(buffSize,numFilters);
            end

            % move buff for the size of frameSize
            buff(frameSize+1:buffSize,i)=buff(1:buffSize-frameSize,i);

            % save current input signal at the front of buff
            buff(1:frameSize,i)=flip(in);

            % extract the signal t samples before
            delayOut = flip(buff(delaySamples+1:delaySamples+frameSize,i));
        end
        % ------------------------------


        % --------get value of delaySamples for each band--------
        function s = getDelaySamples(~,fs,numFilters,speed1,speed2,freq1,freq2,dist,modeNum,iCf,i)
            % initilize output
            s = 0;

            % bypass -- when freq1 and freq2 is at the smaepotion, s is constant in each filter channel
            if freq1 == freq2
                s = round(dist / speed1 * fs);

            else % when speed1 ~= speed2
                % linear
                if modeNum == 0
                    iSpeed = iCf * abs(speed1-speed2) / abs(freq1-freq2);
                    iSpeed = max(iSpeed,1); % make sure iSpeed does not become too small
                    s = round(dist / iSpeed * fs);

                    % linear (non-freqency-related) -- only depends on two speeds of sounds
                elseif modeNum == 1
                    s = round(dist / abs(speed1-speed2) / numFilters * i  * fs);

                    % logarithmic (base of 2) ==== developing ====
                elseif modeNum == 2
                    iSpeed = iCf * (log2(freq1)-log2(freq2)) / abs(freq1-freq2);
                    iSpeed = max(iSpeed,1);
                    s = round(dist / iSpeed * fs);

                    % sigmoid ==== developing ====
                elseif modeNum == 3
                    p = abs(freq1 - freq2) / 2;
                    r = abs(speed1 - speed2);
                    iSpeed = iCf * abs((sin(iCf/p*pi) - (sin(iCf/p*pi)) * r)) / abs(freq1-freq2);
                    s = round(dist / iSpeed * fs);

                    % stepwise -- only has 2 speeds of sounds devided by median of 2 freqencies
                elseif modeNum == 4
                    if iCf >= median([freq1 freq2])
                        if freq1 >= freq2
                            s = round(dist / speed1 * fs); % fit to the speed of the higher frequency
                        else
                            s = round(dist / speed2 * fs); % fit to the speed of the lower frequency
                        end
                    else % iCf < median([freq1 freq2])
                        if freq1 >= freq2
                            s = round(dist / speed2 * fs); % fit to the speed of the lower frequency
                        else
                            s = round(dist / speed1 * fs); % fit to the speed of the higher frequency
                        end
                    end
                elseif modeNum == 5 % none
                    s = 0;
                end
            end

        end
        %----------------------------------------------------


        % --------signal normalize--------
        function normalizedAudio = normalizeSignal(~,in)
            normalizedAudio = in * max(abs(in));
        end
        % --------------------------------


        % --------get DelayMode from 'OpreratingMode.m'--------
        function modeNum = getOperatingnMode(plugin)
            modeNum = 0; % initialize
            switch plugin.DelayMode
                case OperatingMode.linear
                    modeNum = 0;
                case OperatingMode.linear2
                    modeNum = 1;
                case OperatingMode.logarithmic
                    modeNum = 2;
                case OperatingMode.sigmoid
                    modeNum = 3;
                case OperatingMode.stepwise
                    modeNum = 4;
            end
        end
        % -----------------------------------------------------


        % --------parameter modification--------
        % function set.Freq_F1(plugin,val)
        %     plugin.Freq_F1 = val;
        % end
        % function set.Freq_F2(plugin,val)
        %     plugin.Freq_F2 = val;
        % end
        % function set.Speed_F1(plugin,val)
        %     plugin.Speed_F1 = val;
        % end
        % function set.Speed_F2(plugin,val)
        %     plugin.Speed_F2 = val;
        % end
        % function set.Distance (plugin, val)
        %     plugin.Distance = val;
        % end
    end
end