classdef spectralDelayFilter_vst < audioPlugin
    properties
        %LPControl Lowpass filter control signal type
        %   Specify the control signal for your lowpass filter as none,
        %   sine, sawtooth, square, or drawn. If you specify drawn, the
        %   control signal is determined by a wavetableSynthesizer, with
        %   the Wavetable property set to the oscillation drawn using the
        %   drawOscillation method.
        %   The default is none. This property is tunable.
        
        LPControl = audioexample.LFOFilterControlEnum.none;
        %Frequency Frequency of oscillation
        %   Specify the frequency of the control signal in the range 1 to 20.
        %   The default is 2. This property is tunable.
        Frequency = 2;
        
        %Range Range of oscillation
        %   Specify the range of the control signal between 0.1 to 0.8. The
        %   control signal amplitude is determined as 
        %   Amplitude = (DCOffset)*(Range). DC offset is determined by the
        %   Center property.
        %   The default is 0.5. This property is tunable.
        Range = 0.5;
        
        %Center Center of oscillation
        %   Specify the center of the oscillation in the range 0.002 to
        %   0.08. The center of the oscillation corresponds to the DC
        %   offset of the control signal.  The range 0.002 to 0.08
        %   corresponds to a normalized frequency spectrum.
        %   The default is 0.05. This property is tunable.
        Center = 0.05;
        
        %QFactor Q of lowpass filter
        %   Specify the Q of the lowpass filter in the range 0.1 to 20.
        %   The default is sqrt(2). This property is tunable.
        QFactor = sqrt(2);
    end
    
    %----------------------------------------------------------------------
    % PRIVATE PROPERTIES : Used for internal processing and storage 
    %----------------------------------------------------------------------
    properties (Access=private)
        LowpassFilter
        Sinusoid
        Square
        Sawtooth

    end
    
    %----------------------------------------------------------------------
    % HIDDEN PROPERTIES: Properties accessed outside of plugin, but not
    % visible to user
    %----------------------------------------------------------------------
    properties (Hidden)
        visualObj
        plotHandle
        WT
    end
    
    %----------------------------------------------------------------------
    % CONSTANT PROPERTIES : These properties define the interface between
    % generated plugin, DAW, and end-user
    %----------------------------------------------------------------------
    properties (Constant)
        PluginInterface = audioPluginInterface(...
            audioPluginParameter('LPControl',...
                'DisplayName','Delay Type',...
                'Mapping',{'enum','none','linear','logarithm','square'}, ...
                'Layout', [5 1; 5 2]),...
            audioPluginParameter('Frequency',...
                'DisplayName','Speed of Sound',...
                'Label','m/s',...
                'Mapping',{'lin',1,20}, ...
                'Style','rotaryknob','Layout',[3, 1]),...
            audioPluginParameter('Range',...
                'DisplayName','Freq. 1',...
                'Label','Hz',...
                'Mapping',{'lin',0.1,0.8}, ...
                'Style','rotaryknob','Layout',[1, 1]),...
            audioPluginParameter('Center',...
                'DisplayName','Freq. 2',...
                'Label','Hz',...
                'Mapping',{'log',0.002,0.08}, ...
                'Style','rotaryknob','Layout',[1, 2]),...
            audioPluginParameter('QFactor',...
                'DisplayName','Speed of Sound',...
                'Label','m/s',...
                'Mapping',{'log',0.1,20}, ...
                'Style','rotaryknob','Layout',[3, 2]),...
                audioPluginGridLayout('RowHeight', [100 20 100 20 30 20], ...
                'ColumnWidth', [100 100], 'Padding', [10 10 10 30]), ...
            'BackgroundImage', audiopluginexample.private.mwatlogo, ...
            'PluginName','spectralDelayFilter',...
            'InputChannels',2,...
            'OutputChannels',2);
    end
    
    %----------------------------------------------------------------------
    % PUBLIC METHODS : Main processing algorithms
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        % Constructor: Construct objects used in processing. This function
        % is called when the plugin is first initialized in a DAW
        % environment.
        %------------------------------------------------------------------
        function plugin = spectralDelayFilter_vst
            plugin.LowpassFilter = dsp.SOSFilter(...
                'Structure','Direct form I',...
                'CoefficientSource','Input port',...
                'HasScaleValues',false);
            
            plugin.Sinusoid = audioOscillator('SignalType','sine',...
                'Frequency',2,'DCOffset',0.05);
            plugin.Sawtooth = audioOscillator('SignalType','sawtooth',...
                'Frequency',2,'DCOffset',0.05);
            plugin.Square = audioOscillator('SignalType','square',...
                'Frequency',2,'DCOffset',0.05);
            
            plugin.WT = wavetableSynthesizer('Wavetable',0.1*ones(50,1),...
                'Frequency',1);
        end
        function out = process(plugin,in)
            %process Apply low frequency oscillation
            %	y = process(LFO,x) applies specified low frequency
            %   oscillation to the lowpass filter cutoff frequency.
            %   Properties of the plugin determine the type of low
            %   frequency oscillation applied.
            %
            [frameSize,~] = size(in);
            updateFrameSize(plugin,frameSize);
            
            out = applyLFO(plugin,in);
        end
        function drawOscillation(plugin)
            %drawOscillation Open figure to draw oscillation contour
            %    drawOscillation(LFO) opens a user interface for you to draw
            %    an oscillation contour. The oscillation contour is saved as
            %    a wavetable for use with the wavetableSynthesizer System
            %    object.  You can adjust the contour in real-time while the
            %    LFO is running.
            %    This method is only available in the MATLAB environment.
            %    The drawn control signal default is a constant 0.1 value.
            % 
            if isempty(coder.target)
                audioexample.LFOFilterDraw(plugin)
            end
        end
    function reset(plugin)
           Fs = getSampleRate(plugin);
           plugin.Sinusoid.SampleRate = Fs;
           plugin.Sawtooth.SampleRate = Fs;
           plugin.Square.SampleRate   = Fs;
           plugin.WT.SampleRate       = Fs;
           
           updateFrequency(plugin,plugin.Frequency)
           updateDCOffset(plugin,plugin.Center)
           updateControlAmplitude(plugin)
    end
    function s = saveobj(obj)
        s = saveobj@audioPlugin(obj);
        s.LowpassFilter = matlab.System.saveObject(obj.LowpassFilter);
        s.Sinusoid = matlab.System.saveObject(obj.Sinusoid);
        s.Square = matlab.System.saveObject(obj.Square);
        s.Sawtooth = matlab.System.saveObject(obj.Sawtooth);
        s.WT = matlab.System.saveObject(obj.WT);
        s.LPControl = obj.LPControl;
        s.Frequency = obj.Frequency;
        s.Range = obj.Range;
        s.Center = obj.Center;
        s.QFactor = obj.QFactor;
    end
    function obj = reload(obj,s)
        obj = reload@audioPlugin(obj,s);
        obj.LPControl = s.LPControl;
        obj.Frequency = s.Frequency;
        obj.Range = s.Range;
        obj.Center = s.Center;
        obj.QFactor = s.QFactor;
        obj.LowpassFilter = matlab.System.loadObject(s.LowpassFilter);
        obj.Sinusoid = matlab.System.loadObject(s.Sinusoid);
        obj.Square = matlab.System.loadObject(s.Square);
        obj.Sawtooth = matlab.System.loadObject(s.Sawtooth);
        obj.WT = matlab.System.loadObject(s.WT);
    end
    end
    
    %----------------------------------------------------------------------
    % PRIVATE METHODS : Perform processing calculations
    %----------------------------------------------------------------------   
    methods (Access = private)
        function out = applyLFO(plugin,in)           
            if isempty(coder.target)
                if plugin.LPControl == audioexample.LFOFilterControlEnum.drawn
                    drawOscillation(plugin)
                end
            end
            
            sinWave = step(plugin.Sinusoid);
            sawWave = step(plugin.Sawtooth);
            sqrWave = step(plugin.Square);
            drwWave = step(plugin.WT);
            
            switch plugin.LPControl
                case audioexample.LFOFilterControlEnum.sine
                    cutoff = sinWave;
                case audioexample.LFOFilterControlEnum.sawtooth
                    cutoff = sawWave;
                case audioexample.LFOFilterControlEnum.square
                    cutoff = sqrWave;
                otherwise % case audioexample.LFOFilterControlEnum.none
                    cutoff = 1;
            end
            
            if cutoff ==1
                out = in;
            else
                [B,A] = designLPFilter(plugin,cutoff(end));
                out   = step(plugin.LowpassFilter,in,B,A);
            end
        end
        function [b,a] = designLPFilter(plugin,fc)
            % Reference:
            % http://www.musicdsp.org/files/Audio-EQ-Cookbook.txt
            Q = plugin.QFactor;
            
            w0 = 2*pi*fc;
            alpha = sin(w0)/(2*Q);
            
            b1 =  1 - cos(w0);
            a0 =  1 + alpha;
            a1 = -2 * cos(w0);
            a2 =  1 - alpha;
            
            b1 = b1 / a0;
            b0 = b1 / 2;
            a1 = a1 / a0;
            a2 = a2 / a0;
            
            b = [b0 b1 b0];
            a = [1 a1 a2];
        end
    end
    
    %----------------------------------------------------------------------
    % PUBLIC METHODS : Listeners for plugin property/parameter changes
    % (specified by end-user)
    %----------------------------------------------------------------------
    methods
       function set.Frequency(plugin,val)
           plugin.Frequency = val;
           updateFrequency(plugin,val)
       end
       function set.Center(plugin,val)
           plugin.Center = val;
           updateDCOffset(plugin,val)
           updateControlAmplitude(plugin)
       end
       function set.Range(plugin,val)
           plugin.Range = val;
           updateControlAmplitude(plugin)
       end
    end
    
    %----------------------------------------------------------------------
    % PRIVATE METHODS : Update properties of control signals
    %----------------------------------------------------------------------
    methods (Access = private)
        function updateFrequency(plugin,val)
            plugin.Sinusoid.Frequency    	= val;
            plugin.Square.Frequency       	= val;
            plugin.Sawtooth.Frequency     	= val;
            plugin.WT.Frequency           	= val;
        end
        function updateDCOffset(plugin,val)
            plugin.Sinusoid.DCOffset     	= val;
            plugin.Square.DCOffset          = val;
            plugin.Sawtooth.DCOffset      	= val;
        end
        function updateFrameSize(plugin,val)
            plugin.Sinusoid.SamplesPerFrame	= val;
            plugin.Sawtooth.SamplesPerFrame	= val;
            plugin.Square.SamplesPerFrame  	= val;
            plugin.WT.SamplesPerFrame      	= val;
        end
        function updateControlAmplitude(plugin)
            controlSignalAmplitude         	= plugin.Range*plugin.Center;
            plugin.Sinusoid.Amplitude      	= controlSignalAmplitude;
            plugin.Square.Amplitude        	= controlSignalAmplitude;
            plugin.Sawtooth.Amplitude      	= controlSignalAmplitude;
        end
    end

    methods(Static)
        function obj = loadobj(s)
            if isstruct(s)
                obj = audiopluginexample.spectralDelayFilter;
                obj = reload(obj,s);
            end
        end
    end
end