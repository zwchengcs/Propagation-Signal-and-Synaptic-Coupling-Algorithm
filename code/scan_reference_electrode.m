function CandidateCohorts = scan_reference_electrode(spike_times, thres_freq, seconds_recording, thres_number_spikes, ratio)
% This function generates cell array containing candidate electrode cohorts
% for each electrode. Each cell corresponds to an electrode with the same 
% order of your input. If a cell is empty, there's no electrode cohorts 
% associated with this electrode. Use rescan_each_reference to find 
% constituent electrodes from candidate electrode cohorts.
% 
%   Inputs:
%       spike_times:
%           1 x N cell. N cells represent N electrodes. Each cell contains 
%           a 1 x m vector representing the spike times for each electrode.
%           The spike times should be in units of ms. This code deals with 
%           data sampled at 20000Hz. Upsample or downsample your data into 
%           20000Hz sample rate before feeding into the algorithm.
%       thres_freq: 
%           a value representing the frequency lower bound of the spiking
%           frequency for all electrodes. Only electrodes that's above the
%           threshold will considered as a reference electrode. For 
%           example, enter 1 for 1Hz.
%       seconds_recording:
%           The length of recording in seconds. For example, enter 120 for 
%           2 minutes recordings.
%       thres_number_spikes:
%           The threshold for total number of spikes on each reference 
%           electrode.
%       ratio:
%           Let n1 denote the largest sum of counts in any 0.5 ms moving 
%           window in the CCG and n2 denote the sum of counts of the 2 ms 
%           window with the location of the largest sum in the center. 
%           If the largest sum is found in the first 1 ms or the last 1 ms
%           of the CCG, take the sum of the counts of the first 2 ms window
%           or the counts of the last 2 ms window as n2. This ratio is the 
%           lower bound threshold for n2/n1. 
%   Output:
%       CandidateCohorts:
%           cell array contains a list of candidate constituent electrodes
%           for each reference electrode. Each cell provides a list of
%           candidate electrodes along with the latency between each
%           electrode with the reference electrode, the number of
%           co-occurrences and the n2/n1 ratio.
%
if isempty(thres_number_spikes) == 0
    thres = thres_number_spikes;
else 
    thres = thres_freq * seconds_recording;
end
n_e = length(spike_times);
smallwindow = 0.5;
t = int64(smallwindow/0.05);
CandidateCohorts = cell(1,n_e);
parfor electrode = 1:n_e
    ref = spike_times{1,electrode};
    [~, n] = size(ref);
    %assume in ms scale
    if ~isempty(ref) && n >= thres
        timedelay = zeros(1, n_e);
        for loopnumber = 1:n_e
            timedelay(1, loopnumber) = -999; 
        end
        smallwindow_cooccurrences = zeros(1, n_e);
        spikes_ratio = -999*ones(1, n_e);
        ej_list = setdiff(1:n_e, electrode);
        for electrode2 = ej_list
            CCG = zeros(1, 61);  
                tar = spike_times{1, electrode2};
                for k=1:n
                    ref_value = ref(1,k);
                    index = find(tar >= ref_value-1.5&tar <= ref_value+1.5);
                    if isempty(index)==0
                        for i_index = 1:length(index)
                            binvalue = tar(index(i_index)) - ref_value;
                            CCG(1, int64(binvalue/0.05 + 31))=CCG(1, int64(binvalue/0.05 + 31)) + 1;
                        end
                    end
                end
                spikes_smallwindow = sum(CCG(1, 1:1+t));
                location = 1;
                for i = 1:61-t
                    if sum(CCG(1, i:i+t)) > spikes_smallwindow
                        spikes_smallwindow = sum(CCG(1, i:i+t));
                        location = i;
                    end
                end
                delay = find(CCG(1, location:location+t) == max(CCG(1, location:location+t)),  1);
                delay=double(location + delay - 1);
                if delay > 21 && delay < 41
                    spikes_bigwindow = sum(CCG(delay - 20:delay + 20));
                end
                if delay <= 21
                    spikes_bigwindow = sum(CCG(1:41));
                end
                if delay >= 41
                    spikes_bigwindow = sum(CCG(21:61));
                end
                if spikes_smallwindow >= ratio*spikes_bigwindow && spikes_bigwindow>=1
                    timedelay(1, electrode2) = (delay - 31)*0.05;
                    smallwindow_cooccurrences(1,electrode2) = spikes_smallwindow;
                    spikes_ratio(1,electrode2) = spikes_smallwindow/spikes_bigwindow;
                end        
        end
        timedelay(1,electrode) = 0;
        smallwindow_cooccurrences(1,electrode) = n;
        spikes_ratio(1,electrode) = 1;
        ind = find(timedelay >= -1.5);
        CandidateCohorts{1,electrode}(1,:) = ind;
        CandidateCohorts{1,electrode}(2,:) = timedelay(ind);
        CandidateCohorts{1,electrode}(3,:) = smallwindow_cooccurrences(ind);
        CandidateCohorts{1,electrode}(4,:) = spikes_ratio(ind);
    end
end
end
