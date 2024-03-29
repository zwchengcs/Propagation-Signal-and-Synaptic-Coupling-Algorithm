function [ListofPropagation, Time_all] = automated_detection_propagation(spike_times, thres_freq, seconds_recording, thres_number_spikes, ratio, thres_cooccurrences, p)
% This function detects eAP propagation in a recording and generates a 
% collection of cohort electrodes, ach representing an eAP propagation in 
% each recording. Along with the cohort electrodes, this function also
% outputs the propagating spike times for each eAP propagation with
% different number of anchor points.
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
%           lower bound of the number of short latency co-occurrences each
%           electrode needs to have.
%       ratio:
%           Let n1 denote the largest sum of counts in any 0.5 ms moving 
%           window in the CCG and n2 denote the sum of counts of the 2 ms 
%           window with the location of the largest sum in the center. 
%           If the largest sum is found in the first 1 ms or the last 1 ms
%           of the CCG, take the sum of the counts of the first 2 ms window
%           or the counts of the last 2 ms window as n2. This ratio is the 
%           lower bound threshold for n2/n1. 
%       thres_cooccurrences:
%           lower bound of the number of short latency co-occurrences each
%           electrode needs to have.
%       p:
%           percentage of the maximum number of co-occurrences required for
%           all constituent electrodes. p should be between 0 to 100.
% 
%   Outputs:
%       ListofPropagation:
%           cell array contains tables of electrode cohorts for each
%           propagation in a recording. Each table provides a list of
%           candidate electrodes along with the latency between each
%           electrode with the reference electrode, the number of
%           co-occurrences and the n2/n1 ratio.
%       Time_all:
%           A cell array where each cell contains a list of spike times in 
%           the propagation with different number of anchor points chosen 
%           for each propagation in ListofPropagation with the same order. 
%           The first element in each cell is the number of propagating 
%           spike times isolated with two anchor points, the second element
%           is the propagating spike times isolated with three anchor 
%           points, etc., until all constituent electrodes are used as 
%           anchor points.

CandidateCohorts = scan_reference_electrode(spike_times, thres_freq, seconds_recording, thres_number_spikes, ratio);
ElectrodeCohorts = rescan_candidate_cohorts(CandidateCohorts, thres_cooccurrences, p);
ListofPropagation = get_propagation(ElectrodeCohorts);
Time_all = get_propagation_time(ListofPropagation,spike_times);
end
