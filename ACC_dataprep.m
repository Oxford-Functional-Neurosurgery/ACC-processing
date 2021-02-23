%% Prepare ACC data
% Take ACC data files & convert to a format suitable for analysis

    % Oxford Functional Neurosurgery %
    % Written by Conor Keogh %
    % conor.keogh@nds.ox.ac.uk %
    
% Output data structure:
%     1: time (ms) relative to event
%     2-7: time series data (6 electrodes)
%     8: outcome (right / wrong)
%     9: trial number
%     10: session number
%     
% To do this:
%     Get array [onset times, correct/incorrect]
%     Sort by first column
%     -> list of all trials in order with labels
%     Loop through this to get each epoch
%         6 electrodes
%         Create array where each set of samples is labelled by correct/incorrect & trial number
%         Can also add session number 
%         
%     Create table
%     Save as text file
%     -> Can import using pandas for processing

%% Prepare data
% Open file
%d one manually (as I forgot where I saved it...)

% Samples rate
fs = 2048; % Hz

% Get correct & incorrect feedback times
correctTimes = MP_EP1234_OH1234_Mergefile_Ch21.times;
incorrectTimes = MP_EP1234_OH1234_Mergefile_Ch20.times;

% Convert to sample numbers
correctIndices = correctTimes * fs;
incorrectIndices = incorrectTimes * fs;

% Create labelled trial list array
    % Correct = 1
    % Incorrect = 0
    % (MATLAB does not handle mixed-type structures well...)
allTrials = [correctIndices; incorrectIndices];
allLabels = [repmat(1, length(correctIndices), 1); repmat(0, length(incorrectIndices), 1)];

% Sort trials & labels according to time
[sortedTrials, sortIndices] = sort(allTrials);
sortedLabels = allLabels(sortIndices);

% Get session start times
startTimes = MP_EP1234_OH1234_Mergefile_Ch22.times;
startIndices = startTimes * fs; % Convert to sample numbers
startIndices = [startIndices; 7155852]; % Add end sample

%% Cycle through list & create data stucture
% ?take 1000ms either side
intervalBack = 1 * fs; % sec * samples/sec
intervalForward = 1 * fs; % sec * samples/sec

% Get vector of sample times relative to feedback (in ms)
timeVector = -1000 : 1000/fs : 1000;
timeVector = timeVector'; % Transpose vector

% Get electrode data vectors
L21 = MP_EP1234_OH1234_Mergefile_Ch8.values;
L32 = MP_EP1234_OH1234_Mergefile_Ch9.values;
L42 = MP_EP1234_OH1234_Mergefile_Ch10.values;

R65 = MP_EP1234_OH1234_Mergefile_Ch11.values;
R76 = MP_EP1234_OH1234_Mergefile_Ch12.values;
R87 = MP_EP1234_OH1234_Mergefile_Ch13.values;

% Create structure:
% [Time (ms)] [Data x 6] [Outcome] [Trial number] [Session number]
dataArray = [0 0 0 0 0 0 0 0 0 0]; % Would be faster if preallocated - no. of columns x (number of trials * samples per trial)
% Current method v hacky - just concatenating matrices as we go & cutting
% off top at end; not v efficient (but it does work)
for i = 1:length(sortedTrials)
    % Get data for current trial
    L21trial = L21(sortedTrials(i) - intervalBack : sortedTrials(i) + intervalForward);
    L32trial = L32(sortedTrials(i) - intervalBack : sortedTrials(i) + intervalForward);
    L42trial = L42(sortedTrials(i) - intervalBack : sortedTrials(i) + intervalForward);
    
    R65trial = R65(sortedTrials(i) - intervalBack : sortedTrials(i) + intervalForward);
    R76trial = R76(sortedTrials(i) - intervalBack : sortedTrials(i) + intervalForward);
    R87trial = R87(sortedTrials(i) - intervalBack : sortedTrials(i) + intervalForward);
    
    % Get session number for current trial
    session = 10;
    while sortedTrials(i) < startIndices(session)
        session = session - 1;
    end
    
    dataArray = [ dataArray; ... % Concatenate to end of array
        timeVector, ... % Time (ms) relative to feedback    
        L21trial, ... % Electrode recordings
        L32trial, ...
        L42trial, ...
        R65trial, ...
        R76trial, ...
        R87trial, ...
        repmat(sortedLabels(i), length(timeVector), 1), ... % Outcome (correct/incorrect)
        repmat(i, length(timeVector), 1) ... % Trial number
        repmat(session, length(timeVector), 1) ... % Session number
        ];
end
dataArray = dataArray(2:end, :); % Chop off row of zeros

%% Convert to table & save to file
% Create column names
columnNames = {'Time', 'L21', 'L32', 'L42', 'R65', 'R76', 'R87', 'Outcome', 'Trial', 'Session'};

% Create table
dataTable = array2table(dataArray, 'VariableNames', columnNames);

% Save table to file
writetable(dataTable, 'ACCdata.csv');