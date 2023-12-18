classdef octaveFilterBankTest < audioPlugin
    properties (Access = private)
        pOctFilterBank =octaveFilterBank("1 octave", 44100, ...
            FrequencyRange=[20 22000]);
    end
    methods
        function out = process(plugin, in)
            in = sum(in,2)/2;
            inFiltered = plugin.pOctFilterBank(in);
            out = inFiltered(:,6,:);
        end
    end
end
