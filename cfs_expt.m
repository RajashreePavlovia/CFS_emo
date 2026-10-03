%% ============================================================
%  ATTENTION × AWARENESS × EMOTION EXPERIMENT
%  SECTION 1: INITIALIZATION
% =============================================================

clear;
clc;
close all;


%% FIND ALL WHITE/BACKGROUND COLOR COMMANDS
fprintf('\n===============================================================\n');
fprintf('SEARCHING cfs_expt.m FOR BACKGROUND/COLOR COMMANDS\n');
fprintf('===============================================================\n\n');

fileText = fileread('cfs_expt.m');
lines = splitlines(fileText);

searchTerms = {
    'WhiteIndex'
    'BlackIndex'
    'backgroundColor'
    'FillRect'
    'OpenWindow'
    'FillOval'
    'FillPoly'
    '255 255 255'
    '[255'
    '[127'
    '[128'
    'White'
    'white'
    };

for s = 1:numel(searchTerms)

    term = searchTerms{s};

    fprintf('\n---------------------------------------------------------------\n');
    fprintf('SEARCH TERM: %s\n', term);
    fprintf('---------------------------------------------------------------\n');

    found = false;

    for k = 1:numel(lines)

        if contains(lines{k}, term, 'IgnoreCase', false)
            fprintf('Line %d: %s\n', k, lines{k});
            found = true;
        end

    end

    if ~found
        fprintf('No occurrences found.\n');
    end

end

fprintf('\n===============================================================\n');
%% -------------------- Participant information --------------------

participantID = input('Enter participant ID: ', 's');

fprintf('\nParticipant: %s\n', participantID);
fprintf('Experiment initialization started.\n\n');


%% -------------------- Experiment settings -----------------------

% Number of blocks
nBlocks = 24;

% Trials per block
trialsPerBlock = 36;

% Total trials
totalTrials = nBlocks * trialsPerBlock;

% RSVP cross duration (milliseconds)
crossDuration = 166.67;

% Fixation duration (milliseconds)
fixationDuration = 500;

% Inter-trial interval (milliseconds)
ITIDuration = 1500;

% Possible probe trials
minProbeTrial = 15;
maxProbeTrial = 36;


%% -------------------- Experimental factors -----------------------

rsvpLoads = {'Easy', 'Hard'};

awarenessLevels = {'Aware', 'Unaware'};

emotionLevels = {'Happy', 'Angry', 'Neutral'};


%% -------------------- Number of identities -----------------------

nFaces = 12;

% 6 male + 6 female
nMaleFaces = 6;
nFemaleFaces = 6;


%% -------------------- Randomization ------------------------------

% Seed MATLAB's random number generator
rng('shuffle');


%% -------------------- Psychtoolbox -------------------------------

AssertOpenGL;

% Skip synchronization tests while developing/debugging.
% CHANGE THIS TO 0 FOR THE FINAL EXPERIMENT.
Screen('Preference', 'SkipSyncTests', 1);

% Get available screens
screens = Screen('Screens');

% Use the maximum screen number
screenNumber = max(screens);

fprintf('Screen number: %d\n', screenNumber);
fprintf('Initialization complete.\n\n');

KbName('UnifyKeyNames');
escapeKey = KbName('ESCAPE');

fprintf('Press ESC at any time during a display test to exit.\n\n');

%% ============================================================
%  SECTION 2: EXPERIMENT PATHS AND STIMULUS FILES
% =============================================================

%% -------------------- Experiment directories --------------------

expDir = 'D:\CFS\Expt_emo';
stimDir = fullfile(expDir, 'Stimuli');

% RSVP sequence file
rsvpFile = fullfile(stimDir, 'rsvp_sequences.csv');

% Face directories
neutralDir = fullfile(stimDir, ...
    'crop_contour_blur', 'neutral');

angryDir = fullfile(stimDir, ...
    'crop_contour_blur', 'angry');

happyDir = fullfile(stimDir, ...
    'crop_contour_blur', 'happy');


%% -------------------- Check paths -------------------------------

if ~exist(expDir, 'dir')
    error('Experiment directory not found: %s', expDir);
end

if ~exist(stimDir, 'dir')
    error('Stimuli directory not found: %s', stimDir);
end

if ~exist(rsvpFile, 'file')
    error('RSVP CSV file not found: %s', rsvpFile);
end

if ~exist(neutralDir, 'dir')
    error('Neutral face directory not found: %s', neutralDir);
end

if ~exist(angryDir, 'dir')
    error('Angry face directory not found: %s', angryDir);
end

if ~exist(happyDir, 'dir')
    error('Happy face directory not found: %s', happyDir);
end

fprintf('Stimulus paths verified successfully.\n');





%% -------------------- Load RSVP sequences ------------------------

rsvpTable = readtable(rsvpFile, ...
    'Delimiter', ',', ...
    'TextType', 'string');

% Remove completely blank rows
firstColumn = rsvpTable{:,1};
validRows = strlength(strtrim(firstColumn)) > 0;

rsvpTable = rsvpTable(validRows, :);

fprintf('RSVP CSV loaded successfully.\n');
fprintf('Number of RSVP sequence templates: %d\n', height(rsvpTable));

fprintf('\nFirst 10 RSVP sequences:\n');
disp(rsvpTable(1:min(10,height(rsvpTable)), :));



%% -------------------- Organize RSVP templates -------------------

% Easy-load templates
easyRows = strcmpi(rsvpTable.RSVPLoad, 'Easy');

% Hard-load templates
hardRows = strcmpi(rsvpTable.RSVPLoad, 'Hard');

easyTable = rsvpTable(easyRows, :);
hardTable = rsvpTable(hardRows, :);

fprintf('\nRSVP template summary:\n');
fprintf('Easy templates: %d\n', height(easyTable));
fprintf('Hard templates: %d\n', height(hardTable));

fprintf('\nEasy target counts:\n');
disp(unique(easyTable.TargetCount)');

fprintf('Hard target counts:\n');
disp(unique(hardTable.TargetCount)');


%% -------------------- Check sequence templates ------------------

fprintf('\nChecking sequence lengths...\n');

for i = 1:height(rsvpTable)

    sequence = char(rsvpTable.Sequence(i));

    calculatedLength = length(sequence);
    csvLength = rsvpTable.CrossCount(i);

    if calculatedLength ~= csvLength
        warning('Row %d (%s): Sequence length = %d, CrossCount = %d', ...
            i, rsvpTable{ i, 1 }, calculatedLength, csvLength);
    end
end

fprintf('Sequence-length check complete.\n');



%% -------------------- Check target counts -----------------------

for i = 1:height(rsvpTable)

    sequence = char(rsvpTable.Sequence(i));

    calculatedTargets = sum(sequence == '1');
    csvTargets = rsvpTable.TargetCount(i);

    if calculatedTargets ~= csvTargets
        warning('Row %d (%s): Sequence contains %d targets, TargetCount = %d', ...
            i, rsvpTable{ i, 1 }, calculatedTargets, csvTargets);
    end
end

fprintf('Target-count check complete.\n');



%% ============================================================
% SECTION 3: BLOCK RANDOMIZATION
% =============================================================

%% -------------------- Create all 12 conditions ------------------

conditionNumber = 0;

conditions = struct( ...
    'Condition', cell(1,12), ...
    'RSVPLoad', cell(1,12), ...
    'Awareness', cell(1,12), ...
    'Emotion', cell(1,12));

for iLoad = 1:length(rsvpLoads)

    for iAwareness = 1:length(awarenessLevels)

        for iEmotion = 1:length(emotionLevels)

            conditionNumber = conditionNumber + 1;

            conditions(conditionNumber).Condition = conditionNumber;
            conditions(conditionNumber).RSVPLoad = rsvpLoads{iLoad};
            conditions(conditionNumber).Awareness = awarenessLevels{iAwareness};
            conditions(conditionNumber).Emotion = emotionLevels{iEmotion};

        end

    end

end


%% -------------------- Repeat each condition twice ---------------

blockConditions = [conditions conditions];


%% -------------------- Randomize block order ----------------------

randomOrder = randperm(length(blockConditions));

blockConditions = blockConditions(randomOrder);


%% -------------------- Display block order -------------------------

fprintf('\n============================================\n');
fprintf('RANDOMIZED BLOCK ORDER\n');
fprintf('============================================\n\n');

for b = 1:nBlocks

    fprintf('Block %2d:  %-4s | %-8s | %-7s\n', ...
        b, ...
        blockConditions(b).RSVPLoad, ...
        blockConditions(b).Awareness, ...
        blockConditions(b).Emotion);

end

fprintf('\nTotal blocks: %d\n', length(blockConditions));


%% -------------------- Verify block balance ----------------------

fprintf('\n============================================\n');
fprintf('BLOCK BALANCE CHECK\n');
fprintf('============================================\n\n');

for iLoad = 1:length(rsvpLoads)

    for iAwareness = 1:length(awarenessLevels)

        for iEmotion = 1:length(emotionLevels)

            count = 0;

            for b = 1:nBlocks

                if strcmp(blockConditions(b).RSVPLoad, rsvpLoads{iLoad}) && ...
                   strcmp(blockConditions(b).Awareness, awarenessLevels{iAwareness}) && ...
                   strcmp(blockConditions(b).Emotion, emotionLevels{iEmotion})

                    count = count + 1;

                end

            end

            fprintf('%-4s | %-8s | %-7s = %d blocks\n', ...
                rsvpLoads{iLoad}, ...
                awarenessLevels{iAwareness}, ...
                emotionLevels{iEmotion}, ...
                count);

        end

    end

end


%% ============================================================
% SECTION 4: PREPARE RSVP SEQUENCE TEMPLATES
% =============================================================

fprintf('\n============================================\n');
fprintf('PREPARING RSVP SEQUENCE TEMPLATES\n');
fprintf('============================================\n\n');


%% -------------------- Number of templates -----------------------

nSequences = height(rsvpTable);

fprintf('Total RSVP templates found: %d\n', nSequences);


%% -------------------- Store templates ---------------------------

rsvpSequences = struct( ...
    'ID', cell(nSequences,1), ...
    'RSVPLoad', cell(nSequences,1), ...
    'Sequence', cell(nSequences,1), ...
    'CrossCount', cell(nSequences,1), ...
    'Duration', cell(nSequences,1), ...
    'TargetCount', cell(nSequences,1));


for s = 1:nSequences

    rsvpSequences(s).ID = char(rsvpTable{s,1});

    rsvpSequences(s).RSVPLoad = ...
        char(rsvpTable.RSVPLoad(s));

    rsvpSequences(s).Sequence = ...
        char(rsvpTable.Sequence(s));

    rsvpSequences(s).CrossCount = ...
        rsvpTable.CrossCount(s);

    rsvpSequences(s).Duration = ...
        rsvpTable.Duration(s);

    rsvpSequences(s).TargetCount = ...
        rsvpTable.TargetCount(s);

end


fprintf('RSVP templates prepared successfully.\n');


%% -------------------- Display all templates ---------------------

fprintf('\n--------------------------------------------\n');
fprintf('RSVP TEMPLATE LIST\n');
fprintf('--------------------------------------------\n\n');

for s = 1:nSequences

    fprintf('%-6s | %-4s | %-12s | %2d arrows | %d targets\n', ...
        rsvpSequences(s).ID, ...
        rsvpSequences(s).RSVPLoad, ...
        rsvpSequences(s).Sequence, ...
        rsvpSequences(s).CrossCount, ...
        rsvpSequences(s).TargetCount);

end


%% -------------------- Verify template counts --------------------

fprintf('\n============================================\n');
fprintf('RSVP TEMPLATE BALANCE CHECK\n');
fprintf('============================================\n\n');


for iLoad = 1:length(rsvpLoads)

    fprintf('%s load:\n', rsvpLoads{iLoad});

    for targetCount = 1:5

        count = 0;

        for s = 1:nSequences

            if strcmp(rsvpSequences(s).RSVPLoad, rsvpLoads{iLoad}) && ...
               rsvpSequences(s).TargetCount == targetCount

                count = count + 1;

            end

        end

        if count > 0

            fprintf('  %d target(s): %d unique templates\n', ...
                targetCount, count);

        end

    end

    fprintf('\n');

end



%% ============================================================
% SECTION 5: GENERATE RSVP TRIAL TEMPLATES FOR EACH BLOCK
% =============================================================

fprintf('\n============================================\n');
fprintf('GENERATING RSVP TRIAL TEMPLATES\n');
fprintf('============================================\n\n');


%% -------------------- Storage for block trials ------------------

blockTrials = cell(nBlocks, 1);


%% -------------------- Generate trials for each block ------------

for b = 1:nBlocks

    currentLoad = blockConditions(b).RSVPLoad;

    fprintf('Generating trials for Block %d: %s | %s | %s\n', ...
        b, ...
        blockConditions(b).RSVPLoad, ...
        blockConditions(b).Awareness, ...
        blockConditions(b).Emotion);


    % -------------------------------------------------------------
    % Determine required target counts for this load
    % -------------------------------------------------------------

    if strcmp(currentLoad, 'Easy')

        targetCounts = [2 3 4 5];

    elseif strcmp(currentLoad, 'Hard')

        targetCounts = [1 2 3 4];

    else

        error('Unknown RSVP load: %s', currentLoad);

    end


    % -------------------------------------------------------------
    % Temporary storage for the 36 trials
    % -------------------------------------------------------------

    selectedTrials = struct( ...
        'TemplateID', {}, ...
        'RSVPLoad', {}, ...
        'Sequence', {}, ...
        'CrossCount', {}, ...
        'Duration', {}, ...
        'TargetCount', {});


    trialCounter = 0;


    % -------------------------------------------------------------
    % Select 9 trials for each target-count category
    % -------------------------------------------------------------

    for tc = targetCounts

        % Find templates belonging to this load and target count

        available = [];

        for s = 1:nSequences

            if strcmp(rsvpSequences(s).RSVPLoad, currentLoad) && ...
               rsvpSequences(s).TargetCount == tc

                available(end+1) = s;

            end

        end


        nAvailable = length(available);


        % ---------------------------------------------------------
        % We need exactly 9 trials for every target-count category
        % ---------------------------------------------------------

        if nAvailable == 9

            % Use all 9 unique templates once

            chosen = available(randperm(nAvailable));

        elseif nAvailable == 6

            % Use all 6 unique templates once
            chosen = available(randperm(nAvailable));

            % Select 3 additional DIFFERENT templates to repeat
            repeatIndices = randperm(nAvailable, 3);

            chosen = [chosen available(repeatIndices)];

            % Randomize the resulting 9 trials
            chosen = chosen(randperm(length(chosen)));

        else

            error(['Unexpected number of templates for %s load ' ...
                   'with %d targets: %d templates found.'], ...
                   currentLoad, tc, nAvailable);

        end


        % ---------------------------------------------------------
        % Add selected templates to this block
        % ---------------------------------------------------------

        for k = 1:length(chosen)

            s = chosen(k);

            trialCounter = trialCounter + 1;

            selectedTrials(trialCounter).TemplateID = ...
                rsvpSequences(s).ID;

            selectedTrials(trialCounter).RSVPLoad = ...
                rsvpSequences(s).RSVPLoad;

            selectedTrials(trialCounter).Sequence = ...
                rsvpSequences(s).Sequence;

            selectedTrials(trialCounter).CrossCount = ...
                rsvpSequences(s).CrossCount;

            selectedTrials(trialCounter).Duration = ...
                rsvpSequences(s).Duration;

            selectedTrials(trialCounter).TargetCount = ...
                rsvpSequences(s).TargetCount;

        end

    end


    % -------------------------------------------------------------
    % Randomize all 36 trials within the block
    % -------------------------------------------------------------

    randomTrialOrder = randperm(length(selectedTrials));

    selectedTrials = selectedTrials(randomTrialOrder);


    % Store block
    blockTrials{b} = selectedTrials;


    fprintf('  Generated %d RSVP trials.\n', ...
        length(selectedTrials));

end


fprintf('\nAll blocks generated successfully.\n');


%% ============================================================
% SECTION 5B: VERIFY RSVP TRIAL BALANCE
% =============================================================

fprintf('\n============================================\n');
fprintf('RSVP TRIAL BALANCE CHECK\n');
fprintf('============================================\n\n');


for b = 1:nBlocks

    currentLoad = blockConditions(b).RSVPLoad;
    trials = blockTrials{b};


    fprintf('Block %2d | %s | %s | %s\n', ...
        b, ...
        blockConditions(b).RSVPLoad, ...
        blockConditions(b).Awareness, ...
        blockConditions(b).Emotion);


    % Check total number of trials

    if length(trials) ~= trialsPerBlock

        error('Block %d does not contain exactly %d trials.', ...
            b, trialsPerBlock);

    end


    % Determine expected target counts

    if strcmp(currentLoad, 'Easy')

        expectedCounts = [2 3 4 5];

    else

        expectedCounts = [1 2 3 4];

    end


    % Count each target-count category

    for tc = expectedCounts

        count = 0;

        for t = 1:length(trials)

            if trials(t).TargetCount == tc

                count = count + 1;

            end

        end


        fprintf('  %d target(s): %d trials\n', ...
            tc, count);


        % Verify exactly 9

        if count ~= 9

            error(['Block %d has %d trials with %d targets. ' ...
                   'Expected exactly 9.'], ...
                   b, count, tc);

        end

    end

    fprintf('\n');

end


fprintf('============================================\n');
fprintf('ALL RSVP TRIAL BALANCE CHECKS PASSED.\n');
fprintf('============================================\n');


%% ============================================================
% SECTION 6: DEFINE RSVP ARROW PROPERTIES
% =============================================================

fprintf('\n============================================\n');
fprintf('SETTING RSVP ARROW RULES\n');
fprintf('============================================\n\n');


%% -------------------- Arrow orientations -------------------------

% We use two orientations:
% upright
% downright / inverted

arrowOrientations = {'upright', 'downright'};


%% -------------------- Easy condition ----------------------------

% Easy targets:
% RED, either orientation

easyTargetColours = {'red'};

% Easy non-targets:
% YELLOW, GREEN, BLUE, ORANGE, PINK
% Either orientation

easyNonTargetColours = ...
    {'yellow', 'green', 'blue', 'orange', 'pink'};


%% -------------------- Hard condition ----------------------------

% Hard targets:
% UPRIGHT YELLOW
% DOWNRIGHT GREEN

hardTargetColours = {'yellow', 'green'};

hardTargetOrientations = {'upright', 'downright'};


% Hard non-targets:
% BLUE, ORANGE, PINK, RED
% Either orientation

hardNonTargetColours = ...
    {'blue', 'orange', 'pink', 'red'};


fprintf('Easy condition rules defined.\n');
fprintf('Hard condition rules defined.\n');




%% ============================================================
% SECTION 7: GENERATE FINAL RSVP TRIAL SKELETONS
% =============================================================

fprintf('\n============================================\n');
fprintf('GENERATING FINAL RSVP TRIAL SKELETONS\n');
fprintf('============================================\n\n');


%% -------------------- Padding settings --------------------------

% Number of non-targets allowed before the first target
minBeginningNonTargets = 0;
maxBeginningNonTargets = 2;

% Number of non-targets allowed after the final target
minEndingNonTargets = 0;
maxEndingNonTargets = 2;


%% -------------------- Generate skeletons ------------------------

for b = 1:nBlocks

    trials = blockTrials{b};

    for t = 1:length(trials)

        % Original CSV pattern
        baseSequence = trials(t).Sequence;


        % ---------------------------------------------------------
        % Random beginning padding
        % ---------------------------------------------------------

        nBeginning = randi([ ...
            minBeginningNonTargets ...
            maxBeginningNonTargets]);


        % ---------------------------------------------------------
        % Random ending padding
        % ---------------------------------------------------------

        nEnding = randi([ ...
            minEndingNonTargets ...
            maxEndingNonTargets]);


        % ---------------------------------------------------------
        % Create padding
        % ---------------------------------------------------------

        beginningPadding = repmat('o', 1, nBeginning);

        endingPadding = repmat('o', 1, nEnding);


        % ---------------------------------------------------------
        % Construct final sequence
        % ---------------------------------------------------------

        finalSequence = [ ...
            beginningPadding ...
            baseSequence ...
            endingPadding];


        % ---------------------------------------------------------
        % Store final sequence
        % ---------------------------------------------------------

        trials(t).FinalSequence = finalSequence;

        trials(t).BeginningNonTargets = nBeginning;

        trials(t).EndingNonTargets = nEnding;

        trials(t).FinalCrossCount = length(finalSequence);


    end


    % Store updated trials
    blockTrials{b} = trials;

end


fprintf('Final RSVP skeletons generated for all %d blocks.\n', ...
    nBlocks);



%% ============================================================
% SECTION 7B: VERIFY FINAL RSVP SKELETONS
% =============================================================

fprintf('\n============================================\n');
fprintf('VERIFYING RSVP SKELETONS\n');
fprintf('============================================\n\n');


for b = 1:nBlocks

    trials = blockTrials{b};

    for t = 1:length(trials)

        seq = trials(t).FinalSequence;


        % ---------------------------------------------------------
        % Check that sequence contains only 1 and o
        % ---------------------------------------------------------

        if ~all(seq == '1' | seq == 'o')

            error(['Invalid character found in Block %d, ' ...
                   'Trial %d.'], b, t);

        end


        % ---------------------------------------------------------
        % Count targets
        % ---------------------------------------------------------

        actualTargetCount = sum(seq == '1');


        if actualTargetCount ~= trials(t).TargetCount

            error(['Target count mismatch in Block %d, Trial %d. ' ...
                   'Expected %d, found %d.'], ...
                   b, ...
                   t, ...
                   trials(t).TargetCount, ...
                   actualTargetCount);

        end


        % ---------------------------------------------------------
        % Check beginning padding
        % ---------------------------------------------------------

        nBeginning = trials(t).BeginningNonTargets;

        if nBeginning > 0

            if any(seq(1:nBeginning) ~= 'o')

                error(['Invalid beginning padding in Block %d, ' ...
                       'Trial %d.'], b, t);

            end

        end


        % ---------------------------------------------------------
        % Check ending padding
        % ---------------------------------------------------------

        nEnding = trials(t).EndingNonTargets;

        if nEnding > 0

            if any(seq(end-nEnding+1:end) ~= 'o')

                error(['Invalid ending padding in Block %d, ' ...
                       'Trial %d.'], b, t);

            end

        end


        % ---------------------------------------------------------
        % Check spacing between targets
        % ---------------------------------------------------------

        targetPositions = find(seq == '1');

        if length(targetPositions) > 1

            for k = 1:length(targetPositions)-1

                gap = targetPositions(k+1) - ...
                      targetPositions(k) - 1;

                if gap < 1 || gap > 2

                    error(['Invalid target spacing in Block %d, ' ...
                           'Trial %d. Gap = %d.'], ...
                           b, t, gap);

                end

            end

        end

    end

end


fprintf('All RSVP skeleton checks passed successfully.\n');



%% -------------------- Display example trials --------------------

fprintf('\n============================================\n');
fprintf('EXAMPLE GENERATED RSVP TRIALS\n');
fprintf('============================================\n\n');


for b = 1:min(2,nBlocks)

    fprintf('Block %d: %s | %s | %s\n', ...
        b, ...
        blockConditions(b).RSVPLoad, ...
        blockConditions(b).Awareness, ...
        blockConditions(b).Emotion);

    fprintf('--------------------------------------------\n');

    trials = blockTrials{b};

    for t = 1:min(10,length(trials))

        fprintf(['Trial %2d | Template %-6s | ' ...
                 '%d target(s) | %2d arrows | %s\n'], ...
            t, ...
            trials(t).TemplateID, ...
            trials(t).TargetCount, ...
            trials(t).FinalCrossCount, ...
            trials(t).FinalSequence);

    end

    fprintf('\n');

end



%% ============================================================
% SECTION 8: GENERATE ACTUAL RSVP ARROW PROPERTIES
% =============================================================

fprintf('\n============================================\n');
fprintf('GENERATING RSVP ARROW PROPERTIES\n');
fprintf('============================================\n\n');


%% -------------------- Generate arrows ---------------------------

for b = 1:nBlocks

    currentLoad = blockConditions(b).RSVPLoad;

    trials = blockTrials{b};


    for t = 1:length(trials)

        sequence = trials(t).FinalSequence;

        nArrows = length(sequence);


        % ---------------------------------------------------------
        % Storage
        % ---------------------------------------------------------

        arrowColour = cell(1, nArrows);

        arrowOrientation = cell(1, nArrows);

        arrowIsTarget = zeros(1, nArrows);


        % ---------------------------------------------------------
        % Generate each arrow
        % ---------------------------------------------------------

        for a = 1:nArrows

            symbol = sequence(a);


            %% ====================================================
            % TARGET
            % =====================================================

            if symbol == '1'

                arrowIsTarget(a) = 1;


                % -------------------------------------------------
                % EASY TARGET
                % -------------------------------------------------

                if strcmp(currentLoad, 'Easy')

                    % Easy target:
                    % RED, either orientation

                    arrowColour{a} = 'red';


                    % Determine orientations that do not create
                    % a run of more than 3.

                    if a <= 3

                        possibleOrientations = ...
                            arrowOrientations;

                    else

                        if strcmp(arrowOrientation{a-1}, ...
                                  arrowOrientation{a-2}) && ...
                           strcmp(arrowOrientation{a-2}, ...
                                  arrowOrientation{a-3})

                            % Previous 3 are identical.
                            % Must use the opposite orientation.

                            if strcmp(arrowOrientation{a-1}, ...
                                      'upright')

                                possibleOrientations = ...
                                    {'downright'};

                            else

                                possibleOrientations = ...
                                    {'upright'};

                            end

                        else

                            possibleOrientations = ...
                                arrowOrientations;

                        end

                    end


                    arrowOrientation{a} = ...
                        possibleOrientations{ ...
                        randi(length(possibleOrientations))};


                % -------------------------------------------------
                % HARD TARGET
                % -------------------------------------------------

                elseif strcmp(currentLoad, 'Hard')

                    % Hard targets:
                    %
                    % upright yellow
                    % OR
                    % downright green


                    % Find which target types are currently
                    % allowed by the orientation constraint.

                    possibleTargetColours = {};
                    possibleTargetOrientations = {};


                    % Candidate 1:
                    % upright yellow

                    candidateOrientation = 'upright';

                    allowed = true;


                    if a >= 4

                        if strcmp(arrowOrientation{a-1}, ...
                                  candidateOrientation) && ...
                           strcmp(arrowOrientation{a-2}, ...
                                  candidateOrientation) && ...
                           strcmp(arrowOrientation{a-3}, ...
                                  candidateOrientation)

                            allowed = false;

                        end

                    end


                    if allowed

                        possibleTargetColours{end+1} = ...
                            'yellow';

                        possibleTargetOrientations{end+1} = ...
                            'upright';

                    end


                    % Candidate 2:
                    % downright green

                    candidateOrientation = 'downright';

                    allowed = true;


                    if a >= 4

                        if strcmp(arrowOrientation{a-1}, ...
                                  candidateOrientation) && ...
                           strcmp(arrowOrientation{a-2}, ...
                                  candidateOrientation) && ...
                           strcmp(arrowOrientation{a-3}, ...
                                  candidateOrientation)

                            allowed = false;

                        end

                    end


                    if allowed

                        possibleTargetColours{end+1} = ...
                            'green';

                        possibleTargetOrientations{end+1} = ...
                            'downright';

                    end


                    % At least one target type should always be
                    % available because there are only two
                    % orientations and the maximum run is 3.

                    if isempty(possibleTargetColours)

                        error(['No valid Hard target orientation ' ...
                               'available in Block %d, Trial %d, ' ...
                               'Arrow %d.'], b, t, a);

                    end


                    % Randomly select from valid target types

                    targetIndex = ...
                        randi(length(possibleTargetColours));


                    arrowColour{a} = ...
                        possibleTargetColours{targetIndex};

                    arrowOrientation{a} = ...
                        possibleTargetOrientations{targetIndex};

                end


            %% ====================================================
            % NON-TARGET
            % ====================================================

            elseif symbol == 'o'

                arrowIsTarget(a) = 0;


                % -------------------------------------------------
                % Determine available colours
                % -------------------------------------------------

                if strcmp(currentLoad, 'Easy')

                    availableColours = ...
                        easyNonTargetColours;

                elseif strcmp(currentLoad, 'Hard')

                    availableColours = ...
                        hardNonTargetColours;

                end


                % -------------------------------------------------
                % Remove previous colour
                % -------------------------------------------------

                if a == 1

                    possibleColourIndices = ...
                        1:length(availableColours);

                else

                    possibleColourIndices = [];

                    for c = 1:length(availableColours)

                        if ~strcmp(availableColours{c}, ...
                                   arrowColour{a-1})

                            possibleColourIndices(end+1) = c;

                        end

                    end

                end


                % -------------------------------------------------
                % Randomly select colour
                % -------------------------------------------------

                colourIndex = ...
                    possibleColourIndices( ...
                    randi(length(possibleColourIndices)));


                arrowColour{a} = ...
                    availableColours{colourIndex};


                % -------------------------------------------------
                % Determine allowed orientations
                % -------------------------------------------------

                if a <= 3

                    possibleOrientations = ...
                        arrowOrientations;

                else

                    if strcmp(arrowOrientation{a-1}, ...
                              arrowOrientation{a-2}) && ...
                       strcmp(arrowOrientation{a-2}, ...
                              arrowOrientation{a-3})

                        % Previous 3 are identical.
                        % Force opposite orientation.

                        if strcmp(arrowOrientation{a-1}, ...
                                  'upright')

                            possibleOrientations = ...
                                {'downright'};

                        else

                            possibleOrientations = ...
                                {'upright'};

                        end

                    else

                        possibleOrientations = ...
                            arrowOrientations;

                    end

                end


                arrowOrientation{a} = ...
                    possibleOrientations{ ...
                    randi(length(possibleOrientations))};

            end

        end


        % ---------------------------------------------------------
        % Store arrow properties
        % ---------------------------------------------------------

        trials(t).ArrowColour = arrowColour;

        trials(t).ArrowOrientation = arrowOrientation;

        trials(t).ArrowIsTarget = arrowIsTarget;

    end


    blockTrials{b} = trials;

end


fprintf('Actual arrow properties generated for all blocks.\n');



%% ============================================================
% SECTION 8B: VERIFY ARROW COLOUR AND ORIENTATION RULES
% =============================================================

fprintf('\n============================================\n');
fprintf('VERIFYING ARROW PROPERTIES\n');
fprintf('============================================\n\n');


for b = 1:nBlocks

    currentLoad = blockConditions(b).RSVPLoad;

    trials = blockTrials{b};


    for t = 1:length(trials)

        colours = trials(t).ArrowColour;

        orientations = trials(t).ArrowOrientation;

        isTarget = trials(t).ArrowIsTarget;


        %% --------------------------------------------------------
        % Check consecutive colours
        % ---------------------------------------------------------

        for a = 2:length(colours)

            if strcmp(colours{a}, colours{a-1})

                error(['Consecutive identical colours in ' ...
                       'Block %d, Trial %d, Arrow %d. ' ...
                       'Colour = %s.'], ...
                       b, t, a, colours{a});

            end

        end


        %% --------------------------------------------------------
        % Check maximum orientation run
        % ---------------------------------------------------------

        currentRun = 1;

        for a = 2:length(orientations)

            if strcmp(orientations{a}, orientations{a-1})

                currentRun = currentRun + 1;

            else

                currentRun = 1;

            end


            if currentRun > 3

                error(['More than 3 consecutive identical ' ...
                       'orientations in Block %d, Trial %d, ' ...
                       'Arrow %d.'], ...
                       b, t, a);

            end

        end


        %% --------------------------------------------------------
        % Check target definitions
        % ---------------------------------------------------------

        for a = 1:length(colours)

            if isTarget(a) == 1


                if strcmp(currentLoad, 'Easy')

                    % Easy target = red, either orientation

                    if ~strcmp(colours{a}, 'red')

                        error(['Invalid Easy target in Block %d, ' ...
                               'Trial %d, Arrow %d.'], ...
                               b, t, a);

                    end


                elseif strcmp(currentLoad, 'Hard')

                    % Hard target must be:
                    % upright yellow OR downright green

                    validHardTarget = ...
                        (strcmp(colours{a}, 'yellow') && ...
                         strcmp(orientations{a}, 'upright')) || ...
                        (strcmp(colours{a}, 'green') && ...
                         strcmp(orientations{a}, 'downright'));


                    if ~validHardTarget

                        error(['Invalid Hard target in Block %d, ' ...
                               'Trial %d, Arrow %d.'], ...
                               b, t, a);

                    end

                end

            end

        end

    end

end


fprintf('All arrow property checks passed successfully.\n');



%% ============================================================
% SECTION 9: GENERATE FACE PRESENTATION ORDER
% =============================================================

fprintf('\n============================================\n');
fprintf('GENERATING FACE PRESENTATION ORDERS\n');
fprintf('============================================\n\n');


%% -------------------- Face identity list ------------------------

% IMPORTANT:
% These should correspond to the 12 face identities available
% in each emotion folder.
%
% For now we identify them using numbers 1-12.
% We will connect these numbers to the actual image filenames
% after checking the filenames.

faceIDs = 1:nFaces;


%% -------------------- Generate face order for each block --------

blockFaces = cell(nBlocks, 1);


for b = 1:nBlocks

    % -------------------------------------------------------------
    % Each of the 12 identities appears exactly 3 times
    % -------------------------------------------------------------

    faceOrder = repmat(faceIDs, 1, 3);


    % -------------------------------------------------------------
    % Randomize until no identity appears consecutively
    % -------------------------------------------------------------

    validOrder = false;

    while ~validOrder

        faceOrder = faceOrder(randperm(length(faceOrder)));

        validOrder = true;


        % Check for consecutive repetitions

        for f = 2:length(faceOrder)

            if faceOrder(f) == faceOrder(f-1)

                validOrder = false;

                break;

            end

        end

    end


    % -------------------------------------------------------------
    % Store
    % -------------------------------------------------------------

    blockFaces{b} = faceOrder;


    fprintf('Block %2d: %d face presentations generated.\n', ...
        b, length(faceOrder));

end


fprintf('\nAll face presentation orders generated.\n');


%% ============================================================
% SECTION 9B: VERIFY FACE PRESENTATION BALANCE
% =============================================================

fprintf('\n============================================\n');
fprintf('FACE PRESENTATION BALANCE CHECK\n');
fprintf('============================================\n\n');


for b = 1:nBlocks

    faceOrder = blockFaces{b};


    % -------------------------------------------------------------
    % Check total presentations
    % -------------------------------------------------------------

    if length(faceOrder) ~= trialsPerBlock

        error(['Block %d has %d face presentations. ' ...
               'Expected %d.'], ...
               b, length(faceOrder), trialsPerBlock);

    end


    % -------------------------------------------------------------
    % Check every identity appears exactly 3 times
    % -------------------------------------------------------------

    for f = faceIDs

        count = sum(faceOrder == f);

        if count ~= 3

            error(['Block %d: Face identity %d appears %d times. ' ...
                   'Expected exactly 3.'], ...
                   b, f, count);

        end

    end


    % -------------------------------------------------------------
    % Check no consecutive repetitions
    % -------------------------------------------------------------

    for p = 2:length(faceOrder)

        if faceOrder(p) == faceOrder(p-1)

            error(['Consecutive face repetition in Block %d, ' ...
                   'positions %d and %d. Face = %d.'], ...
                   b, p-1, p, faceOrder(p));

        end

    end

end


fprintf('All face presentation balance checks passed.\n');


%% -------------------- Display example face orders ---------------

fprintf('\n============================================\n');
fprintf('EXAMPLE FACE ORDERS\n');
fprintf('============================================\n\n');


for b = 1:min(3,nBlocks)

    fprintf('Block %2d | %s | %s | %s\n', ...
        b, ...
        blockConditions(b).RSVPLoad, ...
        blockConditions(b).Awareness, ...
        blockConditions(b).Emotion);

    fprintf('Face order:\n');

    disp(blockFaces{b});

end



%% ============================================================
% SECTION 10: LOAD FACE FILENAMES
% =============================================================

fprintf('\n============================================\n');
fprintf('LOADING FACE FILENAMES\n');
fprintf('============================================\n\n');

% Face folders
neutralDir = 'D:\CFS\Expt_emo\Stimuli\crop_contour_blur\neutral';
angryDir   = 'D:\CFS\Expt_emo\Stimuli\crop_contour_blur\angry';
happyDir   = 'D:\CFS\Expt_emo\Stimuli\crop_contour_blur\happy';

% Check folders
if ~exist(neutralDir, 'dir')
    error('Neutral face folder not found: %s', neutralDir);
end

if ~exist(angryDir, 'dir')
    error('Angry face folder not found: %s', angryDir);
end

if ~exist(happyDir, 'dir')
    error('Happy face folder not found: %s', happyDir);
end

% Get all files
neutralFiles = dir(fullfile(neutralDir, '*'));
angryFiles   = dir(fullfile(angryDir, '*'));
happyFiles   = dir(fullfile(happyDir, '*'));

% Remove folders
neutralFiles = neutralFiles(~[neutralFiles.isdir]);
angryFiles   = angryFiles(~[angryFiles.isdir]);
happyFiles   = happyFiles(~[happyFiles.isdir]);

fprintf('Neutral files found: %d\n', length(neutralFiles));
fprintf('Angry files found:   %d\n', length(angryFiles));
fprintf('Happy files found:   %d\n', length(happyFiles));

fprintf('\nNeutral filenames:\n');
disp({neutralFiles.name}');

fprintf('\nAngry filenames:\n');
disp({angryFiles.name}');

fprintf('\nHappy filenames:\n');
disp({happyFiles.name}');


%% ============================================================
% SECTION 11: BUILD FACE IDENTITY DATABASE
% =============================================================

fprintf('\n============================================\n');
fprintf('BUILDING FACE IDENTITY DATABASE\n');
fprintf('============================================\n\n');

% ------------------------------------------------------------
% Get filenames
% ------------------------------------------------------------

neutralNames = {neutralFiles.name};
angryNames   = {angryFiles.name};
happyNames   = {happyFiles.name};

% ------------------------------------------------------------
% Extract identity codes
%
% AF = Female
% AM = Male
%
% Examples:
% AF03NES_processed.png -> AF03
% AM01ANS_processed.png -> AM01
% ------------------------------------------------------------

neutralIDs = cell(size(neutralNames));

for i = 1:length(neutralNames)

    [~, nameOnly, ~] = fileparts(neutralNames{i});

    % First four characters = identity
    neutralIDs{i} = nameOnly(1:4);

end

% Get unique identities
faceIDs = unique(neutralIDs, 'stable');

fprintf('Unique identities found: %d\n', length(faceIDs));

% ------------------------------------------------------------
% Check number of identities
% ------------------------------------------------------------

if length(faceIDs) ~= nFaces
    error('Expected %d face identities, but found %d.', ...
        nFaces, length(faceIDs));
end

% ------------------------------------------------------------
% Create face database
% ------------------------------------------------------------

faceDatabase = struct( ...
    'ID', cell(nFaces,1), ...
    'Sex', cell(nFaces,1), ...
    'NeutralFile', cell(nFaces,1), ...
    'AngryFile', cell(nFaces,1), ...
    'HappyFile', cell(nFaces,1));

% ------------------------------------------------------------
% Match each identity across the three emotion folders
% ------------------------------------------------------------

for i = 1:nFaces

    currentID = faceIDs{i};

    faceDatabase(i).ID = currentID;

    % --------------------------------------------------------
    % Determine sex
    % --------------------------------------------------------

    if strcmp(currentID(1:2), 'AF')

        faceDatabase(i).Sex = 'Female';

    elseif strcmp(currentID(1:2), 'AM')

        faceDatabase(i).Sex = 'Male';

    else

        error('Unknown sex code in identity %s.', currentID);

    end

    % --------------------------------------------------------
    % Find neutral image
    % --------------------------------------------------------

    neutralMatch = false;

    for j = 1:length(neutralNames)

        [~, nameOnly, ~] = fileparts(neutralNames{j});

        if strncmp(nameOnly, currentID, 4)

            faceDatabase(i).NeutralFile = neutralNames{j};
            neutralMatch = true;
            break;

        end

    end

    % --------------------------------------------------------
    % Find angry image
    % --------------------------------------------------------

    angryMatch = false;

    for j = 1:length(angryNames)

        [~, nameOnly, ~] = fileparts(angryNames{j});

        if strncmp(nameOnly, currentID, 4)

            faceDatabase(i).AngryFile = angryNames{j};
            angryMatch = true;
            break;

        end

    end

    % --------------------------------------------------------
    % Find happy image
    % --------------------------------------------------------

    happyMatch = false;

    for j = 1:length(happyNames)

        [~, nameOnly, ~] = fileparts(happyNames{j});

        if strncmp(nameOnly, currentID, 4)

            faceDatabase(i).HappyFile = happyNames{j};
            happyMatch = true;
            break;

        end

    end

    % --------------------------------------------------------
    % Verify all three images exist
    % --------------------------------------------------------

    if ~neutralMatch
        error('Missing NEUTRAL image for identity %s.', currentID);
    end

    if ~angryMatch
        error('Missing ANGRY image for identity %s.', currentID);
    end

    if ~happyMatch
        error('Missing HAPPY image for identity %s.', currentID);
    end

end

% ------------------------------------------------------------
% Count female and male identities
% ------------------------------------------------------------

nFemale = sum(strcmp({faceDatabase.Sex}, 'Female'));
nMale   = sum(strcmp({faceDatabase.Sex}, 'Male'));

if nFemale ~= nFemaleFaces
    error('Expected %d female identities, found %d.', ...
        nFemaleFaces, nFemale);
end

if nMale ~= nMaleFaces
    error('Expected %d male identities, found %d.', ...
        nMaleFaces, nMale);
end

% ------------------------------------------------------------
% Display database
% ------------------------------------------------------------

fprintf('\n--------------------------------------------\n');
fprintf('FACE IDENTITY DATABASE\n');
fprintf('--------------------------------------------\n\n');

fprintf('%-6s | %-8s | %-25s | %-25s | %-25s\n', ...
    'ID', 'Sex', 'Neutral', 'Angry', 'Happy');

fprintf('%s\n', repmat('-', 100, 1));

for i = 1:nFaces

    fprintf('%-6s | %-8s | %-25s | %-25s | %-25s\n', ...
        faceDatabase(i).ID, ...
        faceDatabase(i).Sex, ...
        faceDatabase(i).NeutralFile, ...
        faceDatabase(i).AngryFile, ...
        faceDatabase(i).HappyFile);

end

fprintf('\n============================================\n');
fprintf('FACE DATABASE VERIFIED SUCCESSFULLY\n');
fprintf('============================================\n\n');

fprintf('Total identities:  %d\n', nFaces);
fprintf('Female identities: %d\n', nFemale);
fprintf('Male identities:   %d\n', nMale);
fprintf('Each identity has neutral + angry + happy images.\n');



%% ============================================================
% SECTION 12: LOAD AND VERIFY FACE IMAGES
% =============================================================

fprintf('\n============================================\n');
fprintf('LOADING AND VERIFYING FACE IMAGES\n');
fprintf('============================================\n\n');

% ------------------------------------------------------------
% Create image fields in faceDatabase
% ------------------------------------------------------------

for i = 1:nFaces

    % Full file paths
    neutralPath = fullfile(neutralDir, faceDatabase(i).NeutralFile);
    angryPath   = fullfile(angryDir, faceDatabase(i).AngryFile);
    happyPath   = fullfile(happyDir, faceDatabase(i).HappyFile);

    % --------------------------------------------------------
    % Check that files exist
    % --------------------------------------------------------

    if ~exist(neutralPath, 'file')
        error('Neutral file not found: %s', neutralPath);
    end

    if ~exist(angryPath, 'file')
        error('Angry file not found: %s', angryPath);
    end

    if ~exist(happyPath, 'file')
        error('Happy file not found: %s', happyPath);
    end

    % --------------------------------------------------------
    % Read images
    % --------------------------------------------------------

    faceDatabase(i).NeutralImage = imread(neutralPath);
    faceDatabase(i).AngryImage   = imread(angryPath);
    faceDatabase(i).HappyImage   = imread(happyPath);

end

fprintf('All 36 face images loaded successfully.\n\n');

% ------------------------------------------------------------
% Check image dimensions
% ------------------------------------------------------------

fprintf('--------------------------------------------\n');
fprintf('IMAGE DIMENSIONS\n');
fprintf('--------------------------------------------\n\n');

for i = 1:nFaces

    neutralSize = size(faceDatabase(i).NeutralImage);
    angrySize   = size(faceDatabase(i).AngryImage);
    happySize   = size(faceDatabase(i).HappyImage);

    fprintf('%s:\n', faceDatabase(i).ID);

    fprintf('  Neutral: %d x %d', ...
        neutralSize(2), neutralSize(1));

    if length(neutralSize) >= 3
        fprintf(' x %d', neutralSize(3));
    end

    fprintf('\n');

    fprintf('  Angry:   %d x %d', ...
        angrySize(2), angrySize(1));

    if length(angrySize) >= 3
        fprintf(' x %d', angrySize(3));
    end

    fprintf('\n');

    fprintf('  Happy:   %d x %d', ...
        happySize(2), happySize(1));

    if length(happySize) >= 3
        fprintf(' x %d', happySize(3));
    end

    fprintf('\n\n');

end

% ------------------------------------------------------------
% Check whether dimensions are identical across emotions
% ------------------------------------------------------------

fprintf('--------------------------------------------\n');
fprintf('DIMENSION CONSISTENCY CHECK\n');
fprintf('--------------------------------------------\n\n');

dimensionProblem = false;

for i = 1:nFaces

    neutralSize = size(faceDatabase(i).NeutralImage);
    angrySize   = size(faceDatabase(i).AngryImage);
    happySize   = size(faceDatabase(i).HappyImage);

    if ~isequal(neutralSize, angrySize) || ...
       ~isequal(neutralSize, happySize)

        fprintf('WARNING: %s has different dimensions across emotions.\n', ...
            faceDatabase(i).ID);

        dimensionProblem = true;

    end

end

if dimensionProblem
    error(['Dimension inconsistencies detected across emotional versions. ' ...
           'All three emotional images for every identity should have ' ...
           'identical dimensions.']);
else
    fprintf('All identities have matching image dimensions across emotions.\n');
end

% ------------------------------------------------------------
% Check image data type
% ------------------------------------------------------------

fprintf('\n--------------------------------------------\n');
fprintf('IMAGE DATA TYPE CHECK\n');
fprintf('--------------------------------------------\n\n');

for i = 1:nFaces

    fprintf('%s: Neutral=%s | Angry=%s | Happy=%s\n', ...
        faceDatabase(i).ID, ...
        class(faceDatabase(i).NeutralImage), ...
        class(faceDatabase(i).AngryImage), ...
        class(faceDatabase(i).HappyImage));

end

% ------------------------------------------------------------
% Check RGB / grayscale
% ------------------------------------------------------------

fprintf('\n--------------------------------------------\n');
fprintf('COLOUR CHANNEL CHECK\n');
fprintf('--------------------------------------------\n\n');

for i = 1:nFaces

    neutralSize = size(faceDatabase(i).NeutralImage);
    angrySize   = size(faceDatabase(i).AngryImage);
    happySize   = size(faceDatabase(i).HappyImage);

    fprintf('%s: ', faceDatabase(i).ID);

    if length(neutralSize) == 3
        fprintf('Neutral RGB');
    else
        fprintf('Neutral grayscale');
    end

    fprintf(' | ');

    if length(angrySize) == 3
        fprintf('Angry RGB');
    else
        fprintf('Angry grayscale');
    end

    fprintf(' | ');

    if length(happySize) == 3
        fprintf('Happy RGB');
    else
        fprintf('Happy grayscale');
    end

    fprintf('\n');

end

fprintf('\n============================================\n');
fprintf('FACE IMAGE LOADING COMPLETE\n');
fprintf('============================================\n\n');


%% ============================================================
% SECTION 13: GENERATE FACE IDENTITY ORDER FOR EACH BLOCK
% =============================================================

fprintf('\n============================================\n');
fprintf('GENERATING FACE IDENTITY ORDERS\n');
fprintf('============================================\n\n');

% Each identity appears exactly 3 times per block
faceRepetitionsPerBlock = 3;

% ------------------------------------------------------------
% Create face identity order for each block
% ------------------------------------------------------------

blockFaceOrder = cell(nBlocks, 1);

for b = 1:nBlocks

    % --------------------------------------------------------
    % Create three copies of every identity
    % --------------------------------------------------------

    identityPool = repmat(1:nFaces, ...
        1, faceRepetitionsPerBlock);

    % --------------------------------------------------------
    % Randomize until no identical identities are consecutive
    % --------------------------------------------------------

    validOrder = false;

    while ~validOrder

        randomizedOrder = identityPool(randperm(length(identityPool)));

        validOrder = true;

        for k = 2:length(randomizedOrder)

            if randomizedOrder(k) == randomizedOrder(k-1)

                validOrder = false;
                break;

            end

        end

    end

    % Store order for this block
    blockFaceOrder{b} = randomizedOrder;

end

% ------------------------------------------------------------
% Verify face orders
% ------------------------------------------------------------

fprintf('Face identity orders generated for all %d blocks.\n\n', ...
    nBlocks);

faceOrderProblem = false;

for b = 1:nBlocks

    currentOrder = blockFaceOrder{b};

    % Check total presentations
    if length(currentOrder) ~= 36

        fprintf('ERROR: Block %d has %d face presentations.\n', ...
            b, length(currentOrder));

        faceOrderProblem = true;

    end

    % Check each identity occurs exactly 3 times
    for i = 1:nFaces

        count = sum(currentOrder == i);

        if count ~= faceRepetitionsPerBlock

            fprintf(['ERROR: Block %d, identity %s appears ' ...
                     '%d times.\n'], ...
                     b, faceDatabase(i).ID, count);

            faceOrderProblem = true;

        end

    end

    % Check no consecutive identity repeats
    for k = 2:length(currentOrder)

        if currentOrder(k) == currentOrder(k-1)

            fprintf(['ERROR: Block %d has consecutive identity ' ...
                     '%s at positions %d and %d.\n'], ...
                     b, ...
                     faceDatabase(currentOrder(k)).ID, ...
                     k-1, k);

            faceOrderProblem = true;

        end

    end

end

if faceOrderProblem

    error('Face identity order verification failed.');

end

% ------------------------------------------------------------
% Display first few block orders
% ------------------------------------------------------------

fprintf('--------------------------------------------\n');
fprintf('FACE ORDER PREVIEW\n');
fprintf('--------------------------------------------\n\n');

for b = 1:min(3,nBlocks)

    fprintf('Block %d: ', b);

    currentOrder = blockFaceOrder{b};

    for k = 1:length(currentOrder)

        fprintf('%s', faceDatabase(currentOrder(k)).ID);

        if k < length(currentOrder)
            fprintf(' - ');
        end

    end

    fprintf('\n\n');

end

fprintf('============================================\n');
fprintf('FACE IDENTITY ORDERS VERIFIED SUCCESSFULLY\n');
fprintf('============================================\n\n');

fprintf('Each block: 36 face presentations\n');
fprintf('Each identity: exactly 3 presentations/block\n');
fprintf('Consecutive identity repetitions: none\n');
fprintf('Block-specific randomization: yes\n');


%% ============================================================
% SECTION 14: ASSIGN EMOTIONAL FACE IMAGES TO EACH BLOCK
% =============================================================

fprintf('\n============================================\n');
fprintf('ASSIGNING EMOTIONAL FACE IMAGES\n');
fprintf('============================================\n\n');

% ------------------------------------------------------------
% Create structure for face presentations in each block
% ------------------------------------------------------------

blockFaceStimuli = cell(nBlocks, 1);

for b = 1:nBlocks

    currentEmotion = blockConditions(b).Emotion;
    currentOrder   = blockFaceOrder{b};

    % Create structure for 36 presentations
    faceTrials = struct( ...
        'Presentation', cell(1, trialsPerBlock), ...
        'IdentityIndex', cell(1, trialsPerBlock), ...
        'Identity', cell(1, trialsPerBlock), ...
        'Sex', cell(1, trialsPerBlock), ...
        'Emotion', cell(1, trialsPerBlock), ...
        'Filename', cell(1, trialsPerBlock), ...
        'Image', cell(1, trialsPerBlock));

    for p = 1:trialsPerBlock

        % Identity index from randomized order
        identityIndex = currentOrder(p);

        % Store basic information
        faceTrials(p).Presentation = p;
        faceTrials(p).IdentityIndex = identityIndex;
        faceTrials(p).Identity = faceDatabase(identityIndex).ID;
        faceTrials(p).Sex = faceDatabase(identityIndex).Sex;
        faceTrials(p).Emotion = currentEmotion;

        % ----------------------------------------------------
        % Select correct emotion
        % ----------------------------------------------------

        switch currentEmotion

            case 'Neutral'

                faceTrials(p).Filename = ...
                    faceDatabase(identityIndex).NeutralFile;

                faceTrials(p).Image = ...
                    faceDatabase(identityIndex).NeutralImage;

            case 'Angry'

                faceTrials(p).Filename = ...
                    faceDatabase(identityIndex).AngryFile;

                faceTrials(p).Image = ...
                    faceDatabase(identityIndex).AngryImage;

            case 'Happy'

                faceTrials(p).Filename = ...
                    faceDatabase(identityIndex).HappyFile;

                faceTrials(p).Image = ...
                    faceDatabase(identityIndex).HappyImage;

            otherwise

                error('Unknown emotion: %s', currentEmotion);

        end

    end

    blockFaceStimuli{b} = faceTrials;

end

fprintf('Emotional face assignment completed for all %d blocks.\n', ...
    nBlocks);

% ------------------------------------------------------------
% Verification
% ------------------------------------------------------------

fprintf('\n--------------------------------------------\n');
fprintf('FACE STIMULUS VERIFICATION\n');
fprintf('--------------------------------------------\n\n');

faceStimulusProblem = false;

for b = 1:nBlocks

    currentEmotion = blockConditions(b).Emotion;
    currentFaces   = blockFaceStimuli{b};

    % Check 36 presentations
    if length(currentFaces) ~= trialsPerBlock

        fprintf('ERROR: Block %d contains %d face presentations.\n', ...
            b, length(currentFaces));

        faceStimulusProblem = true;

    end

    % Check every presentation has correct emotion
    for p = 1:length(currentFaces)

        if ~strcmp(currentFaces(p).Emotion, currentEmotion)

            fprintf(['ERROR: Block %d, presentation %d has ' ...
                     'incorrect emotion.\n'], b, p);

            faceStimulusProblem = true;

        end

    end

end

if faceStimulusProblem

    error('Face stimulus verification failed.');

end

% ------------------------------------------------------------
% Display preview of first 3 blocks
% ------------------------------------------------------------

fprintf('--------------------------------------------\n');
fprintf('FACE STIMULUS PREVIEW\n');
fprintf('--------------------------------------------\n\n');

for b = 1:min(3,nBlocks)

    fprintf('Block %d: %s | %s | %s\n', ...
        b, ...
        blockConditions(b).RSVPLoad, ...
        blockConditions(b).Awareness, ...
        blockConditions(b).Emotion);

    currentFaces = blockFaceStimuli{b};

    for p = 1:min(10,length(currentFaces))

        fprintf('  %2d: %-5s | %-6s | %s\n', ...
            p, ...
            currentFaces(p).Identity, ...
            currentFaces(p).Sex, ...
            currentFaces(p).Filename);

    end

    fprintf('  ...\n\n');

end

fprintf('============================================\n');
fprintf('FACE STIMULUS ASSIGNMENT VERIFIED\n');
fprintf('============================================\n\n');



%% ================================================================
% SECTION 15 — DISPLAY SETUP
% Development-safe version
% ================================================================

PsychDefaultSetup(2);

screens = Screen('Screens');
screenNumber = max(screens);

% ------------------------------------------------
% DISPLAY MODE
% ------------------------------------------------
% 1 = SAFE WINDOWED DEVELOPMENT MODE
% 0 = FULLSCREEN EXPERIMENT MODE
% ------------------------------------------------

developmentMode = true;

backgroundColor = [128 128 128];

if developmentMode

    % Safe windowed PTB window.
    % This prevents PTB from trapping the entire desktop
    % while we are testing geometry/calibration code.

    testWidth  = 1200;
    testHeight = 800;

    windowRectRequested = [100 100 ...
                           100 + testWidth ...
                           100 + testHeight];

    [win, windowRect] = PsychImaging('OpenWindow', ...
        screenNumber, backgroundColor, windowRectRequested);

else

    % Fullscreen mode for the actual experiment.
    [win, windowRect] = PsychImaging('OpenWindow', ...
        screenNumber, backgroundColor);

end

% ------------------------------------------------
% FORCE PTB COLOR RANGE TO 0-255
% ------------------------------------------------

Screen('ColorRange', win, 255);

fprintf('\nPTB color range forced to 0-255.\n');

actualColorRange = Screen('ColorRange', win);

fprintf('Verified PTB color range: %.2f\n', actualColorRange);



% ------------------------------------------------
% BASIC DISPLAY INFORMATION
% ------------------------------------------------

[screenXpixels, screenYpixels] = Screen('WindowSize', win);

ifi = Screen('GetFlipInterval', win);

refreshRate = 1 / ifi;

[xCenter, yCenter] = RectCenter(windowRect);

% ------------------------------------------------
% PRINT DISPLAY INFORMATION
% ------------------------------------------------

fprintf('\n============================================\n');
fprintf('SECTION 15 — DISPLAY SETUP\n');
fprintf('============================================\n');

if developmentMode
    fprintf('Display mode       : WINDOWED DEVELOPMENT\n');
else
    fprintf('Display mode       : FULLSCREEN EXPERIMENT\n');
end

fprintf('Screen number      : %d\n', screenNumber);
fprintf('Window resolution  : %d × %d pixels\n', ...
    screenXpixels, screenYpixels);

fprintf('Window center      : X = %.1f, Y = %.1f\n', ...
    xCenter, yCenter);

fprintf('Measured IFI       : %.6f s\n', ifi);
fprintf('Measured refresh   : %.2f Hz\n', refreshRate);

fprintf('============================================\n\n');

% ------------------------------------------------
% TEST FIXATION
% ------------------------------------------------

Screen('FillRect', win, backgroundColor);

fixColor = WhiteIndex(win);

fixationSize = 20;
fixationThickness = 2;

Screen('DrawLine', win, fixColor, ...
    xCenter - fixationSize, yCenter, ...
    xCenter + fixationSize, yCenter, fixationThickness);

Screen('DrawLine', win, fixColor, ...
    xCenter, yCenter - fixationSize, ...
    xCenter, yCenter + fixationSize, fixationThickness);

Screen('Flip', win);

fprintf('Display window is open.\n');
fprintf('Press SPACE to continue.\n');

% IMPORTANT:
% Do NOT use ESC for these development tests.

while true

    [keyDown, ~, keyCode] = KbCheck;

    if keyDown

        if keyCode(KbName('SPACE'))
            break;
        end

        % Release before continuing.
        KbReleaseWait;

    end

end

Screen('FillRect', win, backgroundColor);
Screen('Flip', win);

fprintf('Section 15 test completed.\n\n');



%% ============================================================
% SECTION 16: LOAD FACE IMAGES AND CREATE PTB TEXTURES
% ============================================================

fprintf('\n============================================\n');
fprintf('LOADING FACE TEXTURES\n');
fprintf('============================================\n\n');

% ------------------------------------------------------------
% FACE DIRECTORIES
% ------------------------------------------------------------

neutralDir = 'D:\CFS\Expt_emo\Stimuli\crop_contour_blur\neutral';
angryDir   = 'D:\CFS\Expt_emo\Stimuli\crop_contour_blur\angry';
happyDir   = 'D:\CFS\Expt_emo\Stimuli\crop_contour_blur\happy';

% ------------------------------------------------------------
% GET FACE FILES
% ------------------------------------------------------------

neutralFiles = dir(fullfile(neutralDir, '*.png'));
angryFiles   = dir(fullfile(angryDir, '*.png'));
happyFiles   = dir(fullfile(happyDir, '*.png'));

fprintf('Neutral faces: %d\n', length(neutralFiles));
fprintf('Angry faces:   %d\n', length(angryFiles));
fprintf('Happy faces:   %d\n', length(happyFiles));

% Check expected number
if length(neutralFiles) ~= 12 || ...
   length(angryFiles) ~= 12 || ...
   length(happyFiles) ~= 12

    error(['Expected exactly 12 neutral, 12 angry, and 12 happy ', ...
           'face images.']);
end

% ------------------------------------------------------------
% SORT FILES ALPHANUMERICALLY
% ------------------------------------------------------------

[~, idx] = sort({neutralFiles.name});
neutralFiles = neutralFiles(idx);

[~, idx] = sort({angryFiles.name});
angryFiles = angryFiles(idx);

[~, idx] = sort({happyFiles.name});
happyFiles = happyFiles(idx);

% ------------------------------------------------------------
% CREATE TEXTURE ARRAYS
% ------------------------------------------------------------

nFaces = 12;

neutralTextures = zeros(1, nFaces);
angryTextures   = zeros(1, nFaces);
happyTextures   = zeros(1, nFaces);

% Store image dimensions
faceWidth  = zeros(1, nFaces);
faceHeight = zeros(1, nFaces);

% ------------------------------------------------------------
% LOAD NEUTRAL FACES
% ------------------------------------------------------------

fprintf('\nCreating neutral textures...\n');

for i = 1:nFaces

    img = imread(fullfile(neutralDir, neutralFiles(i).name));

    % Convert grayscale to RGB if necessary
    if ndims(img) == 2
        img = repmat(img, [1 1 3]);
    end

    % Store dimensions
    [faceHeight(i), faceWidth(i), ~] = size(img);

    % Create PTB texture
    neutralTextures(i) = Screen('MakeTexture', win, img);

    fprintf('Neutral %2d: %-30s %d x %d\n', ...
        i, neutralFiles(i).name, ...
        faceWidth(i), faceHeight(i));
end

% ------------------------------------------------------------
% LOAD ANGRY FACES
% ------------------------------------------------------------

fprintf('\nCreating angry textures...\n');

for i = 1:nFaces

    img = imread(fullfile(angryDir, angryFiles(i).name));

    if ndims(img) == 2
        img = repmat(img, [1 1 3]);
    end

    angryTextures(i) = Screen('MakeTexture', win, img);

    fprintf('Angry   %2d: %-30s\n', ...
        i, angryFiles(i).name);
end

% ------------------------------------------------------------
% LOAD HAPPY FACES
% ------------------------------------------------------------

fprintf('\nCreating happy textures...\n');

for i = 1:nFaces

    img = imread(fullfile(happyDir, happyFiles(i).name));

    if ndims(img) == 2
        img = repmat(img, [1 1 3]);
    end

    happyTextures(i) = Screen('MakeTexture', win, img);

    fprintf('Happy   %2d: %-30s\n', ...
        i, happyFiles(i).name);
end

% ------------------------------------------------------------
% VERIFY TEXTURES
% ------------------------------------------------------------

if any(neutralTextures <= 0) || ...
   any(angryTextures <= 0) || ...
   any(happyTextures <= 0)

    error('One or more face textures were not created correctly.');
end

fprintf('\nAll 36 face textures created successfully.\n');

fprintf('\nFace image dimensions:\n');
fprintf('Width:  %d pixels\n', faceWidth(1));
fprintf('Height: %d pixels\n', faceHeight(1));

fprintf('\n============================================\n');
fprintf('FACE TEXTURE SETUP COMPLETE\n');
fprintf('============================================\n\n');

fprintf('\nChecking PTB window after texture creation...\n');

openWindows = Screen('Windows');

fprintf('Open PTB objects: ');
disp(openWindows);

if ismember(win, openWindows)
    fprintf('PTB window %d is still OPEN.\n', win);
else
    error('PTB window %d is no longer open.', win);
end

fprintf('All 36 face textures remain loaded.\n');
fprintf('Section 16 completed successfully.\n');



%% ============================================================
%  SECTION 17: FACE DESTINATION RECTANGLE
%  ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('SETTING FACE DESTINATION RECTANGLE\n');
fprintf('============================================\n');

% ------------------------------------------------------------
% FACE DISPLAY SIZE
% ------------------------------------------------------------
% Temporary development size = native image dimensions.
% We will replace this with the calibrated visual-angle size
% once the final BenQ 240-Hz display is connected.
% ------------------------------------------------------------

faceWidthPx  = 283;
faceHeightPx = 337;

% ------------------------------------------------------------
% VERIFY EXPECTED IMAGE DIMENSIONS
% ------------------------------------------------------------

if faceWidthPx ~= 283 || faceHeightPx ~= 337
    error('Unexpected face dimensions.');
end

% ------------------------------------------------------------
% CENTRE THE FACE ON THE SCREEN
% ------------------------------------------------------------

faceRect = CenterRectOnPointd( ...
    [0 0 faceWidthPx faceHeightPx], ...
    xCenter, ...
    yCenter);

% ------------------------------------------------------------
% DISPLAY INFORMATION
% ------------------------------------------------------------

fprintf('Face width:  %d pixels\n', faceWidthPx);
fprintf('Face height: %d pixels\n', faceHeightPx);

fprintf('Face rectangle:\n');
fprintf('  Left   = %.1f\n', faceRect(1));
fprintf('  Top    = %.1f\n', faceRect(2));
fprintf('  Right  = %.1f\n', faceRect(3));
fprintf('  Bottom = %.1f\n', faceRect(4));

fprintf('\nFace destination rectangle created successfully.\n');
fprintf('Section 17 completed successfully.\n');



%% ============================================================
%  SECTION 18: TEST DISPLAY OF ONE FACE
%  ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('TESTING FACE DISPLAY\n');
fprintf('============================================\n');

% ------------------------------------------------------------
% BACKGROUND COLOR
% ------------------------------------------------------------

testBackground = [128 128 128];

% ------------------------------------------------------------
% CLEAR SCREEN
% ------------------------------------------------------------

Screen('FillRect', win, testBackground);

% ------------------------------------------------------------
% DRAW ONE NEUTRAL FACE
% ------------------------------------------------------------

testFace = neutralTextures(1);

Screen('DrawTexture', ...
    win, ...
    testFace, ...
    [], ...
    faceRect);

% ------------------------------------------------------------
% DISPLAY FACE
% ------------------------------------------------------------

vbl = Screen('Flip', win);

fprintf('Face displayed successfully.\n');
fprintf('VBL timestamp: %.6f\n', vbl);
fprintf('\nPress ESC to end the face display test and close PTB.\n');

% ------------------------------------------------------------
% WAIT FOR ESC
% ------------------------------------------------------------

while true

    [keyIsDown, ~, keyCode] = KbCheck;

    if keyIsDown && keyCode(escapeKey)
        break;
    end

    WaitSecs(0.01);

end

% ------------------------------------------------------------
% CLOSE PTB WINDOW
% ------------------------------------------------------------

Screen('FillRect', win, testBackground);
Screen('Flip', win);

fprintf('\nFace display test completed.\n');
fprintf('PTB window remains OPEN.\n');
fprintf('Section 18 completed successfully.\n');


%% ============================================================
%  SECTION 19: CFS MONDRIAN MASK LOADING
% =============================================================

fprintf('\n============================================\n');
fprintf('CFS MONDRIAN MASK LOADING\n');
fprintf('============================================\n\n');

%% ------------------------------------------------------------
% MASK FOLDER
% ------------------------------------------------------------

maskDir = 'D:\CFS\Expt_emo\Stimuli\CFS_Mondrian_Colored';

fprintf('Mask folder:\n%s\n\n', maskDir);

if ~exist(maskDir, 'dir')
    error('Mask folder does not exist:\n%s', maskDir);
end

%% ------------------------------------------------------------
% EXPECTED MASKS
% ------------------------------------------------------------

nMasks = 200;

maskFiles = cell(1, nMasks);

for i = 1:nMasks

    maskName = sprintf('Mondrian_%03d.png', i);
    maskPath = fullfile(maskDir, maskName);

    if ~exist(maskPath, 'file')
        error('Missing mask file:\n%s', maskPath);
    end

    maskFiles{i} = maskPath;

end

fprintf('Found all %d expected mask files.\n', nMasks);

%% ------------------------------------------------------------
% CHECK FIRST MASK
% ------------------------------------------------------------

testMask = imread(maskFiles{1});

[maskHeight, maskWidth, maskChannels] = size(testMask);

fprintf('\nFirst mask:\n');
fprintf('  File       : %s\n', ...
    maskFiles{1});
fprintf('  Width      : %d pixels\n', maskWidth);
fprintf('  Height     : %d pixels\n', maskHeight);
fprintf('  Channels   : %d\n', maskChannels);
fprintf('  Data type  : %s\n', class(testMask));

%% ------------------------------------------------------------
% CHECK ALL MASK DIMENSIONS
% ------------------------------------------------------------

fprintf('\nChecking dimensions of all masks...\n');

allSameSize = true;

for i = 1:nMasks

    img = imread(maskFiles{i});

    [h, w, c] = size(img);

    if h ~= maskHeight || w ~= maskWidth || c ~= maskChannels

        fprintf('\nWARNING: Mask %d has different dimensions!\n', i);

        fprintf('Expected: %d x %d x %d\n', ...
            maskHeight, maskWidth, maskChannels);

        fprintf('Found:    %d x %d x %d\n', ...
            h, w, c);

        allSameSize = false;

    end

end

if ~allSameSize
    error('Not all CFS masks have identical dimensions.');
end

fprintf('All %d masks have identical dimensions.\n', nMasks);

%% ------------------------------------------------------------
% CHECK COLOUR / GRAYSCALE
% ------------------------------------------------------------

if maskChannels == 3
    fprintf('\nMask type: RGB / COLOUR\n');
elseif maskChannels == 1
    fprintf('\nMask type: GRAYSCALE\n');
else
    error('Unexpected number of image channels: %d', ...
        maskChannels);
end

%% ------------------------------------------------------------
% LOAD MASKS INTO PSYCHTOOLBOX TEXTURES
% ------------------------------------------------------------

fprintf('\nOpening CFS mask textures in Psychtoolbox...\n');

cfsMaskTextures = zeros(1, nMasks);

for i = 1:nMasks

    img = imread(maskFiles{i});

    % Make sure grayscale images are converted to RGB
    % for consistent PTB texture handling.
    if ndims(img) == 2
        img = repmat(img, [1 1 3]);
    end

    cfsMaskTextures(i) = Screen('MakeTexture', win, img);

end

%% ------------------------------------------------------------
% VERIFY TEXTURE IDs
% ------------------------------------------------------------

if any(cfsMaskTextures <= 0)
    error('One or more CFS mask textures were not created correctly.');
end

fprintf('Successfully created %d PTB mask textures.\n', nMasks);

%% ------------------------------------------------------------
% SUMMARY
% ------------------------------------------------------------

fprintf('\n--------------------------------------------\n');
fprintf('CFS MASK SUMMARY\n');
fprintf('--------------------------------------------\n');

fprintf('Number of masks       : %d\n', nMasks);
fprintf('Dimensions            : %d x %d pixels\n', ...
    maskWidth, maskHeight);

fprintf('Channels              : %d\n', maskChannels);

fprintf('File format           : PNG\n');

fprintf('First file            : Mondrain_001.png\n');
fprintf('Last file             : Mondrain_200.png\n');

fprintf('PTB textures created  : %d\n', ...
    length(cfsMaskTextures));

fprintf('--------------------------------------------\n');

fprintf('\nSection 19 completed successfully.\n');
fprintf('CFS masks are loaded and ready for testing.\n');


%% ============================================================
%  SECTION 20: CFS MONDRIAN MASK DISPLAY TEST
% =============================================================

fprintf('\n============================================\n');
fprintf('CFS MONDRIAN MASK DISPLAY TEST\n');
fprintf('============================================\n\n');

%% ------------------------------------------------------------
% SELECT TEST MASK
% ------------------------------------------------------------

testMaskIndex = 1;

testMaskTexture = cfsMaskTextures(testMaskIndex);

fprintf('Testing mask: Mondrian_%03d.png\n', testMaskIndex);

%% ------------------------------------------------------------
% MASK RECTANGLE
% ------------------------------------------------------------

% Display at native pixel dimensions for this test.

maskRect = CenterRectOnPointd( ...
    [0 0 maskWidth maskHeight], ...
    xCenter, yCenter);

fprintf('Mask dimensions: %d x %d pixels\n', ...
    maskWidth, maskHeight);

fprintf('Mask position: screen centre\n');

%% ------------------------------------------------------------
% DISPLAY MASK
% ------------------------------------------------------------

Screen('FillRect', win, testBackground);

Screen('DrawTexture', ...
    win, ...
    testMaskTexture, ...
    [], ...
    maskRect);

vbl = Screen('Flip', win);

fprintf('\nMondrian mask displayed successfully.\n');
fprintf('VBL timestamp: %.6f\n', vbl);

%% ------------------------------------------------------------
% WAIT FOR ESC
% ------------------------------------------------------------

fprintf('\nPress ESC to end the mask display test.\n');

while true

    [keyIsDown, ~, keyCode] = KbCheck;

    if keyIsDown && keyCode(escapeKey)
        break;
    end

    WaitSecs(0.01);

end

%% ------------------------------------------------------------
% CLEAR SCREEN
% ------------------------------------------------------------

Screen('FillRect', win, testBackground);
Screen('Flip', win);

fprintf('\nSection 20 completed successfully.\n');
fprintf('PTB window remains OPEN.\n');


%% ============================================================
% SECTION 21: VISUAL-ANGLE CALIBRATION
% CFS FUSION FRAME + FACE GEOMETRY
% =============================================================

fprintf('\n============================================\n');
fprintf('VISUAL-ANGLE CALIBRATION\n');
fprintf('============================================\n\n');

% ------------------------------------------------------------
% DISPLAY PARAMETERS
% ------------------------------------------------------------

screenWidth_in  = 21.7;
screenHeight_in = 12.7;

screenWidth_cm  = screenWidth_in * 2.54;
screenHeight_cm = screenHeight_in * 2.54;

screenWidth_px  = 1920;
screenHeight_px = 1080;

viewingDistance_cm = 60;

fprintf('Screen: %.1f x %.1f inches\n', ...
    screenWidth_in, screenHeight_in);

fprintf('Screen: %.2f x %.2f cm\n', ...
    screenWidth_cm, screenHeight_cm);

fprintf('Resolution: %d x %d pixels\n', ...
    screenWidth_px, screenHeight_px);

fprintf('Viewing distance: %.1f cm\n\n', ...
    viewingDistance_cm);


% ------------------------------------------------------------
% PIXELS PER CM
% ------------------------------------------------------------

pixelsPerCm_horizontal = ...
    screenWidth_px / screenWidth_cm;

pixelsPerCm_vertical = ...
    screenHeight_px / screenHeight_cm;

fprintf('Pixels/cm horizontal: %.4f\n', ...
    pixelsPerCm_horizontal);

fprintf('Pixels/cm vertical: %.4f\n\n', ...
    pixelsPerCm_vertical);


% ------------------------------------------------------------
% FUSION FRAME
% ------------------------------------------------------------

fusionVisualAngle_deg = 7.8;

fusionSize_cm = ...
    2 * viewingDistance_cm * ...
    tand(fusionVisualAngle_deg / 2);

fusionWidth_px = round( ...
    fusionSize_cm * pixelsPerCm_horizontal);

fusionHeight_px = round( ...
    fusionSize_cm * pixelsPerCm_vertical);

fprintf('FUSION FRAME\n');
fprintf('Visual angle: %.2f x %.2f degrees\n', ...
    fusionVisualAngle_deg, fusionVisualAngle_deg);

fprintf('Physical size: %.3f x %.3f cm\n', ...
    fusionSize_cm, fusionSize_cm);

fprintf('Pixel size: %d x %d px\n\n', ...
    fusionWidth_px, fusionHeight_px);


% ------------------------------------------------------------
% FACE
% ------------------------------------------------------------

faceVisualAngleWidth_deg  = 3.4;
faceVisualAngleHeight_deg = 4.6;

faceWidth_cm = ...
    2 * viewingDistance_cm * ...
    tand(faceVisualAngleWidth_deg / 2);

faceHeight_cm = ...
    2 * viewingDistance_cm * ...
    tand(faceVisualAngleHeight_deg / 2);

faceWidth_px = round( ...
    faceWidth_cm * pixelsPerCm_horizontal);

faceHeight_px = round( ...
    faceHeight_cm * pixelsPerCm_vertical);

fprintf('FACE\n');
fprintf('Visual angle: %.2f x %.2f degrees\n', ...
    faceVisualAngleWidth_deg, ...
    faceVisualAngleHeight_deg);

fprintf('Physical size: %.3f x %.3f cm\n', ...
    faceWidth_cm, faceHeight_cm);

fprintf('Pixel size: %d x %d px\n\n', ...
    faceWidth_px, faceHeight_px);


% ------------------------------------------------------------
% FACE HORIZONTAL POSITION
% ------------------------------------------------------------

faceCenterOffset_deg = fusionVisualAngle_deg / 4;

faceCenterOffset_cm = ...
    viewingDistance_cm * ...
    tand(faceCenterOffset_deg);

faceCenterOffset_px = round( ...
    faceCenterOffset_cm * pixelsPerCm_horizontal);

faceCenterOffset_px = round( ...
    faceCenterOffset_cm * pixelsPerCm_horizontal);

fprintf('FACE POSITION\n');
fprintf('Face centre offset: +/- %.2f degrees\n', ...
    faceCenterOffset_deg);

fprintf('Face centre offset: +/- %.2f px\n\n', ...
    faceCenterOffset_px);


% ------------------------------------------------------------
% REPORT EXPECTED VALUES
% ------------------------------------------------------------

fprintf('--------------------------------------------\n');
fprintf('FINAL GEOMETRY\n');
fprintf('--------------------------------------------\n');

fprintf('Fusion frame : %d x %d px = %.2f x %.2f deg\n', ...
    fusionWidth_px, fusionHeight_px, ...
    fusionVisualAngle_deg, fusionVisualAngle_deg);

fprintf('Face         : %d x %d px = %.2f x %.2f deg\n', ...
    faceWidth_px, faceHeight_px, ...
    faceVisualAngleWidth_deg, ...
    faceVisualAngleHeight_deg);

fprintf('Face centre  : +/- %.2f deg horizontally\n', ...
    faceCenterOffset_deg);

fprintf('Face centre  : 0.00 deg vertically\n');

fprintf('--------------------------------------------\n\n');


%% ============================================================
% SECTION 22: CALIBRATED FUSION FRAME + FACE GEOMETRY
% ============================================================
%
% Purpose:
%   1. Define the 7.8° x 7.8° fusion field.
%   2. Define the 3.4° x 4.6° face.
%   3. Place the face at +/- 1.95° horizontally
%      within the fusion frame.
%   4. Define the neutral-gray face-side field.
%   5. Define the full-field CFS mask destination rectangle.
%
% IMPORTANT:
%   - No CFS timing is implemented here.
%   - No stereoscope left/right placement is assumed here.
%   - These rectangles are defined relative to the centre
%     of a fusion frame.
%
% ============================================================

fprintf('\n============================================\n');
fprintf('SECTION 22: FUSION FRAME GEOMETRY\n');
fprintf('============================================\n\n');


%% ------------------------------------------------------------
% 1. FUSION FRAME RECTANGLE
% ------------------------------------------------------------

% The fusion frame occupies the full calibrated
% 7.8° x 7.8° visual-angle field.

fusionFrameRect = CenterRectOnPointd( ...
    [0 0 fusionWidth_px fusionHeight_px], ...
    xCenter, ...
    yCenter);

fprintf('FUSION FRAME\n');
fprintf('  Width  = %d px\n', fusionWidth_px);
fprintf('  Height = %d px\n', fusionHeight_px);

fprintf('  Left   = %.1f\n', fusionFrameRect(1));
fprintf('  Top    = %.1f\n', fusionFrameRect(2));
fprintf('  Right  = %.1f\n', fusionFrameRect(3));
fprintf('  Bottom = %.1f\n\n', fusionFrameRect(4));


%% ------------------------------------------------------------
% 2. FACE CENTRE POSITIONS
% ------------------------------------------------------------

% The two possible face centres are located at:
%
%       -1.95°       0°       +1.95°
%          |          |          |
%          v          v          v
%
%   ---------------------------------
%   |               |               |
%   |      FACE     |     FACE      |
%   |               |               |
%   ---------------------------------
%
% relative to the centre of the 7.8° fusion frame.

leftFaceCenterX = xCenter - faceCenterOffset_px;
rightFaceCenterX = xCenter + faceCenterOffset_px;

faceCenterY = yCenter;

fprintf('FACE CENTRE POSITIONS\n');
fprintf('  Left  face centre = %.1f px\n', leftFaceCenterX);
fprintf('  Right face centre = %.1f px\n', rightFaceCenterX);
fprintf('  Vertical centre   = %.1f px\n\n', faceCenterY);


%% ------------------------------------------------------------
% 3. FACE RECTANGLES
% ------------------------------------------------------------

% Face dimensions correspond to:
%
%   Width  = 3.4°
%   Height = 4.6°
%
% converted to calibrated pixel dimensions in Section 21.

leftFaceRect = CenterRectOnPointd( ...
    [0 0 faceWidth_px faceHeight_px], ...
    leftFaceCenterX, ...
    faceCenterY);

rightFaceRect = CenterRectOnPointd( ...
    [0 0 faceWidth_px faceHeight_px], ...
    rightFaceCenterX, ...
    faceCenterY);

fprintf('FACE RECTANGLES\n');

fprintf('Left face:\n');
fprintf('  Left   = %.1f\n', leftFaceRect(1));
fprintf('  Top    = %.1f\n', leftFaceRect(2));
fprintf('  Right  = %.1f\n', leftFaceRect(3));
fprintf('  Bottom = %.1f\n\n', leftFaceRect(4));

fprintf('Right face:\n');
fprintf('  Left   = %.1f\n', rightFaceRect(1));
fprintf('  Top    = %.1f\n', rightFaceRect(2));
fprintf('  Right  = %.1f\n', rightFaceRect(3));
fprintf('  Bottom = %.1f\n\n', rightFaceRect(4));


%% ------------------------------------------------------------
% 4. FULL CFS MASK RECTANGLE
% ------------------------------------------------------------

% The Mondrian mask must cover the entire 7.8° x 7.8°
% fusion field.

leftCFSRect = fusionFrameRect;
rightCFSRect = fusionFrameRect;

fprintf('CFS MASK RECTANGLE\n');
fprintf('  Width  = %d px\n', fusionWidth_px);
fprintf('  Height = %d px\n', fusionHeight_px);
fprintf('  Visual angle = %.2f° x %.2f°\n\n', ...
    fusionVisualAngle_deg, ...
    fusionVisualAngle_deg);


%% ------------------------------------------------------------
% 5. NEUTRAL-GRAY FACE-SIDE FUSION FIELD
% ------------------------------------------------------------

% The face-presenting eye receives a neutral-gray field
% covering the complete 7.8° x 7.8° fusion area.
%
% The face is then drawn on top of this gray field.
%
% Use 128 rather than 127.5 because standard 8-bit RGB
% textures cannot represent 127.5 exactly.

faceFieldGray = uint8(128);

fprintf('FACE-SIDE FUSION FIELD\n');
fprintf('  RGB value = [%d %d %d]\n', ...
    faceFieldGray, faceFieldGray, faceFieldGray);


%% ------------------------------------------------------------
% 6. CREATE NEUTRAL-GRAY FUSION-FIELD TEXTURE
% ------------------------------------------------------------

% Create an RGB image exactly matching the calibrated
% fusion-frame pixel dimensions.

faceFieldImage = repmat( ...
    faceFieldGray, ...
    [fusionHeight_px fusionWidth_px 3]);

faceFieldTexture = Screen('MakeTexture', ...
    win, ...
    faceFieldImage);

if faceFieldTexture <= 0
    error('Failed to create the neutral-gray face-field texture.');
end

fprintf('Neutral-gray face-field texture created.\n');


%% ------------------------------------------------------------
% 7. VERIFY GEOMETRY NUMERICALLY
% ------------------------------------------------------------

fprintf('\n--------------------------------------------\n');
fprintf('GEOMETRY VERIFICATION\n');
fprintf('--------------------------------------------\n\n');

% Verify that the face is centred vertically.

actualLeftFaceCenterX = ...
    (leftFaceRect(1) + leftFaceRect(3)) / 2;

actualRightFaceCenterX = ...
    (rightFaceRect(1) + rightFaceRect(3)) / 2;

actualLeftFaceCenterY = ...
    (leftFaceRect(2) + leftFaceRect(4)) / 2;

actualRightFaceCenterY = ...
    (rightFaceRect(2) + rightFaceRect(4)) / 2;

fprintf('Requested left face centre : %.2f px\n', ...
    leftFaceCenterX);

fprintf('Actual left face centre    : %.2f px\n\n', ...
    actualLeftFaceCenterX);

fprintf('Requested right face centre: %.2f px\n', ...
    rightFaceCenterX);

fprintf('Actual right face centre   : %.2f px\n\n', ...
    actualRightFaceCenterX);

fprintf('Requested vertical centre  : %.2f px\n', ...
    faceCenterY);

fprintf('Actual left vertical centre : %.2f px\n', ...
    actualLeftFaceCenterY);

fprintf('Actual right vertical centre: %.2f px\n\n', ...
    actualRightFaceCenterY);


%% ------------------------------------------------------------
% 8. FINAL GEOMETRY SUMMARY
% ------------------------------------------------------------

fprintf('--------------------------------------------\n');
fprintf('FINAL SECTION 22 GEOMETRY\n');
fprintf('--------------------------------------------\n');

fprintf('Fusion field : %d x %d px\n', ...
    fusionWidth_px, fusionHeight_px);

fprintf('Fusion field : %.2f° x %.2f°\n', ...
    fusionVisualAngle_deg, ...
    fusionVisualAngle_deg);

fprintf('Face         : %d x %d px\n', ...
    faceWidth_px, ...
    faceHeight_px);

fprintf('Face         : %.2f° x %.2f°\n', ...
    faceVisualAngleWidth_deg, ...
    faceVisualAngleHeight_deg);

fprintf('Face centre offset: +/- %.2f°\n', ...
    faceCenterOffset_deg);

fprintf('Face centre offset: +/- %d px\n', ...
    faceCenterOffset_px);

fprintf('Face-field gray: [%d %d %d]\n', ...
    faceFieldGray, faceFieldGray, faceFieldGray);

fprintf('--------------------------------------------\n');

fprintf('\nSection 22 completed successfully.\n');
fprintf('No CFS timing has been implemented.\n');
fprintf('No stereoscope eye assignment has been implemented.\n');



%% ================================================================
% SECTION 23: CALIBRATED GEOMETRY TEST
%
% Purpose:
%   Verify the calibrated size and position of the face within
%   a single 7.8° × 7.8° fusion frame.
%
%   LEFT test:
%       Face centered at -1.95° horizontally
%
%   RIGHT test:
%       Face centered at +1.95° horizontally
%
% This section tests SPATIAL GEOMETRY ONLY.
% No CFS timing.
% No dichoptic presentation.
% No stereoscope calibration.
% ================================================================

fprintf('\n============================================================\n');
fprintf('SECTION 23: CALIBRATED GEOMETRY TEST\n');
fprintf('============================================================\n\n');

%% ------------------------------------------------
% Display parameters
% ------------------------------------------------

geometryTestBackground = [128 128 128];

fprintf('Fusion field: %d x %d px\n', ...
    fusionWidth_px, fusionHeight_px);

fprintf('Face: %d x %d px\n', ...
    faceWidth_px, faceHeight_px);

fprintf('Face centre offset: +/- %.2f degrees\n', ...
    faceCenterOffset_deg);

fprintf('Face centre offset: +/- %d px\n\n', ...
    faceCenterOffset_px);

%% ------------------------------------------------
% Create / verify face-field texture
% ------------------------------------------------

% The face-field texture is a 7.8° × 7.8° neutral-gray field.
% It is used only to make the spatial extent of the fusion
% frame visible during this geometry test.

if ~exist('faceFieldTexture', 'var') || ...
        ~Screen('WindowKind', faceFieldTexture)

    faceFieldGray = uint8(128);

    faceFieldImage = repmat( ...
        faceFieldGray, ...
        [fusionHeight_px fusionWidth_px 3]);

    faceFieldTexture = Screen('MakeTexture', ...
        win, ...
        faceFieldImage);

end

%% ------------------------------------------------
% Prepare test state
% ------------------------------------------------

abortGeometryTest = false;

%% ================================================================
% LEFT-POSITION FACE
% ================================================================

fprintf('Displaying LEFT-position face.\n');
fprintf('Press SPACE to continue to RIGHT-position face.\n');
fprintf('Press ESC to abort the test.\n\n');

Screen('FillRect', ...
    win, ...
    geometryTestBackground);

Screen('DrawTexture', ...
    win, ...
    faceFieldTexture, ...
    [], ...
    fusionFrameRect);

Screen('DrawTexture', ...
    win, ...
    neutralTextures(1), ...
    [], ...
    leftFaceRect);

Screen('Flip', win);

KbReleaseWait;

while true

    [keyDown, ~, keyCode] = KbCheck;

    if keyDown

        if keyCode(escapeKey)

            abortGeometryTest = true;
            KbReleaseWait;
            break;

        elseif keyCode(KbName('SPACE'))

            KbReleaseWait;
            break;

        end

    end

end

%% ------------------------------------------------
% Abort handling
% ------------------------------------------------

if abortGeometryTest

    Screen('FillRect', win, [0 0 0]);
    Screen('Flip', win);

    fprintf('\nGeometry test aborted by user.\n');
    fprintf('PTB window remains OPEN.\n\n');

else

    %% ============================================================
    % RIGHT-POSITION FACE
    % ============================================================

    fprintf('Displaying RIGHT-position face.\n');
    fprintf('Press SPACE to finish the geometry test.\n');
    fprintf('Press ESC to abort the test.\n\n');

    Screen('FillRect', ...
        win, ...
        geometryTestBackground);

    Screen('DrawTexture', ...
        win, ...
        faceFieldTexture, ...
        [], ...
        fusionFrameRect);

    Screen('DrawTexture', ...
        win, ...
        neutralTextures(1), ...
        [], ...
        rightFaceRect);

    Screen('Flip', win);

    KbReleaseWait;

    while true

        [keyDown, ~, keyCode] = KbCheck;

        if keyDown

            if keyCode(escapeKey)

                abortGeometryTest = true;
                KbReleaseWait;
                break;

            elseif keyCode(KbName('SPACE'))

                KbReleaseWait;
                break;

            end

        end

    end

    %% ------------------------------------------------
    % Finish / abort
    % ------------------------------------------------

    Screen('FillRect', win, [0 0 0]);
    Screen('Flip', win);

    if abortGeometryTest

        fprintf('\nGeometry test aborted by user.\n');
        fprintf('PTB window remains OPEN.\n\n');

    else

        fprintf('\nGeometry test completed successfully.\n\n');

        fprintf('Final geometry:\n');
        fprintf('  Fusion field:       %d × %d px\n', ...
            fusionWidth_px, fusionHeight_px);

        fprintf('  Face:                %d × %d px\n', ...
            faceWidth_px, faceHeight_px);

        fprintf('  Face offset:         ±%.2f°\n', ...
            faceCenterOffset_deg);

        fprintf('  Face offset:         ±%d px\n\n', ...
            faceCenterOffset_px);

    end

end


%% ================================================================
% SECTION 24 — TWO-FRAME GEOMETRY TEST
%
% Purpose:
%   Display two physical fusion frames at a fixed initial separation.
%
% Geometry:
%   Fusion field       = 7.8 deg × 7.8 deg
%   Noise contour      = 0.20 deg wide
%   Noise element      = 1 screen pixel
%   Outer red border   = 0.05 deg
%
% The SAME noise pattern is displayed in both physical frames.
% The central fusion field is neutral gray.
%
% SPACE = continue to Section 25
% ================================================================

fprintf('\n============================================================\n');
fprintf('SECTION 24 — TWO-FRAME GEOMETRY TEST\n');
fprintf('============================================================\n');

%% Fixed initial separation for calibration

frameSeparation_px = 500;

%% ------------------------------------------------
% Convert contour/border specifications to pixels
% -------------------------------------------------

contourWidth_deg = 0.20;
redBorder_deg    = 0.05;

contourWidth_px = max(1, round( ...
    2 * viewingDistance_cm * tand(contourWidth_deg / 2) ...
    * pixelsPerCm_horizontal));

redBorder_px = max(1, round( ...
    2 * viewingDistance_cm * tand(redBorder_deg / 2) ...
    * pixelsPerCm_horizontal));

noiseElement_px = 1;

fprintf('Fusion field       : %.2f deg\n', fusionVisualAngle_deg);
fprintf('Contour width      : %.2f deg = %d px\n', ...
    contourWidth_deg, contourWidth_px);
fprintf('Noise element      : %d px\n', noiseElement_px);
fprintf('Red border width   : %.2f deg = %d px\n', ...
    redBorder_deg, redBorder_px);
fprintf('Initial separation : %d px\n', frameSeparation_px);

%% ------------------------------------------------
% Dimensions of complete frame including contour
% -------------------------------------------------

outerWidth_px  = fusionWidth_px  + 2 * contourWidth_px;
outerHeight_px = fusionHeight_px + 2 * contourWidth_px;

%% ------------------------------------------------
% Create ONE fine-grained noise image
%
% Each image pixel = one screen pixel when drawn
% to the same-sized destination rectangle.
% -------------------------------------------------

rng(12345);

noisePattern = randi([0 1], ...
    outerHeight_px, outerWidth_px);

noiseImage = uint8(noisePattern * 255);

% Convert grayscale to RGB
noiseImageRGB = repmat(noiseImage, [1 1 3]);

calibrationNoiseTexture = Screen('MakeTexture', ...
    win, noiseImageRGB);

%% ------------------------------------------------
% Neutral gray fusion-field color
% -------------------------------------------------

fusionGray = [128 128 128];

%% ------------------------------------------------
% Fixation cross
% -------------------------------------------------

crossSize_px = max(4, round( ...
    0.10 * 2 * viewingDistance_cm * tand(0.5) ...
    * pixelsPerCm_horizontal));

crossLineWidth_px = max(1, round(0.02 * ...
    2 * viewingDistance_cm * tand(0.5) ...
    * pixelsPerCm_horizontal));

%% ------------------------------------------------
% Calculate frame locations
% -------------------------------------------------

leftFrameCenterX  = xCenter - frameSeparation_px / 2;
rightFrameCenterX = xCenter + frameSeparation_px / 2;

leftOuterRect = CenterRectOnPointd( ...
    [0 0 outerWidth_px outerHeight_px], ...
    leftFrameCenterX, yCenter);

rightOuterRect = CenterRectOnPointd( ...
    [0 0 outerWidth_px outerHeight_px], ...
    rightFrameCenterX, yCenter);

leftFusionRect = CenterRectOnPointd( ...
    [0 0 fusionWidth_px fusionHeight_px], ...
    leftFrameCenterX, yCenter);

rightFusionRect = CenterRectOnPointd( ...
    [0 0 fusionWidth_px fusionHeight_px], ...
    rightFrameCenterX, yCenter);

%% ------------------------------------------------
% Display fixed geometry
% -------------------------------------------------

Screen('FillRect', win, backgroundColor);

% Fine identical noise contour
Screen('DrawTexture', win, calibrationNoiseTexture, ...
    [], leftOuterRect);

Screen('DrawTexture', win, calibrationNoiseTexture, ...
    [], rightOuterRect);

% Neutral-gray fusion fields
Screen('FillRect', win, fusionGray, leftFusionRect);
Screen('FillRect', win, fusionGray, rightFusionRect);

% Red outer borders
Screen('FrameRect', win, [255 0 0], ...
    leftOuterRect, redBorder_px);

Screen('FrameRect', win, [255 0 0], ...
    rightOuterRect, redBorder_px);

% Identical fixation crosses
Screen('DrawLine', win, [255 255 255], ...
    leftFrameCenterX - crossSize_px, yCenter, ...
    leftFrameCenterX + crossSize_px, yCenter, ...
    crossLineWidth_px);

Screen('DrawLine', win, [255 255 255], ...
    leftFrameCenterX, yCenter - crossSize_px, ...
    leftFrameCenterX, yCenter + crossSize_px, ...
    crossLineWidth_px);

Screen('DrawLine', win, [255 255 255], ...
    rightFrameCenterX - crossSize_px, yCenter, ...
    rightFrameCenterX + crossSize_px, yCenter, ...
    crossLineWidth_px);

Screen('DrawLine', win, [255 255 255], ...
    rightFrameCenterX, yCenter - crossSize_px, ...
    rightFrameCenterX, yCenter + crossSize_px, ...
    crossLineWidth_px);

% Information text
infoText = sprintf( ...
    'Fixed geometry | Separation = %d px\n\nPress SPACE to continue', ...
    frameSeparation_px);

DrawFormattedText(win, infoText, ...
    'center', windowRect(4) - 70, ...
    [255 255 255]);

Screen('Flip', win);

%% ------------------------------------------------
% Wait for SPACE
% -------------------------------------------------

while true

    [keyDown, ~, keyCode] = KbCheck;

    if keyDown

        if keyCode(KbName('SPACE'))
            KbReleaseWait;
            WaitSecs(0.15);
            break;
        end

        KbReleaseWait;

    end

end

fprintf('Section 24 completed.\n');


%% ================================================================
% SECTION 25 — STEREOSCOPE FUSION CALIBRATION
%
% Controls:
%   LEFT  = -1 px
%   RIGHT = +1 px
%   DOWN  = -5 px
%   UP    = +5 px
%   SPACE = accept
%
% The two physical fusion frames move horizontally only.
% The same fine noise texture is used in both frames.
% ================================================================

fprintf('\n============================================================\n');
fprintf('SECTION 25 — STEREOSCOPE FUSION CALIBRATION\n');
fprintf('============================================================\n');

%% ------------------------------------------------
% Clear any key state left from Section 24
% -------------------------------------------------

KbReleaseWait;
WaitSecs(0.20);

%% ------------------------------------------------
% Define keyboard keys
% -------------------------------------------------

leftKey  = KbName('LeftArrow');
rightKey = KbName('RightArrow');
upKey    = KbName('UpArrow');
downKey  = KbName('DownArrow');
spaceKey = KbName('SPACE');

%% ------------------------------------------------
% Initial frame separation
% -------------------------------------------------

frameSeparation_px = 500;

fprintf('Initial frame separation: %d px\n', ...
    frameSeparation_px);

fprintf('Controls:\n');
fprintf('  LEFT  = -1 px\n');
fprintf('  RIGHT = +1 px\n');
fprintf('  DOWN  = -5 px\n');
fprintf('  UP    = +5 px\n');
fprintf('  SPACE = accept\n\n');

%% ------------------------------------------------
% Acceptance flag
% -------------------------------------------------

calibrationAccepted = false;

%% ================================================================
% CALIBRATION LOOP
% ================================================================

while ~calibrationAccepted

    %% ------------------------------------------------
    % Calculate current frame centers
    % -------------------------------------------------

    leftFrameCenterX = ...
        xCenter - frameSeparation_px / 2;

    rightFrameCenterX = ...
        xCenter + frameSeparation_px / 2;

    %% ------------------------------------------------
    % Calculate outer frame rectangles
    % -------------------------------------------------

    leftOuterRect = CenterRectOnPointd( ...
        [0 0 outerWidth_px outerHeight_px], ...
        leftFrameCenterX, yCenter);

    rightOuterRect = CenterRectOnPointd( ...
        [0 0 outerWidth_px outerHeight_px], ...
        rightFrameCenterX, yCenter);

    %% ------------------------------------------------
    % Calculate central fusion-field rectangles
    % -------------------------------------------------

    leftFusionRect = CenterRectOnPointd( ...
        [0 0 fusionWidth_px fusionHeight_px], ...
        leftFrameCenterX, yCenter);

    rightFusionRect = CenterRectOnPointd( ...
        [0 0 fusionWidth_px fusionHeight_px], ...
        rightFrameCenterX, yCenter);

    %% ------------------------------------------------
    % Draw background
    % -------------------------------------------------

    Screen('FillRect', win, backgroundColor);

    %% ------------------------------------------------
    % Draw identical fine noise contours
    % -------------------------------------------------

    Screen('DrawTexture', win, calibrationNoiseTexture, ...
        [], leftOuterRect);

    Screen('DrawTexture', win, calibrationNoiseTexture, ...
        [], rightOuterRect);

    %% ------------------------------------------------
    % Draw gray central fusion fields
    % -------------------------------------------------

    Screen('FillRect', win, fusionGray, leftFusionRect);
    Screen('FillRect', win, fusionGray, rightFusionRect);

    %% ------------------------------------------------
    % Draw red outer borders
    % -------------------------------------------------

    Screen('FrameRect', win, [255 0 0], ...
        leftOuterRect, redBorder_px);

    Screen('FrameRect', win, [255 0 0], ...
        rightOuterRect, redBorder_px);

    %% ------------------------------------------------
    % Draw fixation cross — left frame
    % -------------------------------------------------

    Screen('DrawLine', win, [255 255 255], ...
        leftFrameCenterX - crossSize_px, yCenter, ...
        leftFrameCenterX + crossSize_px, yCenter, ...
        crossLineWidth_px);

    Screen('DrawLine', win, [255 255 255], ...
        leftFrameCenterX, yCenter - crossSize_px, ...
        leftFrameCenterX, yCenter + crossSize_px, ...
        crossLineWidth_px);

    %% ------------------------------------------------
    % Draw fixation cross — right frame
    % -------------------------------------------------

    Screen('DrawLine', win, [255 255 255], ...
        rightFrameCenterX - crossSize_px, yCenter, ...
        rightFrameCenterX + crossSize_px, yCenter, ...
        crossLineWidth_px);

    Screen('DrawLine', win, [255 255 255], ...
        rightFrameCenterX, yCenter - crossSize_px, ...
        rightFrameCenterX, yCenter + crossSize_px, ...
        crossLineWidth_px);

    %% ------------------------------------------------
    % Display calibration instructions
    % -------------------------------------------------

    calibrationText = sprintf([ ...
        'STEREOSCOPE CALIBRATION\n\n' ...
        'Frame separation: %d px\n\n' ...
        'LEFT / RIGHT  = 1 px\n' ...
        'UP / DOWN     = 5 px\n\n' ...
        'Adjust until the two frames fuse.\n' ...
        'Press SPACE when correct.'], ...
        frameSeparation_px);

    DrawFormattedText(win, calibrationText, ...
        'center', windowRect(4) - 130, ...
        [255 255 255]);

    %% ------------------------------------------------
    % Flip display
    % -------------------------------------------------

    Screen('Flip', win);

    %% ------------------------------------------------
    % Wait for one key press
    % -------------------------------------------------

    keyProcessed = false;

    while ~keyProcessed

        [keyDown, ~, keyCode] = KbCheck;

        if keyDown

            %% LEFT = decrease separation by 1 px

            if keyCode(leftKey)

                frameSeparation_px = ...
                    max(outerWidth_px + 10, ...
                    frameSeparation_px - 1);

                keyProcessed = true;

            %% RIGHT = increase separation by 1 px

            elseif keyCode(rightKey)

                frameSeparation_px = ...
                    frameSeparation_px + 1;

                keyProcessed = true;

            %% UP = increase separation by 5 px

            elseif keyCode(upKey)

                frameSeparation_px = ...
                    frameSeparation_px + 5;

                keyProcessed = true;

            %% DOWN = decrease separation by 5 px

            elseif keyCode(downKey)

                frameSeparation_px = ...
                    max(outerWidth_px + 10, ...
                    frameSeparation_px - 5);

                keyProcessed = true;

            %% SPACE = accept

            elseif keyCode(spaceKey)

                calibrationAccepted = true;
                keyProcessed = true;

            end

            %% Wait until the physical key is released

            KbReleaseWait;

        end

    end

end

%% ================================================================
% CALIBRATION ACCEPTED
% ================================================================

calibratedFrameSeparation_px = frameSeparation_px;

frameSeparation_cm = ...
    calibratedFrameSeparation_px / pixelsPerCm_horizontal;

calibratedFrameSeparation_deg = ...
    2 * atand(frameSeparation_cm / ...
    (2 * viewingDistance_cm));

fprintf('\nCalibration ACCEPTED.\n');

fprintf('Final frame separation = %d px\n', ...
    calibratedFrameSeparation_px);

fprintf('Approximate separation = %.2f cm\n', ...
    frameSeparation_cm);

fprintf('Approximate separation = %.3f deg\n', ...
    calibratedFrameSeparation_deg);

fprintf('Stored calibrated separation: %d px\n', ...
    calibratedFrameSeparation_px);

%% ------------------------------------------------
% Close calibration noise texture
% -------------------------------------------------

Screen('Close', calibrationNoiseTexture);

fprintf('Section 25 completed.\n');


%% ================================================================
% SECTION 26 — BLOCK-WISE STEREOSCOPE CALIBRATION STORAGE
%
% Creates a structure for storing the calibrated physical separation
% independently for every block.
%
% This does NOT run the calibration yet.
% It only prepares the storage that the final experiment will use.
%
% ================================================================

fprintf('\n============================================\n');
fprintf('SECTION 26 — CALIBRATION STORAGE\n');
fprintf('============================================\n');

%% ------------------------------------------------
% CREATE CALIBRATION STRUCTURE
% -------------------------------------------------

blockCalibration = struct();

blockCalibration.Block = ...
    (1:nBlocks)';

blockCalibration.FrameSeparation_px = ...
    nan(nBlocks,1);

%% ------------------------------------------------
% OPTIONAL: STORE CALIBRATION IN DEGREES
%
% This is useful for checking/reproducibility.
% The physical adjustment itself is performed in pixels.
% -------------------------------------------------

blockCalibration.FrameSeparation_deg = ...
    nan(nBlocks,1);

%% ------------------------------------------------
% STORE PARTICIPANT ID
% -------------------------------------------------

blockCalibration.ParticipantID = ...
    repmat({participantID}, nBlocks, 1);

%% ------------------------------------------------
% VERIFY
% -------------------------------------------------

fprintf('Participant: %s\n', participantID);
fprintf('Number of blocks: %d\n\n', nBlocks);

fprintf('Calibration storage created:\n\n');

disp(blockCalibration);

fprintf('Section 26 completed.\n\n');


%% ================================================================
% SECTION 27 — BLOCK-WISE STEREOSCOPE CALIBRATION
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('SECTION 27 — BLOCK-WISE STEREOSCOPE CALIBRATION\n');
fprintf('============================================================\n');

%% ------------------------------------------------
% 27.1 — Calibration colours
% ------------------------------------------------

calibrationBackground = [128 128 128];
calibrationFusionGray = [128 128 128];
calibrationRed        = [255 0 0];
calibrationBlack      = [0 0 0];

%% ------------------------------------------------
% 27.2 — Create calibration noise texture
% ------------------------------------------------

rng(12345);

outerWidth_px  = fusionWidth_px  + 2*contourWidth_px;
outerHeight_px = fusionHeight_px + 2*contourWidth_px;

noisePattern = randi([0 1], ...
    outerHeight_px, outerWidth_px);

noiseImage = uint8(noisePattern * 255);

noiseImageRGB = repmat(noiseImage, [1 1 3]);

blockCalibrationNoiseTexture = Screen('MakeTexture', ...
    win, noiseImageRGB);

%% ------------------------------------------------
% 27.3 — Calibration controls
% ------------------------------------------------

initialFrameSeparation_px = 500;

leftKey  = KbName('LeftArrow');
rightKey = KbName('RightArrow');
upKey    = KbName('UpArrow');
downKey  = KbName('DownArrow');
spaceKey = KbName('SPACE');

%% ------------------------------------------------
% 27.4 — Calibrate at beginning of every block
% ------------------------------------------------

for b = 1:nBlocks

    fprintf('\n');
    fprintf('BLOCK %d OF %d — STEREOSCOPE CALIBRATION\n', ...
        b, nBlocks);
    fprintf('------------------------------------------------------------\n');

    % ------------------------------------------------
    % Starting separation
    % ------------------------------------------------

    if b == 1

        frameSeparation_px = initialFrameSeparation_px;

    else

        frameSeparation_px = ...
            blockCalibration.FrameSeparation_px(b-1);

    end

    KbReleaseWait;
    WaitSecs(0.20);

    calibrationAccepted = false;

    %% ------------------------------------------------
    % Calibration loop
    % ------------------------------------------------

    while ~calibrationAccepted

        % ------------------------------------------------
        % Frame centres
        % ------------------------------------------------

        leftFrameCenterX = ...
            xCenter - frameSeparation_px/2;

        rightFrameCenterX = ...
            xCenter + frameSeparation_px/2;

        % ------------------------------------------------
        % Outer rectangles
        % ------------------------------------------------

        leftOuterRect = CenterRectOnPointd( ...
            [0 0 outerWidth_px outerHeight_px], ...
            leftFrameCenterX, yCenter);

        rightOuterRect = CenterRectOnPointd( ...
            [0 0 outerWidth_px outerHeight_px], ...
            rightFrameCenterX, yCenter);

        % ------------------------------------------------
        % Fusion rectangles
        % ------------------------------------------------

        leftFusionRect = CenterRectOnPointd( ...
            [0 0 fusionWidth_px fusionHeight_px], ...
            leftFrameCenterX, yCenter);

        rightFusionRect = CenterRectOnPointd( ...
            [0 0 fusionWidth_px fusionHeight_px], ...
            rightFrameCenterX, yCenter);

        % ------------------------------------------------
        % CLEAR ENTIRE WINDOW
        % ------------------------------------------------

        Screen('FillRect', ...
            win, ...
            calibrationBackground);

        % ------------------------------------------------
        % BLACK/WHITE NOISE CONTOURS
        % ------------------------------------------------

        Screen('DrawTexture', ...
            win, ...
            blockCalibrationNoiseTexture, ...
            [], ...
            leftOuterRect);

        Screen('DrawTexture', ...
            win, ...
            blockCalibrationNoiseTexture, ...
            [], ...
            rightOuterRect);

        % ------------------------------------------------
        % GRAY FUSION FIELDS
        % ------------------------------------------------

        Screen('FillRect', ...
            win, ...
            calibrationFusionGray, ...
            leftFusionRect);

        Screen('FillRect', ...
            win, ...
            calibrationFusionGray, ...
            rightFusionRect);

        % ------------------------------------------------
        % RED OUTER BORDER
        % ------------------------------------------------

        Screen('FrameRect', ...
            win, ...
            calibrationRed, ...
            leftOuterRect, ...
            redBorder_px);

        Screen('FrameRect', ...
            win, ...
            calibrationRed, ...
            rightOuterRect, ...
            redBorder_px);

        % ------------------------------------------------
        % FIXATION CROSS SIZE
        % ------------------------------------------------

        crossSize_px  = 10;
        crossWidth_px = 2;

        % ------------------------------------------------
        % LEFT FIXATION CROSS
        % ------------------------------------------------

        Screen('FillRect', ...
            win, ...
            calibrationBlack, ...
            [leftFrameCenterX - crossSize_px, ...
             yCenter - crossWidth_px/2, ...
             leftFrameCenterX + crossSize_px, ...
             yCenter + crossWidth_px/2]);

        Screen('FillRect', ...
            win, ...
            calibrationBlack, ...
            [leftFrameCenterX - crossWidth_px/2, ...
             yCenter - crossSize_px, ...
             leftFrameCenterX + crossWidth_px/2, ...
             yCenter + crossSize_px]);

        % ------------------------------------------------
        % RIGHT FIXATION CROSS
        % ------------------------------------------------

        Screen('FillRect', ...
            win, ...
            calibrationBlack, ...
            [rightFrameCenterX - crossSize_px, ...
             yCenter - crossWidth_px/2, ...
             rightFrameCenterX + crossSize_px, ...
             yCenter + crossWidth_px/2]);

        Screen('FillRect', ...
            win, ...
            calibrationBlack, ...
            [rightFrameCenterX - crossWidth_px/2, ...
             yCenter - crossSize_px, ...
             rightFrameCenterX + crossWidth_px/2, ...
             yCenter + crossSize_px]);

        % ------------------------------------------------
        % CALIBRATION INFORMATION
        % ------------------------------------------------

        separation_cm = ...
            frameSeparation_px / pixelsPerCm_horizontal;

        separation_deg = ...
            2 * atand( ...
            separation_cm / ...
            (2 * viewingDistance_cm));

        instructionText = sprintf( ...
    ['BLOCK %d/%d    Separation: %d px (%.2f cm, %.2f deg)\n' ...
     'LEFT/RIGHT = 1 px    UP/DOWN = 5 px    SPACE = ACCEPT'], ...
    b, ...
    nBlocks, ...
    frameSeparation_px, ...
    separation_cm, ...
    separation_deg);

        DrawFormattedText( ...
            win, ...
            instructionText, ...
            'center', ...
            20, ...
            calibrationBlack);

        % ------------------------------------------------
        % FLIP TO SCREEN
        % ------------------------------------------------

        Screen('Flip', win);

        % ------------------------------------------------
        % WAIT FOR ONE RESPONSE
        % ------------------------------------------------

        keyProcessed = false;

        while ~keyProcessed

            [keyDown, ~, keyCode] = KbCheck;

            if keyDown

                if keyCode(leftKey)

                    frameSeparation_px = max( ...
                        outerWidth_px + 10, ...
                        frameSeparation_px - 1);

                    keyProcessed = true;

                elseif keyCode(rightKey)

                    frameSeparation_px = ...
                        frameSeparation_px + 1;

                    keyProcessed = true;

                elseif keyCode(upKey)

                    frameSeparation_px = ...
                        frameSeparation_px + 5;

                    keyProcessed = true;

                elseif keyCode(downKey)

                    frameSeparation_px = max( ...
                        outerWidth_px + 10, ...
                        frameSeparation_px - 5);

                    keyProcessed = true;

                elseif keyCode(spaceKey)

                    calibrationAccepted = true;
                    keyProcessed = true;

                end

                KbReleaseWait;

            end

        end

    end

    %% ------------------------------------------------
    % 27.5 — Store accepted calibration
    % ------------------------------------------------

    blockCalibration.FrameSeparation_px(b) = ...
        frameSeparation_px;

    frameSeparation_cm = ...
        frameSeparation_px / pixelsPerCm_horizontal;

    blockCalibration.FrameSeparation_deg(b) = ...
        2 * atand( ...
        frameSeparation_cm / ...
        (2 * viewingDistance_cm));

    fprintf('Calibration ACCEPTED.\n');
    fprintf('Final separation = %d px\n', ...
        frameSeparation_px);

    fprintf('Approximate separation = %.2f cm\n', ...
        frameSeparation_cm);

    fprintf('Approximate separation = %.3f deg\n', ...
        blockCalibration.FrameSeparation_deg(b));

end

%% ------------------------------------------------
% 27.6 — Close calibration texture
% ------------------------------------------------

Screen('Close', blockCalibrationNoiseTexture);

%% ------------------------------------------------
% 27.7 — Display calibration results
% ------------------------------------------------

fprintf('\n');
fprintf('============================================================\n');
fprintf('ALL BLOCK CALIBRATIONS COMPLETED\n');
fprintf('============================================================\n');

disp(blockCalibration);

fprintf('Section 27 completed.\n');


%% ================================================================
% SECTION 28 — BLOCK-SPECIFIC FUSION FRAME GEOMETRY
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('SECTION 28 — BLOCK-SPECIFIC FUSION FRAME GEOMETRY\n');
fprintf('============================================================\n');

%% ------------------------------------------------
% Check calibration data
% ------------------------------------------------

if ~isfield(blockCalibration, 'FrameSeparation_px')
    error('blockCalibration.FrameSeparation_px does not exist.');
end

if length(blockCalibration.FrameSeparation_px) ~= nBlocks
    error(['Number of stored calibration values does not match ', ...
           'number of blocks.']);
end

if any(isnan(blockCalibration.FrameSeparation_px))
    error('One or more blocks have missing frame-separation calibration.');
end

%% ------------------------------------------------
% Display stored calibration values
% ------------------------------------------------

fprintf('\nStored block-specific separations:\n');
fprintf('----------------------------------\n');

for b = 1:nBlocks

    fprintf('Block %02d: %4d px  |  %8.3f deg\n', ...
        b, ...
        blockCalibration.FrameSeparation_px(b), ...
        blockCalibration.FrameSeparation_deg(b));

end

%% ------------------------------------------------
% Create block-specific geometry
% ------------------------------------------------

blockGeometry = struct();

blockGeometry.Block = (1:nBlocks)';

blockGeometry.FrameSeparation_px = ...
    blockCalibration.FrameSeparation_px;

blockGeometry.FrameSeparation_deg = ...
    blockCalibration.FrameSeparation_deg;

blockGeometry.LeftFrameCenterX = nan(nBlocks,1);
blockGeometry.RightFrameCenterX = nan(nBlocks,1);

blockGeometry.LeftFusionRect = ...
    cell(nBlocks,1);

blockGeometry.RightFusionRect = ...
    cell(nBlocks,1);

blockGeometry.LeftOuterRect = ...
    cell(nBlocks,1);

blockGeometry.RightOuterRect = ...
    cell(nBlocks,1);

%% ------------------------------------------------
% Calculate geometry for every block
% ------------------------------------------------

for b = 1:nBlocks

    frameSeparation_px = ...
        blockGeometry.FrameSeparation_px(b);

    % ------------------------------------------------
    % Frame centres
    % ------------------------------------------------

    leftFrameCenterX = ...
        xCenter - frameSeparation_px/2;

    rightFrameCenterX = ...
        xCenter + frameSeparation_px/2;

    blockGeometry.LeftFrameCenterX(b) = ...
        leftFrameCenterX;

    blockGeometry.RightFrameCenterX(b) = ...
        rightFrameCenterX;

    % ------------------------------------------------
    % Fusion-frame rectangles
    % ------------------------------------------------

    blockGeometry.LeftFusionRect{b} = ...
        CenterRectOnPointd( ...
        [0 0 fusionWidth_px fusionHeight_px], ...
        leftFrameCenterX, ...
        yCenter);

    blockGeometry.RightFusionRect{b} = ...
        CenterRectOnPointd( ...
        [0 0 fusionWidth_px fusionHeight_px], ...
        rightFrameCenterX, ...
        yCenter);

    % ------------------------------------------------
    % Outer contour rectangles
    % ------------------------------------------------

    blockGeometry.LeftOuterRect{b} = ...
        CenterRectOnPointd( ...
        [0 0 outerWidth_px outerHeight_px], ...
        leftFrameCenterX, ...
        yCenter);

    blockGeometry.RightOuterRect{b} = ...
        CenterRectOnPointd( ...
        [0 0 outerWidth_px outerHeight_px], ...
        rightFrameCenterX, ...
        yCenter);

end

%% ------------------------------------------------
% Verification
% ------------------------------------------------

fprintf('\nBlock-specific geometry created successfully.\n');

fprintf('\nExample geometry:\n');
fprintf('-----------------\n');

fprintf('Block 1 separation: %d px\n', ...
    blockGeometry.FrameSeparation_px(1));

fprintf('Block 1 left frame centre: %.1f px\n', ...
    blockGeometry.LeftFrameCenterX(1));

fprintf('Block 1 right frame centre: %.1f px\n', ...
    blockGeometry.RightFrameCenterX(1));

fprintf('Block 1 fusion frame: %.0f × %.0f px\n', ...
    fusionWidth_px, fusionHeight_px);

fprintf('\nSection 28 completed.\n');


%% ================================================================
% SECTION 29 — EYE-SPECIFIC STIMULUS ASSIGNMENT
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('SECTION 29 — EYE-SPECIFIC STIMULUS ASSIGNMENT\n');
fprintf('============================================================\n');

%% ------------------------------------------------
% 29.1 — Participant dominant-eye assignment
% ------------------------------------------------

% IMPORTANT:
% Enter the participant's experimentally determined dominant eye.
%
% Valid options:
%   'left'
%   'right'

dominantEye = 'right';

%% ------------------------------------------------
% Check dominant-eye entry
% ------------------------------------------------

if ~ismember(lower(dominantEye), {'left','right'})
    error('dominantEye must be either ''left'' or ''right''.');
end

dominantEye = lower(dominantEye);

%% ------------------------------------------------
% 29.2 — Map dominant eye to physical frame
% ------------------------------------------------

% IMPORTANT:
% Do NOT assume that the physical left side of the monitor
% corresponds to the participant's left eye.
%
% The mapping below must reflect the actual mirror-stereoscope
% optical arrangement.

% ------------------------------------------------
% CURRENT MIRROR-STEREOSCOPE CONFIGURATION
% ------------------------------------------------
%
% Set these according to your actual stereoscope optical path.
%
% If the physical LEFT frame is seen by the participant's
% LEFT eye:
%
%     leftEyePhysicalFrame = 'left';
%     rightEyePhysicalFrame = 'right';
%
% If the optical arrangement is reversed:
%
%     leftEyePhysicalFrame = 'right';
%     rightEyePhysicalFrame = 'left';

leftEyePhysicalFrame  = 'left';
rightEyePhysicalFrame = 'right';

%% ------------------------------------------------
% Validate optical mapping
% ------------------------------------------------

if ~ismember(leftEyePhysicalFrame, {'left','right'})
    error('leftEyePhysicalFrame must be ''left'' or ''right''.');
end

if ~ismember(rightEyePhysicalFrame, {'left','right'})
    error('rightEyePhysicalFrame must be ''left'' or ''right''.');
end

if strcmp(leftEyePhysicalFrame, rightEyePhysicalFrame)
    error(['Invalid stereoscope mapping: both eyes are assigned ', ...
           'to the same physical frame.']);
end

%% ------------------------------------------------
% 29.3 — Determine physical stimulus sides
% ------------------------------------------------

if strcmp(dominantEye, 'left')

    facePhysicalSide = leftEyePhysicalFrame;
    cfsPhysicalSide  = rightEyePhysicalFrame;

else

    facePhysicalSide = rightEyePhysicalFrame;
    cfsPhysicalSide  = leftEyePhysicalFrame;

end

%% ------------------------------------------------
% 29.4 — Store assignment
% ------------------------------------------------

eyeAssignment = struct();

eyeAssignment.DominantEye = dominantEye;

eyeAssignment.LeftEyePhysicalFrame = ...
    leftEyePhysicalFrame;

eyeAssignment.RightEyePhysicalFrame = ...
    rightEyePhysicalFrame;

eyeAssignment.FacePhysicalSide = ...
    facePhysicalSide;

eyeAssignment.CFSPhysicalSide = ...
    cfsPhysicalSide;

%% ------------------------------------------------
% 29.5 — Display assignment
% ------------------------------------------------

fprintf('\n');
fprintf('Eye/stereoscope assignment:\n');
fprintf('---------------------------\n');

fprintf('Dominant eye:              %s\n', ...
    dominantEye);

fprintf('Left eye physical frame:   %s\n', ...
    leftEyePhysicalFrame);

fprintf('Right eye physical frame:  %s\n', ...
    rightEyePhysicalFrame);

fprintf('Face physical frame:       %s\n', ...
    facePhysicalSide);

fprintf('CFS physical frame:        %s\n', ...
    cfsPhysicalSide);

%% ------------------------------------------------
% 29.6 — Final consistency check
% ------------------------------------------------

if strcmp(facePhysicalSide, cfsPhysicalSide)
    error('Face and CFS have been assigned to the same physical frame.');
end

fprintf('\nEye-specific stimulus assignment verified.\n');
fprintf('Section 29 completed.\n');


%% ================================================================
% SECTION 30 — BLOCK-SPECIFIC FACE AND CFS GEOMETRY
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('SECTION 30 — BLOCK-SPECIFIC FACE AND CFS GEOMETRY\n');
fprintf('============================================================\n');

%% ------------------------------------------------
% 30.1 — Check required variables
% ------------------------------------------------

if ~exist('blockGeometry', 'var')
    error('blockGeometry does not exist. Run Section 28 first.');
end

if ~exist('eyeAssignment', 'var')
    error('eyeAssignment does not exist. Run Section 29 first.');
end

%% ------------------------------------------------
% 30.2 — Create storage
% ------------------------------------------------

blockStimulusGeometry = struct();

blockStimulusGeometry.Block = (1:nBlocks)';

blockStimulusGeometry.FacePhysicalSide = ...
    repmat({eyeAssignment.FacePhysicalSide}, nBlocks, 1);

blockStimulusGeometry.CFSPhysicalSide = ...
    repmat({eyeAssignment.CFSPhysicalSide}, nBlocks, 1);

blockStimulusGeometry.FaceCenterX = nan(nBlocks,1);
blockStimulusGeometry.FaceCenterY = nan(nBlocks,1);

blockStimulusGeometry.FaceRect = cell(nBlocks,1);

blockStimulusGeometry.CFSRect = cell(nBlocks,1);

%% ------------------------------------------------
% 30.3 — Calculate block-specific stimulus geometry
% ------------------------------------------------

for b = 1:nBlocks

    % ------------------------------------------------
    % Physical frame centres
    % ------------------------------------------------

    leftFrameCenterX = ...
        blockGeometry.LeftFrameCenterX(b);

    rightFrameCenterX = ...
        blockGeometry.RightFrameCenterX(b);

    % ------------------------------------------------
    % Determine which physical frame contains face
    % ------------------------------------------------

    if strcmp(eyeAssignment.FacePhysicalSide, 'left')

        faceFrameCenterX = leftFrameCenterX;

    elseif strcmp(eyeAssignment.FacePhysicalSide, 'right')

        faceFrameCenterX = rightFrameCenterX;

    else

        error('Invalid face physical side.');

    end

    % ------------------------------------------------
    % Face centre
    % ------------------------------------------------

    % Face is positioned 1.95 degrees horizontally
    % toward the centre of the overall display.
    %
    % Therefore:
    %
    % LEFT physical frame:
    %       face is shifted RIGHT
    %
    % RIGHT physical frame:
    %       face is shifted LEFT

    if strcmp(eyeAssignment.FacePhysicalSide, 'left')

        faceCenterX = ...
            faceFrameCenterX + faceCenterOffset_px;

    else

        faceCenterX = ...
            faceFrameCenterX - faceCenterOffset_px;

    end

    faceCenterY = yCenter;

    % ------------------------------------------------
    % Store face centre
    % ------------------------------------------------

    blockStimulusGeometry.FaceCenterX(b) = ...
        faceCenterX;

    blockStimulusGeometry.FaceCenterY(b) = ...
        faceCenterY;

    % ------------------------------------------------
    % Face rectangle
    % ------------------------------------------------

    blockStimulusGeometry.FaceRect{b} = ...
        CenterRectOnPointd( ...
        [0 0 faceWidth_px faceHeight_px], ...
        faceCenterX, ...
        faceCenterY);

    % ------------------------------------------------
    % CFS rectangle
    % ------------------------------------------------

    if strcmp(eyeAssignment.CFSPhysicalSide, 'left')

        blockStimulusGeometry.CFSRect{b} = ...
            blockGeometry.LeftFusionRect{b};

    else

        blockStimulusGeometry.CFSRect{b} = ...
            blockGeometry.RightFusionRect{b};

    end

end

%% ------------------------------------------------
% 30.4 — Display example geometry
% ------------------------------------------------

fprintf('\n');
fprintf('Block 1 stimulus geometry:\n');
fprintf('--------------------------\n');

fprintf('Face physical side: %s\n', ...
    blockStimulusGeometry.FacePhysicalSide{1});

fprintf('CFS physical side:  %s\n', ...
    blockStimulusGeometry.CFSPhysicalSide{1});

fprintf('Face centre: %.1f, %.1f px\n', ...
    blockStimulusGeometry.FaceCenterX(1), ...
    blockStimulusGeometry.FaceCenterY(1));

fprintf('Face size: %.0f × %.0f px\n', ...
    faceWidth_px, faceHeight_px);

fprintf('\nFace visual angle: %.1f × %.1f deg\n', ...
    faceVisualAngleWidth_deg, ...
    faceVisualAngleHeight_deg);

fprintf('Face horizontal offset: %.2f deg\n', ...
    faceCenterOffset_deg);

fprintf('\nBlock-specific face/CFS geometry created.\n');
fprintf('Section 30 completed.\n');


%% ================================================================
% SECTION 31 — LOAD AND VERIFY CFS MONDRIAN STIMULI
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('SECTION 31 — LOAD AND VERIFY CFS MONDRIAN STIMULI\n');
fprintf('============================================================\n');

%% ------------------------------------------------
% 31.1 — CFS stimulus folder
% ------------------------------------------------

cfsFolder = ...
    'D:\CFS\Expt_emo\Stimuli\CFS_Mondrian_Colored';

nCFSMasks = 200;

%% ------------------------------------------------
% 31.2 — Check folder
% ------------------------------------------------

if ~exist(cfsFolder, 'dir')

    error(['CFS stimulus folder not found: ', ...
           cfsFolder]);

end

fprintf('CFS folder found:\n%s\n', cfsFolder);

%% ------------------------------------------------
% 31.3 — Create texture storage
% ------------------------------------------------

cfsTextures = nan(nCFSMasks, 1);

cfsWidth_px  = nan(nCFSMasks, 1);
cfsHeight_px = nan(nCFSMasks, 1);

%% ------------------------------------------------
% 31.4 — Load all CFS masks
% ------------------------------------------------

for m = 1:nCFSMasks

    cfsFile = fullfile( ...
        cfsFolder, ...
        sprintf('Mondrian_%03d.png', m));

    % ------------------------------------------------
    % Check file exists
    % ------------------------------------------------

    if ~exist(cfsFile, 'file')

        error(['Missing CFS mask: ', cfsFile]);

    end

    % ------------------------------------------------
    % Read image
    % ------------------------------------------------

    cfsImage = imread(cfsFile);

    % ------------------------------------------------
    % Convert grayscale images to RGB
    % ------------------------------------------------

    if ndims(cfsImage) == 2

        cfsImage = repmat(cfsImage, [1 1 3]);

    end

    % ------------------------------------------------
    % Verify RGB
    % ------------------------------------------------

    if size(cfsImage, 3) ~= 3

        error(['CFS mask is not RGB: ', cfsFile]);

    end

    % ------------------------------------------------
    % Store dimensions
    % ------------------------------------------------

    cfsHeight_px(m) = size(cfsImage, 1);
    cfsWidth_px(m)  = size(cfsImage, 2);

    % ------------------------------------------------
    % Create PTB texture
    % ------------------------------------------------

    cfsTextures(m) = ...
        Screen('MakeTexture', win, cfsImage);

end

%% ------------------------------------------------
% 31.5 — Verify dimensions
% ------------------------------------------------

uniqueWidths = unique(cfsWidth_px);
uniqueHeights = unique(cfsHeight_px);

fprintf('\nCFS texture verification:\n');
fprintf('-------------------------\n');

fprintf('Number of masks: %d\n', nCFSMasks);

fprintf('Unique widths: ');
disp(uniqueWidths');

fprintf('Unique heights: ');
disp(uniqueHeights');

if numel(uniqueWidths) ~= 1 || numel(uniqueHeights) ~= 1

    error(['CFS masks do not all have identical dimensions. ', ...
           'Check the source PNG files.']);

end

%% ------------------------------------------------
% 31.6 — Store source dimensions
% ------------------------------------------------

cfsSourceWidth_px  = uniqueWidths(1);
cfsSourceHeight_px = uniqueHeights(1);

%% ------------------------------------------------
% 31.7 — Display summary
% ------------------------------------------------

fprintf('\nAll CFS masks loaded successfully.\n');

fprintf('Source mask dimensions: %d × %d px\n', ...
    cfsSourceWidth_px, ...
    cfsSourceHeight_px);

fprintf('Final presentation rectangle will be:\n');
fprintf('    %d × %d px\n', ...
    fusionWidth_px, ...
    fusionHeight_px);

fprintf('\nCFS textures created: %d\n', ...
    nCFSMasks);

fprintf('Section 31 completed.\n');



%% ================================================================
% SECTION 32 — LOAD AND VERIFY KDEF FACE STIMULI
% ================================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('SECTION 32 — LOAD AND VERIFY KDEF FACE STIMULI\n');
fprintf('============================================================\n');

%% ------------------------------------------------
% 32.1 — Face stimulus folders
% ------------------------------------------------

neutralDir = ...
    'D:\CFS\Expt_emo\Stimuli\crop_contour_blur\neutral';

angryDir = ...
    'D:\CFS\Expt_emo\Stimuli\crop_contour_blur\angry';

happyDir = ...
    'D:\CFS\Expt_emo\Stimuli\crop_contour_blur\happy';

emotionNames = {'angry', 'happy', 'neutral'};

emotionDirs = { ...
    angryDir, ...
    happyDir, ...
    neutralDir};

%% ------------------------------------------------
% 32.2 — Verify folders
% ------------------------------------------------

for e = 1:numel(emotionNames)

    if ~isfolder(emotionDirs{e})

        error(['Folder not found for %s faces:\n%s'], ...
            emotionNames{e}, ...
            emotionDirs{e});

    end

    fprintf('%s folder found:\n%s\n\n', ...
        upper(emotionNames{e}), ...
        emotionDirs{e});

end

%% ------------------------------------------------
% 32.3 — Find PNG files
% ------------------------------------------------

faceFiles = struct();

for e = 1:numel(emotionNames)

    emotion = emotionNames{e};
    emotionDir = emotionDirs{e};

    pngFiles = dir(fullfile(emotionDir, '*.png'));

    allFiles = pngFiles;

    if isempty(allFiles)

        error(['No PNG files found in:\n%s'], ...
            emotionDir);

    end

    % Sort alphabetically by filename
    [~, sortIndex] = sort({allFiles.name});

    allFiles = allFiles(sortIndex);

    faceFiles.(emotion) = allFiles;

    fprintf('%s PNG files found: %d\n', ...
        upper(emotion), ...
        numel(allFiles));

end

fprintf('\n');

%% ------------------------------------------------
% 32.4 — Create storage
% ------------------------------------------------

faceImages = struct();
faceTextures = struct();

%% ------------------------------------------------
% 32.5 — Read and verify all faces
% ------------------------------------------------

for e = 1:numel(emotionNames)

    emotion = emotionNames{e};

    files = faceFiles.(emotion);

    nFaces = numel(files);

    fprintf('Verifying %s faces...\n', ...
        upper(emotion));

    % Storage
    faceImages.(emotion) = cell(nFaces,1);

    faceTextures.(emotion) = nan(nFaces,1);

    imageWidths = nan(nFaces,1);
    imageHeights = nan(nFaces,1);
    imageChannels = nan(nFaces,1);

    for f = 1:nFaces

        imagePath = fullfile( ...
            files(f).folder, ...
            files(f).name);

        %% ------------------------------------------------
        % Read PNG
        % ------------------------------------------------

        faceImage = imread(imagePath);

        %% ------------------------------------------------
        % Convert grayscale PNG to RGB
        % ------------------------------------------------

        if ndims(faceImage) == 2

            faceImage = repmat(faceImage, [1 1 3]);

        elseif ndims(faceImage) == 3 && ...
               size(faceImage,3) == 3

            % Already RGB

        else

            error(['Unexpected image format:\n%s\n' ...
                   'Dimensions: %s'], ...
                imagePath, ...
                mat2str(size(faceImage)));

        end

        %% ------------------------------------------------
        % Record dimensions
        % ------------------------------------------------

        imageHeights(f) = size(faceImage,1);
        imageWidths(f)  = size(faceImage,2);
        imageChannels(f) = size(faceImage,3);

        %% ------------------------------------------------
        % Store image
        % ------------------------------------------------

        faceImages.(emotion){f} = faceImage;

        %% ------------------------------------------------
        % Create PTB texture
        % ------------------------------------------------

        faceTextures.(emotion)(f) = ...
            Screen('MakeTexture', ...
                   win, ...
                   faceImage);

    end

    %% ------------------------------------------------
    % Check dimensional consistency
    % ------------------------------------------------

    uniqueWidths = unique(imageWidths);
    uniqueHeights = unique(imageHeights);
    uniqueChannels = unique(imageChannels);

    fprintf('  Unique widths:    %d\n', ...
        numel(uniqueWidths));

    fprintf('  Unique heights:   %d\n', ...
        numel(uniqueHeights));

    fprintf('  Unique channels:  %d\n', ...
        numel(uniqueChannels));

    if numel(uniqueWidths) ~= 1 || ...
       numel(uniqueHeights) ~= 1 || ...
       numel(uniqueChannels) ~= 1

        error(['Face dimensions are not consistent within ' ...
               'the %s folder.'], ...
            emotion);

    end

    fprintf('  Dimensions: %d × %d × %d\n', ...
        uniqueWidths, ...
        uniqueHeights, ...
        uniqueChannels);

    fprintf('  All %d %s faces verified.\n\n', ...
        nFaces, ...
        emotion);

end

%% ------------------------------------------------
% 32.6 — Overall verification
% ------------------------------------------------

totalFaceTextures = 0;

for e = 1:numel(emotionNames)

    emotion = emotionNames{e};

    totalFaceTextures = ...
        totalFaceTextures + ...
        numel(faceTextures.(emotion));

end

fprintf('============================================================\n');
fprintf('KDEF FACE VERIFICATION SUMMARY\n');
fprintf('============================================================\n');

for e = 1:numel(emotionNames)

    emotion = emotionNames{e};

    fprintf('%-10s : %d textures\n', ...
        upper(emotion), ...
        numel(faceTextures.(emotion)));

end

fprintf('------------------------------------------------------------\n');

fprintf('Total face textures created: %d\n', ...
    totalFaceTextures);

fprintf('Face presentation size: %d × %d px\n', ...
    faceWidth_px, ...
    faceHeight_px);

fprintf('Face visual angle: %.2f × %.2f degrees\n', ...
    faceVisualAngleWidth_deg, ...
    faceVisualAngleHeight_deg);

fprintf('============================================================\n');
fprintf('Section 32 completed.\n');
fprintf('============================================================\n');



%% ================================================================
% SECTION 33 — ARROW SEQUENCE LIBRARY
%
% Purpose:
%   Load and validate the predefined arrow-sequence library.
%
% One trial = ONE COMPLETE SEQUENCE of arrows.
%
% Easy / Low load:
%   Targets = red upright OR red downright
%   Target counts = 2, 3, 4, 5
%
% Hard / High load:
%   Targets = yellow upright OR green downright
%   Target counts = 1, 2, 3, 4
%
% The CSV contains the target/non-target POSITION structure:
%   1 = target
%   o = non-target
%
% Trial generation/randomization will be done later.
%
% ================================================================

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 33 — ARROW SEQUENCE LIBRARY\n');
fprintf('===============================================================\n');


%% ---------------------------------------------------------------
% 33.1 CSV FILE
% ---------------------------------------------------------------

sequenceCSV = 'D:\CFS\Expt_emo\Stimuli\rsvp_sequences.csv';

if ~isfile(sequenceCSV)

    error(['Sequence CSV not found:\n\n' ...
           '%s\n\n' ...
           'Please check the file path.'], sequenceCSV);

end

fprintf('Sequence CSV found:\n');
fprintf('%s\n', sequenceCSV);


%% 33.2 READ CSV

sequenceTable = readtable(sequenceCSV, ...
    'TextType','string');

fprintf('\nCSV loaded successfully.\n');
fprintf('Raw number of rows: %d\n', height(sequenceTable));

%% 33.2a REMOVE EMPTY ROWS
%
% The CSV contains 63 actual sequence entries.
% Additional blank rows at the bottom are removed here.

isEmptyRow = true(height(sequenceTable),1);

for r = 1:height(sequenceTable)

    % Check Sequence column first.
    % This is sufficient because every valid sequence must have
    % a Sequence entry.

    sequenceValue = sequenceTable.Sequence(r);

    if ~ismissing(sequenceValue) && ...
            strlength(strtrim(sequenceValue)) > 0

        isEmptyRow(r) = false;
    end
end

nEmptyRows = sum(isEmptyRow);

if nEmptyRows > 0
    sequenceTable(isEmptyRow,:) = [];
end

fprintf('Empty rows removed: %d\n', nEmptyRows);
fprintf('Actual sequence entries remaining: %d\n', ...
    height(sequenceTable));

%% ---------------------------------------------------------------
% 33.3 VERIFY REQUIRED COLUMNS
% ---------------------------------------------------------------

requiredColumns = [ ...
    "RSVPLoad", ...
    "Sequence", ...
    "CrossCount", ...
    "Duration" ...
    ];

actualColumns = string(sequenceTable.Properties.VariableNames);

for c = 1:numel(requiredColumns)

    if ~any(strcmpi(actualColumns, requiredColumns(c)))

        error(['Required column "%s" was not found in the CSV.\n' ...
               'Available columns are:\n%s'], ...
               requiredColumns(c), ...
               strjoin(actualColumns, ', '));

    end

end

fprintf('\nRequired columns verified:\n');

for c = 1:numel(requiredColumns)

    fprintf('  %s\n', requiredColumns(c));

end


%% ---------------------------------------------------------------
% 33.4 STANDARDIZE COLUMN ACCESS
% ---------------------------------------------------------------
%
% Find the actual MATLAB column names in a case-insensitive way.
%
% ---------------------------------------------------------------

columnNames = sequenceTable.Properties.VariableNames;

loadColumnName = columnNames{ ...
    find(strcmpi(columnNames,'RSVPLoad'),1)};

sequenceColumnName = columnNames{ ...
    find(strcmpi(columnNames,'Sequence'),1)};

crossColumnName = columnNames{ ...
    find(strcmpi(columnNames,'CrossCount'),1)};

durationColumnName = columnNames{ ...
    find(strcmpi(columnNames,'Duration'),1)};


%% ---------------------------------------------------------------
% 33.5 EXTRACT COLUMNS
% ---------------------------------------------------------------

sequenceLoad = string(sequenceTable.(loadColumnName));
sequenceCode = string(sequenceTable.(sequenceColumnName));
crossCount   = double(sequenceTable.(crossColumnName));
duration_ms  = double(sequenceTable.(durationColumnName));


%% ---------------------------------------------------------------
% 33.6 STANDARDIZE LOAD LABELS
% ---------------------------------------------------------------

sequenceLoad = lower(strtrim(sequenceLoad));

validLoadLabels = ...
    sequenceLoad == "easy" | sequenceLoad == "hard";

if any(~validLoadLabels)

    badRows = find(~validLoadLabels);

    error(['Invalid RSVPLoad value(s) found in row(s): %s\n' ...
           'Allowed values are: Easy, Hard'], ...
           mat2str(badRows'));

end

fprintf('\nLoad labels verified.\n');
fprintf('  Easy rows: %d\n', sum(sequenceLoad == "easy"));
fprintf('  Hard rows: %d\n', sum(sequenceLoad == "hard"));


%% ---------------------------------------------------------------
% 33.7 VERIFY SEQUENCE STRINGS
% ---------------------------------------------------------------
%
% Every sequence must contain ONLY:
%
%   1 = target position
%   o = non-target position
%
% ---------------------------------------------------------------

validSequenceCharacters = true(height(sequenceTable),1);

for t = 1:height(sequenceTable)

    thisSequence = char(sequenceCode(t));

    if isempty(thisSequence)

        validSequenceCharacters(t) = false;

    elseif any(~ismember(thisSequence, ['1' 'o']))

        validSequenceCharacters(t) = false;

    end

end

if any(~validSequenceCharacters)

    badRows = find(~validSequenceCharacters);

    error(['Invalid sequence characters found in row(s): %s\n' ...
           'Sequences may contain only "1" and "o".'], ...
           mat2str(badRows'));

end

fprintf('\nSequence characters verified.\n');


%% ---------------------------------------------------------------
% 33.8 CALCULATE ACTUAL TARGET COUNTS
% ---------------------------------------------------------------

actualTargetCount = zeros(height(sequenceTable),1);
actualCrossCount  = zeros(height(sequenceTable),1);

for t = 1:height(sequenceTable)

    thisSequence = char(sequenceCode(t));

    actualTargetCount(t) = sum(thisSequence == '1');

    actualCrossCount(t) = length(thisSequence);

end


%% ---------------------------------------------------------------
% 33.9 VERIFY CROSS COUNT
% ---------------------------------------------------------------

crossCountMatches = ...
    actualCrossCount == crossCount;

if any(~crossCountMatches)

    badRows = find(~crossCountMatches);

    fprintf('\nWARNING — CrossCount mismatch detected.\n');

    for i = 1:numel(badRows)

        r = badRows(i);

        fprintf(['  Row %d: sequence "%s" has %d arrows, ' ...
                 'CSV says %g\n'], ...
                 r, ...
                 sequenceCode(r), ...
                 actualCrossCount(r), ...
                 crossCount(r));

    end

    error('CrossCount validation failed.');

end

fprintf('\nCrossCount verified for all sequences.\n');


%% ---------------------------------------------------------------
% 33.10 VERIFY TARGET COUNT
% ---------------------------------------------------------------
%
% The CSV does not need a separate target-count column because
% the target count is directly determined by the number of "1"s.
%
% ---------------------------------------------------------------

fprintf('\nTarget-count distribution in sequence library:\n');

for nTargets = 1:5

    nEasy = sum(sequenceLoad == "easy" & ...
                actualTargetCount == nTargets);

    nHard = sum(sequenceLoad == "hard" & ...
                actualTargetCount == nTargets);

    fprintf('  %d target(s): Easy = %d, Hard = %d\n', ...
        nTargets, nEasy, nHard);

end


%% ---------------------------------------------------------------
% 33.11 VERIFY LOAD-SPECIFIC TARGET COUNTS
% ---------------------------------------------------------------

easyValidTargetCounts = ismember( ...
    actualTargetCount(sequenceLoad == "easy"), ...
    [2 3 4 5]);

hardValidTargetCounts = ismember( ...
    actualTargetCount(sequenceLoad == "hard"), ...
    [1 2 3 4]);

if any(~easyValidTargetCounts)

    error(['Easy condition contains a sequence with an invalid ' ...
           'target count. Easy must contain only 2–5 targets.']);

end

if any(~hardValidTargetCounts)

    error(['Hard condition contains a sequence with an invalid ' ...
           'target count. Hard must contain only 1–4 targets.']);

end

fprintf('\nLoad-specific target-count ranges verified.\n');


%% ---------------------------------------------------------------
% 33.12 VERIFY TARGET SEPARATION
% ---------------------------------------------------------------
%
% Every target must be separated from the next target by at least
% one non-target.
%
% Therefore "11" is forbidden.
%
% ---------------------------------------------------------------

targetSeparationValid = true(height(sequenceTable),1);

for t = 1:height(sequenceTable)

    thisSequence = char(sequenceCode(t));

    if contains(thisSequence,'11')

        targetSeparationValid(t) = false;

    end

end

if any(~targetSeparationValid)

    badRows = find(~targetSeparationValid);

    error(['Target-separation rule violated in row(s): %s\n' ...
           'No sequence may contain consecutive targets ("11").'], ...
           mat2str(badRows'));

end

fprintf('\nTarget-separation constraint verified.\n');


%% ---------------------------------------------------------------
% 33.13 CHECK FOR DUPLICATE SEQUENCES
% ---------------------------------------------------------------

[uniqueSequences,~,sequenceGroup] = unique( ...
    sequenceCode,'stable');

sequenceDuplicateCounts = accumarray( ...
    sequenceGroup,1);

duplicateSequenceIndices = ...
    find(sequenceDuplicateCounts > 1);

if ~isempty(duplicateSequenceIndices)

    fprintf('\nWARNING — Duplicate sequence codes found:\n');

    for i = 1:numel(duplicateSequenceIndices)

        idx = duplicateSequenceIndices(i);

        fprintf('  %s (%d occurrences)\n', ...
            uniqueSequences(idx), ...
            sequenceDuplicateCounts(idx));

    end

else

    fprintf('\nNo duplicate sequence codes found.\n');

end


%% ---------------------------------------------------------------
% 33.14 CREATE SEPARATE SEQUENCE LIBRARIES
% ---------------------------------------------------------------

easySequenceLibrary = sequenceTable( ...
    sequenceLoad == "easy", :);

hardSequenceLibrary = sequenceTable( ...
    sequenceLoad == "hard", :);


%% ---------------------------------------------------------------
% 33.15 ADD CALCULATED VARIABLES
% ---------------------------------------------------------------

easySequenceLibrary.TargetCount = ...
    actualTargetCount(sequenceLoad == "easy");

easySequenceLibrary.ActualCrossCount = ...
    actualCrossCount(sequenceLoad == "easy");

hardSequenceLibrary.TargetCount = ...
    actualTargetCount(sequenceLoad == "hard");

hardSequenceLibrary.ActualCrossCount = ...
    actualCrossCount(sequenceLoad == "hard");


%% ---------------------------------------------------------------
% 33.16 SUMMARY
% ---------------------------------------------------------------

fprintf('\n');
fprintf('---------------------------------------------------------------\n');
fprintf('SEQUENCE LIBRARY SUMMARY\n');
fprintf('---------------------------------------------------------------\n');

fprintf('Total sequence templates: %d\n', ...
    height(sequenceTable));

fprintf('Easy sequence templates:  %d\n', ...
    height(easySequenceLibrary));

fprintf('Hard sequence templates:  %d\n', ...
    height(hardSequenceLibrary));

fprintf('\nEasy target-count library:\n');

for nTargets = 2:5

    n = sum(easySequenceLibrary.TargetCount == nTargets);

    fprintf('  %d target(s): %d sequences\n', ...
        nTargets,n);

end

fprintf('\nHard target-count library:\n');

for nTargets = 1:4

    n = sum(hardSequenceLibrary.TargetCount == nTargets);

    fprintf('  %d target(s): %d sequences\n', ...
        nTargets,n);

end


%% ---------------------------------------------------------------
% 33.17 STORE MASTER LIBRARY
% ---------------------------------------------------------------

arrowSequenceLibrary = struct();

arrowSequenceLibrary.All = sequenceTable;

arrowSequenceLibrary.Easy = easySequenceLibrary;

arrowSequenceLibrary.Hard = hardSequenceLibrary;

arrowSequenceLibrary.AllSequenceCodes = ...
    sequenceCode;

arrowSequenceLibrary.AllTargetCounts = ...
    actualTargetCount;

arrowSequenceLibrary.AllCrossCounts = ...
    actualCrossCount;

arrowSequenceLibrary.AllDurations_ms = ...
    duration_ms;


%% ---------------------------------------------------------------
% 33.18 ARROW TASK DEFINITIONS
% ---------------------------------------------------------------

% HARD / HIGH LOAD
arrowTask.Hard.Targets = {
    'Yellow_Upright'
    'Green_Downright'
    };

arrowTask.Hard.NonTargets = {
    'Green_Upright'
    'Yellow_Downright'
    'Pink_Upright'
    'Pink_Downright'
    'Orange_Upright'
    'Orange_Downright'
    'Blue_Upright'
    'Blue_Downright'
    'Red_Upright'
    'Red_Downright'
    };

arrowTask.Hard.TargetCounts = 1:4;


% EASY / LOW LOAD
arrowTask.Easy.Targets = {
    'Red_Upright'
    'Red_Downright'
    };

arrowTask.Easy.NonTargets = {
    'Yellow_Upright'
    'Yellow_Downright'
    'Green_Upright'
    'Green_Downright'
    'Pink_Upright'
    'Pink_Downright'
    'Orange_Upright'
    'Orange_Downright'
    'Blue_Upright'
    'Blue_Downright'
    };

arrowTask.Easy.TargetCounts = 2:5;


%% ---------------------------------------------------------------
% 33.19 FINAL OUTPUT
% ---------------------------------------------------------------

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 33 COMPLETED\n');
fprintf('===============================================================\n');

fprintf('\nArrow task definitions:\n');

fprintf('  HARD/HIGH:\n');
fprintf('    Targets: Yellow-up, Green-down\n');
fprintf('    Target counts: 1–4\n');

fprintf('  EASY/LOW:\n');
fprintf('    Targets: Red-up, Red-down\n');
fprintf('    Target counts: 2–5\n');

fprintf('\nNo trial randomization has been performed yet.\n');
fprintf('No arrow textures have been created yet.\n');
fprintf('No CFS timing has been changed.\n');

fprintf('\nSection 33 completed successfully.\n');



%% ================================================================
% SECTION 34 — GENERATE BLOCK TRIAL SEQUENCES
%
% Purpose:
%   Generate the 36 actual RSVP trials for each load condition.
%
% EASY / LOW:
%   36 trials total
%   9 trials each with 2, 3, 4, and 5 targets
%
% HARD / HIGH:
%   36 trials total
%   9 trials each with 1, 2, 3, and 4 targets
%
% Sequence selection:
%   - Uses only sequences from the CSV library.
%   - Every target-count category is exactly balanced.
%   - Available templates are used before reuse.
%   - Reuse is allowed where fewer than 9 templates exist.
%   - No exact sequence may repeat consecutively.
%
% This section does NOT:
%   - assign arrow colours/orientations
%   - create arrow textures
%   - present trials
%   - alter CFS timing
%
% ================================================================

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 34 — GENERATE BLOCK TRIAL SEQUENCES\n');
fprintf('===============================================================\n');

%% 34.1 BASIC PARAMETERS

trialsPerBlock = 36;
trialsPerTargetCount = 9;

easyTargetCounts = arrowTask.Easy.TargetCounts;
hardTargetCounts = arrowTask.Hard.TargetCounts;

fprintf('\nTrials per block: %d\n', trialsPerBlock);
fprintf('Trials per target-count category: %d\n', ...
    trialsPerTargetCount);

%% 34.2 CHECK TARGET-COUNT BALANCE

if numel(easyTargetCounts) * trialsPerTargetCount ~= trialsPerBlock
    error('Easy target-count distribution does not produce 36 trials.');
end

if numel(hardTargetCounts) * trialsPerTargetCount ~= trialsPerBlock
    error('Hard target-count distribution does not produce 36 trials.');
end

%% ================================================================
% 34.3 GENERATE EASY / LOW BLOCK
% ================================================================

fprintf('\nGenerating EASY / LOW block...\n');

easySelectedIndices = [];

for nTargets = easyTargetCounts

    % Find all available templates with this target count.
    availableIndices = find( ...
        easySequenceLibrary.TargetCount == nTargets);

    % Force column-vector format.
    availableIndices = availableIndices(:);

    nAvailable = numel(availableIndices);

    if nAvailable == 0
        error('No Easy sequence templates found for %d targets.', ...
            nTargets);
    end

    % ------------------------------------------------------------
    % Select exactly 9 trials.
    % ------------------------------------------------------------

    selectedForThisCount = zeros(0,1);

    while numel(selectedForThisCount) < trialsPerTargetCount

        % Randomize the available templates.
        shuffledIndices = ...
            availableIndices(randperm(nAvailable));

        % Force column-vector format.
        shuffledIndices = shuffledIndices(:);

        % Number of trials still needed.
        remainingTrials = ...
            trialsPerTargetCount - numel(selectedForThisCount);

        % Number to take during this pass.
        numberToTake = ...
            min(remainingTrials,nAvailable);

        % Add selected indices as a COLUMN.
        selectedForThisCount = ...
            [selectedForThisCount; ...
             shuffledIndices(1:numberToTake)];

    end

    % Randomize the 9 selected trials.
    selectedForThisCount = ...
        selectedForThisCount( ...
        randperm(numel(selectedForThisCount)));

    % Force column-vector format again.
    selectedForThisCount = selectedForThisCount(:);

    % Add to Easy block.
    easySelectedIndices = ...
        [easySelectedIndices; selectedForThisCount];

    fprintf(['  %d target(s): %d trials selected ' ...
             'from %d unique templates\n'], ...
        nTargets, ...
        numel(selectedForThisCount), ...
        nAvailable);
end

%% ================================================================
% 34.4 RANDOMIZE EASY BLOCK ORDER
% ================================================================

easySelectedIndices = ...
    easySelectedIndices( ...
    randperm(numel(easySelectedIndices)));

fprintf('\nEasy block randomized.\n');

%% ================================================================
% 34.5 CHECK EASY BLOCK FOR CONSECUTIVE EXACT REPEATS
% ================================================================
%
% If a consecutive repeat occurs, repeatedly shuffle the entire
% block until the restriction is satisfied.
%
% The target-count composition is preserved because we are only
% shuffling the already-selected trials.

easySequenceCodes = ...
    string(easySequenceLibrary.Sequence(easySelectedIndices));

easyValidOrder = false;

for shuffleAttempt = 1:10000

    consecutiveRepeat = ...
        easySequenceCodes(2:end) == ...
        easySequenceCodes(1:end-1);

    if ~any(consecutiveRepeat)

        easyValidOrder = true;
        break;
    end

    % Re-shuffle the entire selected sequence list.
    easySelectedIndices = ...
        easySelectedIndices( ...
        randperm(numel(easySelectedIndices)));

    easySequenceCodes = ...
        string(easySequenceLibrary.Sequence( ...
        easySelectedIndices));
end

if ~easyValidOrder

    error(['Could not create a valid Easy block without ' ...
           'consecutive exact sequence repeats after 10,000 ' ...
           'randomization attempts.']);
end

fprintf('No consecutive exact sequence repeats in Easy block.\n');

%% ================================================================
% 34.6 CREATE EASY BLOCK TABLE
% ================================================================

easyBlockSequences = ...
    easySequenceLibrary(easySelectedIndices,:);

easyBlockSequences.TrialNumber = ...
    (1:trialsPerBlock)';

%% ================================================================
% 34.7 VERIFY EASY TARGET-COUNT DISTRIBUTION
% ================================================================

fprintf('\nEASY / LOW block verification:\n');

for nTargets = easyTargetCounts

    nTrials = sum( ...
        easyBlockSequences.TargetCount == nTargets);

    fprintf('  %d target(s): %d trials\n', ...
        nTargets,nTrials);

    if nTrials ~= trialsPerTargetCount

        error(['Easy block imbalance: %d targets has %d trials ' ...
               'instead of %d.'], ...
            nTargets, ...
            nTrials, ...
            trialsPerTargetCount);
    end
end

%% ================================================================
% 34.8 GENERATE HARD / HIGH BLOCK
% ================================================================

fprintf('\nGenerating HARD / HIGH block...\n');

hardSelectedIndices = [];

for nTargets = hardTargetCounts

    % Find all available templates with this target count.
    availableIndices = find( ...
        hardSequenceLibrary.TargetCount == nTargets);

    nAvailable = numel(availableIndices);

    if nAvailable == 0
        error('No Hard sequence templates found for %d targets.', ...
            nTargets);
    end


    % ------------------------------------------------------------
    % Select exactly 9 trials.
    % ------------------------------------------------------------

    selectedForThisCount = zeros(0,1);

    while numel(selectedForThisCount) < trialsPerTargetCount

        % Randomize the available templates.
        shuffledIndices = ...
            availableIndices(randperm(nAvailable));

        % Force column-vector format.
        shuffledIndices = shuffledIndices(:);

        % Number of trials still needed.
        remainingTrials = ...
            trialsPerTargetCount - numel(selectedForThisCount);

        % Number to take during this pass.
        numberToTake = ...
            min(remainingTrials,nAvailable);

        % Add selected indices as a COLUMN.
        selectedForThisCount = ...
            [selectedForThisCount; ...
             shuffledIndices(1:numberToTake)];

    end

    % Randomize the 9 selected trials.
    selectedForThisCount = ...
        selectedForThisCount( ...
        randperm(numel(selectedForThisCount)));

    % Force column-vector format again.
    selectedForThisCount = selectedForThisCount(:);

    % Add to Hard block.
    hardSelectedIndices = ...
    [hardSelectedIndices; selectedForThisCount];

    fprintf(['  %d target(s): %d trials selected ' ...
             'from %d unique templates\n'], ...
        nTargets, ...
        numel(selectedForThisCount), ...
        nAvailable);
end
%% ================================================================
% 34.9 RANDOMIZE HARD BLOCK ORDER
% ================================================================

hardSelectedIndices = ...
    hardSelectedIndices( ...
    randperm(numel(hardSelectedIndices)));

fprintf('\nHard block randomized.\n');

%% ================================================================
% 34.10 CHECK HARD BLOCK FOR CONSECUTIVE EXACT REPEATS
% ================================================================

hardSequenceCodes = ...
    string(hardSequenceLibrary.Sequence(hardSelectedIndices));

hardValidOrder = false;

for shuffleAttempt = 1:10000

    consecutiveRepeat = ...
        hardSequenceCodes(2:end) == ...
        hardSequenceCodes(1:end-1);

    if ~any(consecutiveRepeat)

        hardValidOrder = true;
        break;
    end

    % Re-shuffle the entire selected sequence list.
    hardSelectedIndices = ...
        hardSelectedIndices( ...
        randperm(numel(hardSelectedIndices)));

    hardSequenceCodes = ...
        string(hardSequenceLibrary.Sequence( ...
        hardSelectedIndices));
end

if ~hardValidOrder

    error(['Could not create a valid Hard block without ' ...
           'consecutive exact sequence repeats after 10,000 ' ...
           'randomization attempts.']);
end

fprintf('No consecutive exact sequence repeats in Hard block.\n');

%% ================================================================
% 34.11 CREATE HARD BLOCK TABLE
% ================================================================

hardBlockSequences = ...
    hardSequenceLibrary(hardSelectedIndices,:);

hardBlockSequences.TrialNumber = ...
    (1:trialsPerBlock)';

%% ================================================================
% 34.12 VERIFY HARD TARGET-COUNT DISTRIBUTION
% ================================================================

fprintf('\nHARD / HIGH block verification:\n');

for nTargets = hardTargetCounts

    nTrials = sum( ...
        hardBlockSequences.TargetCount == nTargets);

    fprintf('  %d target(s): %d trials\n', ...
        nTargets,nTrials);

    if nTrials ~= trialsPerTargetCount

        error(['Hard block imbalance: %d targets has %d trials ' ...
               'instead of %d.'], ...
            nTargets, ...
            nTrials, ...
            trialsPerTargetCount);
    end
end

%% ================================================================
% 34.13 DISPLAY EASY TRIAL ORDER
% ================================================================

fprintf('\n');
fprintf('---------------------------------------------------------------\n');
fprintf('EASY / LOW — GENERATED TRIAL ORDER\n');
fprintf('---------------------------------------------------------------\n');

for t = 1:trialsPerBlock

    fprintf(['Trial %2d: %-12s | %d target(s) | ' ...
             '%d arrows | %.2f ms\n'], ...
        easyBlockSequences.TrialNumber(t), ...
        easyBlockSequences.Sequence(t), ...
        easyBlockSequences.TargetCount(t), ...
        easyBlockSequences.ActualCrossCount(t), ...
        easyBlockSequences.Duration(t));
end

%% ================================================================
% 34.14 DISPLAY HARD TRIAL ORDER
% ================================================================

fprintf('\n');
fprintf('---------------------------------------------------------------\n');
fprintf('HARD / HIGH — GENERATED TRIAL ORDER\n');
fprintf('---------------------------------------------------------------\n');

for t = 1:trialsPerBlock

    fprintf(['Trial %2d: %-12s | %d target(s) | ' ...
             '%d arrows | %.2f ms\n'], ...
        hardBlockSequences.TrialNumber(t), ...
        hardBlockSequences.Sequence(t), ...
        hardBlockSequences.TargetCount(t), ...
        hardBlockSequences.ActualCrossCount(t), ...
        hardBlockSequences.Duration(t));
end

%% ================================================================
% 34.15 STORE GENERATED SEQUENCES
% ================================================================

arrowBlockSequences = struct();

% Store the actual 36-trial tables.
arrowBlockSequences.Easy = easyBlockSequences;
arrowBlockSequences.Hard = hardBlockSequences;

% Store block-level metadata separately.
arrowBlockSequences.EasyTargetCounts = easyTargetCounts;
arrowBlockSequences.HardTargetCounts = hardTargetCounts;

arrowBlockSequences.TrialsPerBlock = ...
    trialsPerBlock;

arrowBlockSequences.TrialsPerTargetCount = ...
    trialsPerTargetCount;

%% ================================================================
% 34.16 FINAL SUMMARY
% ================================================================

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 34 COMPLETED\n');
fprintf('===============================================================\n');

fprintf('\nEasy block: %d trials\n', ...
    height(easyBlockSequences));

fprintf('Hard block: %d trials\n', ...
    height(hardBlockSequences));

fprintf('\nEasy target-count distribution:\n');

for nTargets = easyTargetCounts

    fprintf('  %d target(s): %d\n', ...
        nTargets, ...
        sum(easyBlockSequences.TargetCount == nTargets));
end

fprintf('\nHard target-count distribution:\n');

for nTargets = hardTargetCounts

    fprintf('  %d target(s): %d\n', ...
        nTargets, ...
        sum(hardBlockSequences.TargetCount == nTargets));
end

fprintf('\nNo consecutive exact sequence repeats detected.\n');

fprintf('\nNo arrow colour/orientation assignment performed yet.\n');
fprintf('No arrow textures created yet.\n');
fprintf('No CFS timing changed.\n');

fprintf('\nSection 34 completed successfully.\n');



%% ================================================================
% SECTION 35 — BALANCED FACE-IDENTITY ASSIGNMENT
%
% Each block:
%   36 trials
%   12 identities total
%   6 female + 6 male
%   Each identity appears exactly 3 times
%   No same identity on consecutive trials
%
% The same identity pool is used across emotions and awareness
% conditions. Emotion is determined by the block.
% ================================================================

fprintf('\n===============================================================\n');
fprintf('SECTION 35 — FACE IDENTITY ASSIGNMENT\n');
fprintf('===============================================================\n');

%% ---------------------------------------------------------------
% 35.1 PARAMETERS
% ---------------------------------------------------------------

trialsPerBlock = 36;
nIdentities = 12;
repetitionsPerIdentity = 3;

if nIdentities * repetitionsPerIdentity ~= trialsPerBlock
    error(['Identity balancing error: %d identities × %d repetitions ' ...
           'does not equal %d trials.'], ...
           nIdentities, repetitionsPerIdentity, trialsPerBlock);
end

fprintf('Trials per block: %d\n', trialsPerBlock);
fprintf('Face identities: %d\n', nIdentities);
fprintf('Presentations per identity: %d\n', repetitionsPerIdentity);


%% ---------------------------------------------------------------
% 35.2 GET THE 12 IDENTITIES
% ---------------------------------------------------------------
%
% Section 32 loaded 12 face files per emotion.
% We use the filenames from the neutral set as the master identity
% list because all identities should exist across all 3 emotions.
%
% IMPORTANT:
% The identity is based on the filename, not on the emotion folder.
% ---------------------------------------------------------------

neutralFiles = dir(fullfile(neutralDir, '*.png'));

if numel(neutralFiles) ~= nIdentities
    error(['Expected exactly %d neutral face files, but found %d. ' ...
           'Check the neutral stimulus folder.'], ...
           nIdentities, numel(neutralFiles));
end

neutralNames = {neutralFiles.name};

% Sort filenames for reproducible identity indexing.
neutralNames = sort(neutralNames);

fprintf('\nNeutral face files found: %d\n', numel(neutralNames));

for i = 1:nIdentities
    fprintf('  Identity %02d: %s\n', i, neutralNames{i});
end


%% ---------------------------------------------------------------
% 35.3 EXTRACT IDENTITY CODES
% ---------------------------------------------------------------
%
% The identity code is the filename without extension.
%
% Example:
%   AM01NESH.png -> AM01NESH
%
% This allows the same identity to be matched across:
%   neutral
%   angry
%   happy
%
% ---------------------------------------------------------------

identityCodes = cell(nIdentities,1);

for i = 1:nIdentities

    [~, identityCodes{i}, ~] = fileparts(neutralNames{i});

end

% Check for duplicate identity codes.
if numel(unique(identityCodes)) ~= nIdentities
    error('Duplicate identity codes detected in neutral stimulus files.');
end

fprintf('\nIdentity codes extracted successfully.\n');


%% ---------------------------------------------------------------
% 35.4 CREATE THREE PRESENTATIONS OF EACH IDENTITY
% ---------------------------------------------------------------

allIdentityIndices = repelem((1:nIdentities)', ...
                             repetitionsPerIdentity);

if numel(allIdentityIndices) ~= trialsPerBlock
    error('Incorrect number of identity assignments generated.');
end


%% ---------------------------------------------------------------
% 35.5 RANDOMIZE WITH NO CONSECUTIVE IDENTITY REPEATS
% ---------------------------------------------------------------
%
% We shuffle the 36 identity assignments until:
%
%   1. Each identity appears exactly 3 times
%   2. No identity occurs on consecutive trials
%
% The identity frequencies remain exactly balanced.
% ---------------------------------------------------------------

maxIdentityShuffleAttempts = 10000;

identityOrderFound = false;

for attempt = 1:maxIdentityShuffleAttempts

    shuffledIdentityIndices = ...
        allIdentityIndices(randperm(trialsPerBlock));

    if all(shuffledIdentityIndices(1:end-1) ~= ...
           shuffledIdentityIndices(2:end))

        identityOrderFound = true;
        break;
    end

end

if ~identityOrderFound
    error(['Could not generate a valid 36-trial identity order with ' ...
           'no consecutive repetitions after %d attempts.'], ...
           maxIdentityShuffleAttempts);
end

fprintf('\nValid identity order generated.\n');
fprintf('Shuffle attempts required: %d\n', attempt);


%% ---------------------------------------------------------------
% 35.6 VERIFY IDENTITY COUNTS
% ---------------------------------------------------------------

identityCounts = zeros(nIdentities,1);

for i = 1:nIdentities
    identityCounts(i) = ...
        sum(shuffledIdentityIndices == i);
end

if any(identityCounts ~= repetitionsPerIdentity)
    error('Identity balancing verification failed.');
end

if any(shuffledIdentityIndices(1:end-1) == ...
       shuffledIdentityIndices(2:end))
    error('Consecutive identity repetition detected.');
end

fprintf('\nIdentity-count verification passed.\n');
fprintf('Each identity appears exactly %d times.\n', ...
        repetitionsPerIdentity);

fprintf('No identity repeats on consecutive trials.\n');


%% ---------------------------------------------------------------
% 35.7 STORE HUMAN-READABLE IDENTITY INFORMATION
% ---------------------------------------------------------------

blockFaceIdentity = cell(nBlocks,1);

for b = 1:nBlocks

    % Copy the same balanced identity structure into each block.
    %
    % IMPORTANT:
    % We generate a NEW random order for every block below.
    
    identityOrderFound = false;

    for attempt = 1:maxIdentityShuffleAttempts

        candidateOrder = ...
            allIdentityIndices(randperm(trialsPerBlock));

        if all(candidateOrder(1:end-1) ~= ...
               candidateOrder(2:end))

            identityOrderFound = true;
            break;
        end

    end

    if ~identityOrderFound
        error(['Could not generate a valid face identity order ' ...
               'for block %d.'], b);
    end

    blockFaceIdentity{b} = candidateOrder(:);

end


%% ---------------------------------------------------------------
% 35.8 VERIFY EVERY BLOCK
% ---------------------------------------------------------------

for b = 1:nBlocks

    currentOrder = blockFaceIdentity{b};

    % Number of trials
    if numel(currentOrder) ~= trialsPerBlock
        error('Block %d does not contain 36 face identities.', b);
    end

    % Exactly 3 presentations per identity
    currentCounts = zeros(nIdentities,1);

    for i = 1:nIdentities
        currentCounts(i) = sum(currentOrder == i);
    end

    if any(currentCounts ~= repetitionsPerIdentity)
        error(['Face identity balancing failed in block %d.'], b);
    end

    % No consecutive repeats
    if any(currentOrder(1:end-1) == currentOrder(2:end))
        error(['Consecutive face identity repetition detected ' ...
               'in block %d.'], b);
    end

end

fprintf('\nAll %d blocks passed identity verification.\n', nBlocks);


%% ---------------------------------------------------------------
% 35.9 DISPLAY FIRST BLOCK AS A CHECK
% ---------------------------------------------------------------

fprintf('\n---------------------------------------------------------------\n');
fprintf('Example identity order — Block 1\n');
fprintf('---------------------------------------------------------------\n');

for t = 1:trialsPerBlock

    identityIndex = blockFaceIdentity{1}(t);

    fprintf('Trial %02d: Identity %02d (%s)\n', ...
            t, ...
            identityIndex, ...
            identityCodes{identityIndex});

end


%% ---------------------------------------------------------------
% 35.10 STORE IN ARROW / BLOCK STRUCTURE
% ---------------------------------------------------------------

%
% Do NOT overwrite the arrow sequences.
% We simply add the corresponding face identity information.
%

for b = 1:nBlocks

    arrowBlockSequences(b).FaceIdentityIndex = ...
        blockFaceIdentity{b};

    arrowBlockSequences(b).FaceIdentityCode = ...
        identityCodes(blockFaceIdentity{b});

end


%% ---------------------------------------------------------------
% 35.11 FINAL SUMMARY
% ---------------------------------------------------------------

fprintf('\n===============================================================\n');
fprintf('SECTION 35 COMPLETED SUCCESSFULLY\n');
fprintf('===============================================================\n');

fprintf('Blocks: %d\n', nBlocks);
fprintf('Trials per block: %d\n', trialsPerBlock);
fprintf('Identities per block: %d\n', nIdentities);
fprintf('Presentations per identity: %d\n', repetitionsPerIdentity);
fprintf('Consecutive identity repetitions: NONE\n');
fprintf('Identity balancing: PASSED\n');

fprintf('===============================================================\n\n');



%% ================================================================
% SECTION 36 — ARROW COLOUR / ORIENTATION ASSIGNMENT
%
% Converts each 1/o RSVP sequence into actual arrow identities.
%
% 1 = target
% o = non-target
%
% HARD / HIGH:
%   Targets:
%       Yellow upright
%       Green downright
%
%   Non-targets:
%       Green upright
%       Yellow downright
%       Pink upright/downright
%       Orange upright/downright
%       Blue upright/downright
%       Red upright/downright
%
% EASY / LOW:
%   Targets:
%       Red upright/downright
%
%   Non-targets:
%       Yellow upright/downright
%       Green upright/downright
%       Pink upright/downright
%       Orange upright/downright
%       Blue upright/downright
%
% Constraints:
%   - Target status determined by colour × orientation.
%   - Colours cannot repeat consecutively.
%   - Orientation may repeat up to 3 consecutive arrows.
%
% No textures created.
% No stimuli presented.
% No CFS timing changed.
% ================================================================

fprintf('\n===============================================================\n');
fprintf('SECTION 36 — ARROW COLOUR / ORIENTATION ASSIGNMENT\n');
fprintf('===============================================================\n');


%% ---------------------------------------------------------------
% 36.1 EXTRACT SEQUENCE CODES FROM SECTION 34
% ---------------------------------------------------------------

% Section 34 stores Easy and Hard sequences as tables.
% Extract the Sequence variable explicitly.

if istable(easyBlockSequences)

    if ~ismember('Sequence', easyBlockSequences.Properties.VariableNames)
        error('easyBlockSequences is a table but has no Sequence column.');
    end

    easySequenceCodes = easyBlockSequences.Sequence;

else

    easySequenceCodes = easyBlockSequences;

end


if istable(hardBlockSequences)

    if ~ismember('Sequence', hardBlockSequences.Properties.VariableNames)
        error('hardBlockSequences is a table but has no Sequence column.');
    end

    hardSequenceCodes = hardBlockSequences.Sequence;

else

    hardSequenceCodes = hardBlockSequences;

end


% Convert sequence codes to cell arrays of character vectors.
%
% This makes the rest of the section independent of whether the
% original Sequence column was string, char, or cell.

if isstring(easySequenceCodes)

    easySequenceCodes = cellstr(easySequenceCodes);

elseif ischar(easySequenceCodes)

    easySequenceCodes = cellstr(easySequenceCodes);

end


if isstring(hardSequenceCodes)

    hardSequenceCodes = cellstr(hardSequenceCodes);

elseif ischar(hardSequenceCodes)

    hardSequenceCodes = cellstr(hardSequenceCodes);

end


fprintf('\nSequence codes extracted successfully.\n');
fprintf('Easy sequences: %d\n',numel(easySequenceCodes));
fprintf('Hard sequences: %d\n',numel(hardSequenceCodes));


%% ---------------------------------------------------------------
% 36.2 DEFINE ARROW IDENTITIES
% ---------------------------------------------------------------

arrowIdentityNames = { ...
    'Yellow_Upright', ...
    'Yellow_Downright', ...
    'Green_Upright', ...
    'Green_Downright', ...
    'Pink_Upright', ...
    'Pink_Downright', ...
    'Orange_Upright', ...
    'Orange_Downright', ...
    'Blue_Upright', ...
    'Blue_Downright', ...
    'Red_Upright', ...
    'Red_Downright'};

nArrowIdentities = numel(arrowIdentityNames);


%% ---------------------------------------------------------------
% 36.3 DEFINE COLOUR AND ORIENTATION
% ---------------------------------------------------------------

arrowIdentity = struct( ...
    'Name',{}, ...
    'Colour',{}, ...
    'Orientation',{});

for i = 1:nArrowIdentities

    arrowIdentity(i).Name = arrowIdentityNames{i};

end


% Yellow
idx = find(strcmp(arrowIdentityNames,'Yellow_Upright'));
arrowIdentity(idx).Colour = 'Yellow';
arrowIdentity(idx).Orientation = 'Upright';

idx = find(strcmp(arrowIdentityNames,'Yellow_Downright'));
arrowIdentity(idx).Colour = 'Yellow';
arrowIdentity(idx).Orientation = 'Downright';


% Green
idx = find(strcmp(arrowIdentityNames,'Green_Upright'));
arrowIdentity(idx).Colour = 'Green';
arrowIdentity(idx).Orientation = 'Upright';

idx = find(strcmp(arrowIdentityNames,'Green_Downright'));
arrowIdentity(idx).Colour = 'Green';
arrowIdentity(idx).Orientation = 'Downright';


% Pink
idx = find(strcmp(arrowIdentityNames,'Pink_Upright'));
arrowIdentity(idx).Colour = 'Pink';
arrowIdentity(idx).Orientation = 'Upright';

idx = find(strcmp(arrowIdentityNames,'Pink_Downright'));
arrowIdentity(idx).Colour = 'Pink';
arrowIdentity(idx).Orientation = 'Downright';


% Orange
idx = find(strcmp(arrowIdentityNames,'Orange_Upright'));
arrowIdentity(idx).Colour = 'Orange';
arrowIdentity(idx).Orientation = 'Upright';

idx = find(strcmp(arrowIdentityNames,'Orange_Downright'));
arrowIdentity(idx).Colour = 'Orange';
arrowIdentity(idx).Orientation = 'Downright';


% Blue
idx = find(strcmp(arrowIdentityNames,'Blue_Upright'));
arrowIdentity(idx).Colour = 'Blue';
arrowIdentity(idx).Orientation = 'Upright';

idx = find(strcmp(arrowIdentityNames,'Blue_Downright'));
arrowIdentity(idx).Colour = 'Blue';
arrowIdentity(idx).Orientation = 'Downright';


% Red
idx = find(strcmp(arrowIdentityNames,'Red_Upright'));
arrowIdentity(idx).Colour = 'Red';
arrowIdentity(idx).Orientation = 'Upright';

idx = find(strcmp(arrowIdentityNames,'Red_Downright'));
arrowIdentity(idx).Colour = 'Red';
arrowIdentity(idx).Orientation = 'Downright';


%% ---------------------------------------------------------------
% 36.4 DEFINE TARGET / NON-TARGET IDENTITIES
% ---------------------------------------------------------------

% HARD / HIGH

hardTargetIdentityNames = { ...
    'Yellow_Upright', ...
    'Green_Downright'};

hardNonTargetIdentityNames = { ...
    'Green_Upright', ...
    'Yellow_Downright', ...
    'Pink_Upright', ...
    'Pink_Downright', ...
    'Orange_Upright', ...
    'Orange_Downright', ...
    'Blue_Upright', ...
    'Blue_Downright', ...
    'Red_Upright', ...
    'Red_Downright'};


% EASY / LOW

easyTargetIdentityNames = { ...
    'Red_Upright', ...
    'Red_Downright'};

easyNonTargetIdentityNames = { ...
    'Yellow_Upright', ...
    'Yellow_Downright', ...
    'Green_Upright', ...
    'Green_Downright', ...
    'Pink_Upright', ...
    'Pink_Downright', ...
    'Orange_Upright', ...
    'Orange_Downright', ...
    'Blue_Upright', ...
    'Blue_Downright'};


%% ---------------------------------------------------------------
% 36.5 CONVERT NAMES TO NUMERIC INDICES
% ---------------------------------------------------------------

easyTargetIndices = zeros(numel(easyTargetIdentityNames),1);

for i = 1:numel(easyTargetIdentityNames)

    easyTargetIndices(i) = ...
        find(strcmp(arrowIdentityNames, ...
                    easyTargetIdentityNames{i}));

end


easyNonTargetIndices = zeros(numel(easyNonTargetIdentityNames),1);

for i = 1:numel(easyNonTargetIdentityNames)

    easyNonTargetIndices(i) = ...
        find(strcmp(arrowIdentityNames, ...
                    easyNonTargetIdentityNames{i}));

end


hardTargetIndices = zeros(numel(hardTargetIdentityNames),1);

for i = 1:numel(hardTargetIdentityNames)

    hardTargetIndices(i) = ...
        find(strcmp(arrowIdentityNames, ...
                    hardTargetIdentityNames{i}));

end


hardNonTargetIndices = zeros(numel(hardNonTargetIdentityNames),1);

for i = 1:numel(hardNonTargetIdentityNames)

    hardNonTargetIndices(i) = ...
        find(strcmp(arrowIdentityNames, ...
                    hardNonTargetIdentityNames{i}));

end


fprintf('\nTarget and non-target identities defined.\n');


%% ---------------------------------------------------------------
% 36.6 ASSIGN ARROWS TO EASY SEQUENCES
% ---------------------------------------------------------------

fprintf('\nAssigning arrows to EASY sequences...\n');

easyArrowAssignments = cell(numel(easySequenceCodes),1);

for t = 1:numel(easySequenceCodes)

    sequenceCode = easySequenceCodes{t};
    sequenceLength = length(sequenceCode);

    assignedIndices = zeros(1,sequenceLength);

    for position = 1:sequenceLength

        isTarget = sequenceCode(position) == '1';

        if isTarget
            candidateIndices = easyTargetIndices;
        else
            candidateIndices = easyNonTargetIndices;
        end


        % ---------------------------------------------------------
        % No consecutive colours
        % ---------------------------------------------------------

        if position > 1

            previousIdentity = assignedIndices(position-1);

            previousColour = ...
                arrowIdentity(previousIdentity).Colour;

            candidateKeep = true(size(candidateIndices));

            for c = 1:numel(candidateIndices)

                candidateColour = ...
                    arrowIdentity(candidateIndices(c)).Colour;

                if strcmp(candidateColour,previousColour)
                    candidateKeep(c) = false;
                end

            end

            candidateIndices = ...
                candidateIndices(candidateKeep);

        end


        % ---------------------------------------------------------
        % Maximum 3 consecutive identical orientations
        % ---------------------------------------------------------

        if position >= 4

            orientation1 = ...
                arrowIdentity(assignedIndices(position-1)).Orientation;

            orientation2 = ...
                arrowIdentity(assignedIndices(position-2)).Orientation;

            orientation3 = ...
                arrowIdentity(assignedIndices(position-3)).Orientation;

            if strcmp(orientation1,orientation2) && ...
               strcmp(orientation2,orientation3)

                candidateKeep = true(size(candidateIndices));

                for c = 1:numel(candidateIndices)

                    candidateOrientation = ...
                        arrowIdentity(candidateIndices(c)).Orientation;

                    if strcmp(candidateOrientation,orientation1)
                        candidateKeep(c) = false;
                    end

                end

                candidateIndices = ...
                    candidateIndices(candidateKeep);

            end

        end


        % ---------------------------------------------------------
        % Safety check
        % ---------------------------------------------------------

        if isempty(candidateIndices)

            error(['Could not assign a valid Easy arrow at trial %d, ' ...
                   'position %d, sequence "%s".'], ...
                   t,position,sequenceCode);

        end


        % ---------------------------------------------------------
        % Randomly select candidate
        % ---------------------------------------------------------

        selectedCandidate = ...
            candidateIndices(randi(numel(candidateIndices)));

        assignedIndices(position) = selectedCandidate;

    end

    easyArrowAssignments{t} = assignedIndices;

end

fprintf('Easy arrow assignment completed.\n');



%% ---------------------------------------------------------------
% 36.7 ASSIGN ARROWS TO HARD SEQUENCES
% ---------------------------------------------------------------

fprintf('\nAssigning arrows to HARD sequences...\n');

hardArrowAssignments = cell(numel(hardSequenceCodes),1);

for t = 1:numel(hardSequenceCodes)

    sequenceCode = hardSequenceCodes{t};
    sequenceLength = length(sequenceCode);

    % -------------------------------------------------------------
    % Start recursive backtracking assignment
    % -------------------------------------------------------------

    assignedIndices = zeros(1,sequenceLength);

    [success,assignedIndices] = ...
        assignHardArrowRecursive( ...
            sequenceCode, ...
            1, ...
            assignedIndices, ...
            hardTargetIndices, ...
            hardNonTargetIndices, ...
            arrowIdentity);

    % -------------------------------------------------------------
    % Safety check
    % -------------------------------------------------------------

    if ~success

        error(['Could not find ANY valid Hard arrow assignment at ' ...
               'trial %d, sequence "%s".'], ...
               t,sequenceCode);

    end

    hardArrowAssignments{t} = assignedIndices;

end

fprintf('Hard arrow assignment completed.\n');



%% ---------------------------------------------------------------
% 36.8 VERIFY EASY ASSIGNMENTS
% ---------------------------------------------------------------

fprintf('\nVerifying EASY arrow assignments...\n');

for t = 1:numel(easySequenceCodes)

    sequenceCode = easySequenceCodes{t};
    assignedIndices = easyArrowAssignments{t};

    if length(sequenceCode) ~= numel(assignedIndices)
        error('Easy trial %d: sequence/arrow length mismatch.',t);
    end

    for position = 1:length(sequenceCode)

        currentIdentity = assignedIndices(position);

        expectedTarget = sequenceCode(position) == '1';

        actualTarget = ...
            any(currentIdentity == easyTargetIndices);

        if expectedTarget ~= actualTarget
            error(['Easy trial %d position %d: target-status mismatch.'], ...
                  t,position);
        end


        if position > 1

            previousColour = ...
                arrowIdentity(assignedIndices(position-1)).Colour;

            currentColour = ...
                arrowIdentity(currentIdentity).Colour;

            if strcmp(previousColour,currentColour)
                error(['Easy trial %d position %d: consecutive ' ...
                       'colours detected.'],t,position);
            end

        end


        if position >= 4

            o1 = arrowIdentity(assignedIndices(position-1)).Orientation;
            o2 = arrowIdentity(assignedIndices(position-2)).Orientation;
            o3 = arrowIdentity(assignedIndices(position-3)).Orientation;
            o4 = arrowIdentity(assignedIndices(position)).Orientation;

            if strcmp(o1,o2) && strcmp(o2,o3) && strcmp(o3,o4)
                error(['Easy trial %d position %d: orientation repeated ' ...
                       'more than 3 consecutive times.'],t,position);
            end

        end

    end

end

fprintf('Easy assignment verification passed.\n');


%% ---------------------------------------------------------------
% 36.9 VERIFY HARD ASSIGNMENTS
% ---------------------------------------------------------------

fprintf('\nVerifying HARD arrow assignments...\n');

for t = 1:numel(hardSequenceCodes)

    sequenceCode = hardSequenceCodes{t};
    assignedIndices = hardArrowAssignments{t};

    if length(sequenceCode) ~= numel(assignedIndices)
        error('Hard trial %d: sequence/arrow length mismatch.',t);
    end

    for position = 1:length(sequenceCode)

        currentIdentity = assignedIndices(position);

        expectedTarget = sequenceCode(position) == '1';

        actualTarget = ...
            any(currentIdentity == hardTargetIndices);

        if expectedTarget ~= actualTarget
            error(['Hard trial %d position %d: target-status mismatch.'], ...
                  t,position);
        end


        if position > 1

            previousColour = ...
                arrowIdentity(assignedIndices(position-1)).Colour;

            currentColour = ...
                arrowIdentity(currentIdentity).Colour;

            if strcmp(previousColour,currentColour)
                error(['Hard trial %d position %d: consecutive ' ...
                       'colours detected.'],t,position);
            end

        end


        if position >= 4

            o1 = arrowIdentity(assignedIndices(position-1)).Orientation;
            o2 = arrowIdentity(assignedIndices(position-2)).Orientation;
            o3 = arrowIdentity(assignedIndices(position-3)).Orientation;
            o4 = arrowIdentity(assignedIndices(position)).Orientation;

            if strcmp(o1,o2) && strcmp(o2,o3) && strcmp(o3,o4)
                error(['Hard trial %d position %d: orientation repeated ' ...
                       'more than 3 consecutive times.'],t,position);
            end

        end

    end

end

fprintf('Hard assignment verification passed.\n');


%% ---------------------------------------------------------------
% 36.10 STORE ASSIGNMENTS
% ---------------------------------------------------------------

% Keep the original Easy and Hard sequence tables intact.
% Store arrow assignments in separate variables.

fprintf('\nArrow assignments stored successfully.\n');


%% ---------------------------------------------------------------
% 36.11 DISPLAY EXAMPLES
% ---------------------------------------------------------------

fprintf('\n---------------------------------------------------------------\n');
fprintf('EXAMPLE EASY ARROW ASSIGNMENTS\n');
fprintf('---------------------------------------------------------------\n');

for t = 1:min(5,numel(easySequenceCodes))

    fprintf('\nTrial %02d\n',t);
    fprintf('Sequence: %s\n',easySequenceCodes{t});

    assignedIndices = easyArrowAssignments{t};

    for p = 1:numel(assignedIndices)

        idx = assignedIndices(p);

        fprintf('  Position %02d: %-20s\n', ...
                p,arrowIdentity(idx).Name);

    end

end


fprintf('\n---------------------------------------------------------------\n');
fprintf('EXAMPLE HARD ARROW ASSIGNMENTS\n');
fprintf('---------------------------------------------------------------\n');

for t = 1:min(5,numel(hardSequenceCodes))

    fprintf('\nTrial %02d\n',t);
    fprintf('Sequence: %s\n',hardSequenceCodes{t});

    assignedIndices = hardArrowAssignments{t};

    for p = 1:numel(assignedIndices)

        idx = assignedIndices(p);

        fprintf('  Position %02d: %-20s\n', ...
                p,arrowIdentity(idx).Name);

    end

end


%% ---------------------------------------------------------------
% 36.12 FINAL SUMMARY
% ---------------------------------------------------------------

fprintf('\n===============================================================\n');
fprintf('SECTION 36 COMPLETED SUCCESSFULLY\n');
fprintf('===============================================================\n');

fprintf('Easy trials assigned: %d\n', ...
        numel(easyArrowAssignments));

fprintf('Hard trials assigned: %d\n', ...
        numel(hardArrowAssignments));

fprintf('Target/non-target status: VERIFIED\n');
fprintf('Consecutive colour constraint: VERIFIED\n');
fprintf('Maximum orientation run: 3\n');
fprintf('Orientation constraint: VERIFIED\n');

fprintf('\nNo arrow textures created.\n');
fprintf('No stimuli presented.\n');
fprintf('No CFS timing changed.\n');

fprintf('===============================================================\n\n');



%% ================================================================
% SECTION 37: INSPECT ARROW TASK STRUCTURE
% ================================================================

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 37: INSPECTING ARROW TASK STRUCTURE\n');
fprintf('===============================================================\n');

fprintf('\narrowTask fields:\n');
disp(fieldnames(arrowTask));

fprintf('\narrowIdentity fields:\n');
disp(fieldnames(arrowIdentity));

fprintf('\narrowIdentityNames:\n');
disp(arrowIdentityNames);

fprintf('\narrowIdentity contents:\n');
disp(arrowIdentity);

fprintf('\narrowTask contents:\n');
disp(arrowTask);

fprintf('\n===============================================================\n');
fprintf('SECTION 37 INSPECTION COMPLETED\n');
fprintf('===============================================================\n');




%% ================================================================
% SECTION 38 — ARROW GEOMETRY DEFINITION
%
% Purpose:
%   Define the physical presentation geometry of the RSVP arrows.
%
% This section:
%   - defines arrow size in visual-angle units
%   - converts the size to pixels
%   - defines the arrow shape
%   - defines the six arrow colours
%   - defines upright/downright orientations
%   - does NOT create PTB textures yet
%   - does NOT present any participant trials
%
% ================================================================

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 38 — ARROW GEOMETRY DEFINITION\n');
fprintf('===============================================================\n');


%% ---------------------------------------------------------------
% 38.1 ARROW VISUAL SIZE
% ---------------------------------------------------------------

% The RSVP arrows are presented centrally.
%
% We use a compact arrow so that the stimulus remains clearly
% distinguishable while fitting comfortably within the RSVP
% presentation area.

arrowWidth_deg  = 0.90;
arrowHeight_deg = 1.50;


%% ---------------------------------------------------------------
% 38.2 CONVERT VISUAL ANGLE TO PIXELS
% ---------------------------------------------------------------

% Horizontal conversion

arrowWidth_cm = ...
    2 * viewingDistance_cm * ...
    tand(arrowWidth_deg / 2);

arrowWidth_px = ...
    round(arrowWidth_cm * pixelsPerCm_horizontal);


% Vertical conversion

arrowHeight_cm = ...
    2 * viewingDistance_cm * ...
    tand(arrowHeight_deg / 2);

arrowHeight_px = ...
    round(arrowHeight_cm * pixelsPerCm_vertical);


%% ---------------------------------------------------------------
% 38.3 CHECK PIXEL SIZE
% ---------------------------------------------------------------

fprintf('\nArrow visual geometry:\n');

fprintf('  Width  = %.2f degrees\n', ...
    arrowWidth_deg);

fprintf('  Height = %.2f degrees\n', ...
    arrowHeight_deg);

fprintf('  Width  = %.2f cm\n', ...
    arrowWidth_cm);

fprintf('  Height = %.2f cm\n', ...
    arrowHeight_cm);

fprintf('  Width  = %d px\n', ...
    arrowWidth_px);

fprintf('  Height = %d px\n', ...
    arrowHeight_px);


%% ---------------------------------------------------------------
% 38.4 DEFINE ARROW COLOURS
% ---------------------------------------------------------------

arrowColourRGB = struct();

arrowColourRGB.Yellow = [255 255 0];
arrowColourRGB.Green  = [0 255 0];
arrowColourRGB.Pink   = [255 105 180];
arrowColourRGB.Orange = [255 165 0];
arrowColourRGB.Blue   = [0 120 255];
arrowColourRGB.Red    = [255 0 0];


%% ---------------------------------------------------------------
% 38.5 DEFINE ORIENTATIONS
% ---------------------------------------------------------------

arrowOrientations = { ...
    'Upright', ...
    'Downright'};


%% ---------------------------------------------------------------
% 38.6 DEFINE ARROW SHAPE
% ---------------------------------------------------------------

% The arrow consists of:
%
%   - a triangular arrowhead
%   - a rectangular shaft
%
% The arrow is initially constructed upright.
% The downright version is obtained by vertical inversion.

arrowCanvasWidth  = arrowWidth_px;
arrowCanvasHeight = arrowHeight_px;

arrowImage = uint8(zeros( ...
    arrowCanvasHeight, ...
    arrowCanvasWidth, ...
    3));


%% ---------------------------------------------------------------
% 38.7 ARROW COLOUR NAMES
% ---------------------------------------------------------------

arrowColourNames = { ...
    'Yellow', ...
    'Green', ...
    'Pink', ...
    'Orange', ...
    'Blue', ...
    'Red'};


%% ---------------------------------------------------------------
% 38.8 STORE GEOMETRY
% ---------------------------------------------------------------

arrowGeometry = struct();

arrowGeometry.Width_deg = arrowWidth_deg;
arrowGeometry.Height_deg = arrowHeight_deg;

arrowGeometry.Width_cm = arrowWidth_cm;
arrowGeometry.Height_cm = arrowHeight_cm;

arrowGeometry.Width_px = arrowWidth_px;
arrowGeometry.Height_px = arrowHeight_px;

arrowGeometry.CanvasWidth_px = arrowCanvasWidth;
arrowGeometry.CanvasHeight_px = arrowCanvasHeight;

arrowGeometry.ColourNames = arrowColourNames;
arrowGeometry.Orientations = arrowOrientations;


%% ---------------------------------------------------------------
% 38.9 VERIFY EXISTING ARROW IDENTITIES
% ---------------------------------------------------------------

if numel(arrowIdentity) ~= 12

    error(['Expected 12 arrow identities, but found %d.'], ...
        numel(arrowIdentity));

end


for i = 1:numel(arrowIdentity)

    if isempty(arrowIdentity(i).Name)
        error('Arrow identity %d has no name.',i);
    end

    if isempty(arrowIdentity(i).Colour)
        error('Arrow identity %d has no colour.',i);
    end

    if isempty(arrowIdentity(i).Orientation)
        error('Arrow identity %d has no orientation.',i);
    end

end


%% ---------------------------------------------------------------
% 38.10 DISPLAY IDENTITY TABLE
% ---------------------------------------------------------------

fprintf('\n---------------------------------------------------------------\n');
fprintf('ARROW IDENTITY TABLE\n');
fprintf('---------------------------------------------------------------\n');

for i = 1:numel(arrowIdentity)

    fprintf('%2d: %-20s | %-8s | %-10s\n', ...
        i, ...
        arrowIdentity(i).Name, ...
        arrowIdentity(i).Colour, ...
        arrowIdentity(i).Orientation);

end


%% ---------------------------------------------------------------
% 38.11 STORE COLOUR INFORMATION IN IDENTITY STRUCTURE
% ---------------------------------------------------------------

for i = 1:numel(arrowIdentity)

    colourName = arrowIdentity(i).Colour;

    if ~isfield(arrowColourRGB,colourName)

        error(['No RGB colour has been defined for arrow colour: %s'], ...
            colourName);

    end

    arrowIdentity(i).RGB = ...
        arrowColourRGB.(colourName);

end


%% ---------------------------------------------------------------
% 38.12 FINAL SUMMARY
% ---------------------------------------------------------------

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 38 COMPLETED\n');
fprintf('===============================================================\n');

fprintf('\nArrow geometry:\n');
fprintf('  %.2f × %.2f degrees\n', ...
    arrowWidth_deg,arrowHeight_deg);

fprintf('  %d × %d pixels\n', ...
    arrowWidth_px,arrowHeight_px);

fprintf('\nArrow colours: %d\n', ...
    numel(arrowColourNames));

fprintf('Arrow orientations: %d\n', ...
    numel(arrowOrientations));

fprintf('Arrow identities: %d\n', ...
    numel(arrowIdentity));

fprintf('\nNo PTB textures created.\n');
fprintf('No stimuli presented.\n');
fprintf('No RSVP trials run.\n');

fprintf('\nSection 38 completed successfully.\n');



%% ================================================================
% SECTION 39 — CREATE AND VERIFY ARROW TEXTURES
%
% Purpose:
%   Create PTB textures for all 12 arrow identities:
%
%   Yellow_Upright
%   Yellow_Downright
%   Green_Upright
%   Green_Downright
%   Pink_Upright
%   Pink_Downright
%   Orange_Upright
%   Orange_Downright
%   Blue_Upright
%   Blue_Downright
%   Red_Upright
%   Red_Downright
%
%   This section:
%   - creates the arrow pixel images
%   - creates PTB textures
%   - verifies all 12 textures
%   - displays them on screen
%
%   It does NOT run experimental trials.
%
% ================================================================

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 39 — CREATE AND VERIFY ARROW TEXTURES\n');
fprintf('===============================================================\n');


%% ---------------------------------------------------------------
% 39.1 INITIALIZE TEXTURE STORAGE
% ---------------------------------------------------------------

nArrowIdentities = numel(arrowIdentity);

arrowTextures = zeros(1,nArrowIdentities);

arrowImages = cell(1,nArrowIdentities);


%% ---------------------------------------------------------------
% 39.2 ARROW CANVAS
% ---------------------------------------------------------------

canvasW = arrowGeometry.CanvasWidth_px;
canvasH = arrowGeometry.CanvasHeight_px;

fprintf('\nArrow canvas:\n');
fprintf('  Width  = %d px\n',canvasW);
fprintf('  Height = %d px\n',canvasH);


%% ---------------------------------------------------------------
% 39.3 DEFINE ARROW SHAPE
%
% Coordinate system:
%   x increases to the right
%   y increases downward
%
% Upright arrow:
%   ^
%
% Downright arrow:
%   v
%
% The arrow is drawn using:
%   - triangular head
%   - rectangular shaft
%
% ---------------------------------------------------------------

% Arrow dimensions

shaftWidth = max(3,round(canvasW * 0.18));
shaftHeight = round(canvasH * 0.42);

headWidth = round(canvasW * 0.62);
headHeight = round(canvasH * 0.42);


%% ---------------------------------------------------------------
% 39.4 CREATE EACH ARROW IMAGE
% ---------------------------------------------------------------

for i = 1:nArrowIdentities

    % ------------------------------------------------------------
    % Get colour
    % ------------------------------------------------------------

    rgb = arrowIdentity(i).RGB;


    % ------------------------------------------------------------
    % Start with black background
    % ------------------------------------------------------------

    img = uint8(zeros(canvasH,canvasW,3));


    % ------------------------------------------------------------
    % Coordinate centre
    % ------------------------------------------------------------

    cx = (canvasW + 1) / 2;
    cy = (canvasH + 1) / 2;


    % ------------------------------------------------------------
    % Determine orientation
    % ------------------------------------------------------------

    isUpright = strcmpi( ...
        arrowIdentity(i).Orientation, ...
        'Upright');


    % ------------------------------------------------------------
    % Arrow shaft
    % ------------------------------------------------------------

    shaftX1 = round(cx - shaftWidth/2);
    shaftX2 = round(cx + shaftWidth/2);

    if isUpright

        shaftY1 = round(cy);
        shaftY2 = round(cy + shaftHeight/2);

    else

        shaftY1 = round(cy - shaftHeight/2);
        shaftY2 = round(cy);

    end


    shaftX1 = max(1,shaftX1);
    shaftX2 = min(canvasW,shaftX2);

    shaftY1 = max(1,shaftY1);
    shaftY2 = min(canvasH,shaftY2);


    % ------------------------------------------------------------
    % Draw shaft
    % ------------------------------------------------------------

    img(shaftY1:shaftY2, ...
        shaftX1:shaftX2,1) = rgb(1);

    img(shaftY1:shaftY2, ...
        shaftX1:shaftX2,2) = rgb(2);

    img(shaftY1:shaftY2, ...
        shaftX1:shaftX2,3) = rgb(3);


    % ------------------------------------------------------------
    % Arrowhead
    % ------------------------------------------------------------

    halfHead = floor(headWidth/2);


    if isUpright

        tipY = round(cy - headHeight/2);

        baseY = round(cy);

    else

        tipY = round(cy + headHeight/2);

        baseY = round(cy);

    end


    % ------------------------------------------------------------
    % Draw triangular arrowhead
    % ------------------------------------------------------------

    for y = min(tipY,baseY):max(tipY,baseY)

        if isUpright

            progress = ...
                (y - tipY) / max(1,(baseY - tipY));

        else

            progress = ...
                (y - baseY) / max(1,(tipY - baseY));

        end

        currentHalfWidth = ...
            round(halfHead * progress);

        x1 = round(cx - currentHalfWidth);
        x2 = round(cx + currentHalfWidth);

        x1 = max(1,x1);
        x2 = min(canvasW,x2);

        if x1 <= x2

            img(y,x1:x2,1) = rgb(1);
            img(y,x1:x2,2) = rgb(2);
            img(y,x1:x2,3) = rgb(3);

        end

    end


    % ------------------------------------------------------------
    % Store image
    % ------------------------------------------------------------

    arrowImages{i} = img;


    % ------------------------------------------------------------
    % Create PTB texture
    % ------------------------------------------------------------

    arrowTextures(i) = ...
        Screen('MakeTexture',win,img);

end


%% ---------------------------------------------------------------
% 39.5 VERIFY TEXTURE CREATION
% ---------------------------------------------------------------

if any(arrowTextures <= 0)

    error('One or more arrow textures were not created correctly.');

end


fprintf('\nArrow textures created successfully:\n');

for i = 1:nArrowIdentities

    fprintf('  %2d: %-20s | Texture ID = %d\n', ...
        i, ...
        arrowIdentity(i).Name, ...
        arrowTextures(i));

end


%% ---------------------------------------------------------------
% 39.6 STORE TEXTURES
% ---------------------------------------------------------------

arrowTextureSet = struct();

arrowTextureSet.Textures = arrowTextures;

arrowTextureSet.Images = arrowImages;

arrowTextureSet.IdentityNames = ...
    arrowIdentityNames;

arrowTextureSet.Width_px = canvasW;

arrowTextureSet.Height_px = canvasH;


%% ---------------------------------------------------------------
% 39.7 DISPLAY VERIFICATION SCREEN
% ---------------------------------------------------------------

fprintf('\nDisplaying arrow texture verification screen.\n');
fprintf('Press SPACE to continue.\n');

Screen('FillRect',win,backgroundColor);


% Display positions in a 4 × 3 grid

nColumns = 4;
nRows = 3;

displayAreaW = min( ...
    windowRect(3) * 0.75, ...
    nColumns * 180);

displayAreaH = min( ...
    windowRect(4) * 0.65, ...
    nRows * 180);


xSpacing = displayAreaW / nColumns;
ySpacing = displayAreaH / nRows;


for i = 1:nArrowIdentities

    row = ceil(i / nColumns);
    col = mod(i-1,nColumns) + 1;

    x = ...
        windowRect(3)/2 ...
        - displayAreaW/2 ...
        + (col - 0.5) * xSpacing;

    y = ...
        windowRect(4)/2 ...
        - displayAreaH/2 ...
        + (row - 0.5) * ySpacing;


    dstRect = CenterRectOnPointd( ...
        [0 0 canvasW canvasH], ...
        x,y);


    Screen('DrawTexture', ...
        win, ...
        arrowTextures(i), ...
        [], ...
        dstRect);


    % Identity label

    DrawFormattedText( ...
        win, ...
        arrowIdentity(i).Name, ...
        x - 70, ...
        y + 30, ...
        [255 255 255]);

end


DrawFormattedText( ...
    win, ...
    'ARROW TEXTURE VERIFICATION\n\nPress SPACE to continue.', ...
    'center', ...
    windowRect(4) - 100, ...
    [255 255 255], ...
    [], ...
    [], ...
    1.5);


Screen('Flip',win);


%% ---------------------------------------------------------------
% 39.8 WAIT FOR SPACE
% ---------------------------------------------------------------

spaceKey = KbName('SPACE');

KbReleaseWait;

while true

    [keyDown,~,keyCode] = KbCheck;

    if keyDown

        if keyCode(spaceKey)

            KbReleaseWait;
            break;

        end

    end

end


%% ---------------------------------------------------------------
% 39.9 FINAL SUMMARY
% ---------------------------------------------------------------

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 39 COMPLETED\n');
fprintf('===============================================================\n');

fprintf('\nTotal arrow textures: %d\n', ...
    numel(arrowTextures));

fprintf('Arrow size: %d × %d px\n', ...
    canvasW,canvasH);

fprintf('Arrow identities verified: YES\n');
fprintf('PTB textures created: YES\n');
fprintf('Texture verification screen completed: YES\n');

fprintf('\nNo experimental trials were run.\n');
fprintf('No sequence timing was changed.\n');
fprintf('No CFS timing was changed.\n');

fprintf('\nSection 39 completed successfully.\n');



%% ================================================================
% SECTION 40 — INSPECT BACKGROUND AND WINDOW SETTINGS
% ================================================================

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 40 — INSPECT BACKGROUND AND WINDOW SETTINGS\n');
fprintf('===============================================================\n');


%% ---------------------------------------------------------------
% 40.1 CHECK BACKGROUND VARIABLE
% ---------------------------------------------------------------

fprintf('\nCurrent backgroundColor variable:\n');

if exist('backgroundColor','var')

    disp(backgroundColor);

    fprintf('Class: %s\n',class(backgroundColor));
    fprintf('Size:  ');
    disp(size(backgroundColor));

else

    fprintf('backgroundColor does NOT exist.\n');

end


%% ---------------------------------------------------------------
% 40.2 CHECK COMMON BACKGROUND VARIABLES
% ---------------------------------------------------------------

fprintf('\nOther background-related variables:\n');

backgroundVariables = { ...
    'testBackground', ...
    'geometryTestBackground', ...
    'fusionGray', ...
    'backgroundColor'};


for i = 1:numel(backgroundVariables)

    variableName = backgroundVariables{i};

    if exist(variableName,'var')

        fprintf('\n%s =\n',variableName);
        disp(eval(variableName));

    end

end


%% ---------------------------------------------------------------
% 40.3 CHECK WINDOW
% ---------------------------------------------------------------

fprintf('\nWindow information:\n');

fprintf('win = %d\n',win);

if isempty(Screen('Windows'))

    fprintf('WARNING: No PTB windows are currently open.\n');

else

    fprintf('Currently open PTB windows/textures detected.\n');

end


%% ---------------------------------------------------------------
% 40.4 DRAW KNOWN TEST COLOURS
% ---------------------------------------------------------------

fprintf('\nDisplaying explicit background colour test.\n');
fprintf('Press SPACE after inspecting the screen.\n');

   
% Explicit BLACK

Screen('FillRect',win,[0 0 0]);

DrawFormattedText( ...
    win, ...
    'BLACK  [0 0 0]', ...
    'center', ...
    'center', ...
    [255 255 255]);

Screen('Flip',win);

KbReleaseWait;

while true

    [keyDown,~,keyCode] = KbCheck;

    if keyDown && keyCode(KbName('SPACE'))

        KbReleaseWait;
        break;

    end

end


% Explicit MID-GRAY

Screen('FillRect',win,[127 127 127]);

DrawFormattedText( ...
    win, ...
    'MID-GRAY  [127 127 127]', ...
    'center', ...
    'center', ...
    [255 255 255]);

Screen('Flip',win);

KbReleaseWait;

while true

    [keyDown,~,keyCode] = KbCheck;

    if keyDown && keyCode(KbName('SPACE'))

        KbReleaseWait;
        break;

    end

end


% Explicit WHITE

Screen('FillRect',win,[255 255 255]);

DrawFormattedText( ...
    win, ...
    'WHITE  [255 255 255]', ...
    'center', ...
    'center', ...
    [0 0 0]);

Screen('Flip',win);

KbReleaseWait;

while true

    [keyDown,~,keyCode] = KbCheck;

    if keyDown && keyCode(KbName('SPACE'))

        KbReleaseWait;
        break;

    end

end


%% ---------------------------------------------------------------
% 40.5 FINAL SUMMARY
% ---------------------------------------------------------------

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 40 COMPLETED\n');
fprintf('===============================================================\n');

fprintf('\nThe screen was explicitly tested with:\n');
fprintf('  Black    = [0 0 0]\n');
fprintf('  Mid-gray = [128 128 128]\n');
fprintf('  White    = [255 255 255]\n');

fprintf('\nNo textures were created.\n');
fprintf('No experimental trials were run.\n');
fprintf('No CFS timing was changed.\n');

fprintf('\nSection 40 completed successfully.\n');


%% ================================================================
% SIMPLE PTB RGB TEST
% ================================================================

fprintf('\nRGB TEST\n');
fprintf('Press SPACE to move through the screens.\n');

% BLACK
Screen('FillRect', win, [0 0 0]);
Screen('Flip', win);

KbReleaseWait;
KbWait;

% DARK GRAY
Screen('FillRect', win, [32 32 32]);
Screen('Flip', win);

KbReleaseWait;
KbWait;

% MID GRAY
Screen('FillRect', win, [127 127 127]);
Screen('Flip', win);

KbReleaseWait;
KbWait;

% LIGHT GRAY
Screen('FillRect', win, [200 200 200]);
Screen('Flip', win);

KbReleaseWait;
KbWait;

% WHITE
Screen('FillRect', win, [255 255 255]);
Screen('Flip', win);

KbReleaseWait;
KbWait;

fprintf('\nRGB TEST COMPLETED.\n');


%% SECTION 41 — FIX PTB COLOR RANGE TO 0–255
% ===============================================================
% Purpose:
%   PTB is currently using a 0–1 color range.
%   This section changes the window to a standard 0–255 range.
% ===============================================================

fprintf('\n===============================================================\n');
fprintf('SECTION 41 — FIXING PTB COLOR RANGE\n');
fprintf('===============================================================\n\n');

% Check current range
currentRange = Screen('ColorRange', win);

fprintf('Color range BEFORE change: %g\n', currentRange);

% Set standard 8-bit RGB range
Screen('ColorRange', win, 255);

% Check again
newRange = Screen('ColorRange', win);

fprintf('Color range AFTER change:  %g\n\n', newRange);

% ---------------------------------------------------------------
% Test five actual RGB values
% ---------------------------------------------------------------

testColours = {
    [0   0   0],     'BLACK       [0 0 0]'
    [32  32  32],    'DARK GRAY   [32 32 32]'
    [127 127 127],   'MID GRAY    [127 127 127]'
    [200 200 200],   'LIGHT GRAY  [200 200 200]'
    [255 255 255],   'WHITE       [255 255 255]'
    };

fprintf('Displaying RGB test screens...\n\n');

for i = 1:size(testColours,1)

    rgb = testColours{i,1};
    label = testColours{i,2};

    Screen('FillRect', win, rgb);

    % Put the label in black so it is visible on gray/white
    DrawFormattedText(win, label, ...
        'center', 'center', [0 0 0]);

    Screen('Flip', win);

    fprintf('Displayed: %s\n', label);

    KbWait([], 2);

end

fprintf('\nRGB test completed.\n');
fprintf('===============================================================\n');    


%% SECTION A — INSPECT FACE/MASK DISPLAY CODE

fprintf('\n===============================================================\n');
fprintf('SECTION A — FACE/MASK DISPLAY CODE INSPECTION\n');
fprintf('===============================================================\n\n');

fileText = fileread('cfs_expt.m');
lines = splitlines(fileText);

ranges = [
    3600 3775
    3870 3980
    4085 4180
    4345 4370
    4455 4570
    ];

for r = 1:size(ranges,1)

    fprintf('\n===============================================================\n');
    fprintf('LINES %d–%d\n', ranges(r,1), ranges(r,2));
    fprintf('===============================================================\n');

    for k = ranges(r,1):min(ranges(r,2),numel(lines))
        fprintf('%5d: %s\n', k, lines{k});
    end

end

fprintf('\n===============================================================\n');



% ================================================================
% SECTION 42 — FULL RSVP TRIAL / BLOCK PRESENTATION
% ================================================================
%
% RSVP STRUCTURE:
%   Each trial = ONE COMPLETE arrow sequence
%
%   Arrow duration  = 166.67 ms
%   Gap duration    = 50.00 ms
%
%   Response:
%       participant reports number of target arrows (1–5)
%
%   ITI:
%       1500 ms
%
%   Block:
%       36 trials
%
%   Easy:
%       2, 3, 4, 5 targets
%       9 trials each
%
%   Hard:
%       1, 2, 3, 4 targets
%       9 trials each
%
% ================================================================


fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 42 — FULL RSVP TRIAL / BLOCK PRESENTATION\n');
fprintf('===============================================================\n');


%% ---------------------------------------------------------------
% 42.1 — CHECK REQUIRED VARIABLES
% ---------------------------------------------------------------

requiredVariables = { ...
    'win', ...
    'windowRect', ...
    'backgroundColor', ...
    'arrowBlockSequences', ...
    'easyArrowAssignments', ...
    'hardArrowAssignments'};

for v = 1:length(requiredVariables)

    if ~exist(requiredVariables{v}, 'var')

        error(['SECTION 42 ERROR: Required variable "' ...
               requiredVariables{v} ...
               '" does not exist.']);

    end

end

fprintf('Required experiment variables found.\n');


%% ---------------------------------------------------------------
% 42.2 — FIND ARROW TEXTURE ARRAY
% ---------------------------------------------------------------
%
% The exact variable name created in Section 39 may differ.
% Check the common possibilities.
%

if exist('arrowTextures', 'var')

    arrowTextureArray = arrowTextures;

elseif exist('arrowTextureIDs', 'var')

    arrowTextureArray = arrowTextureIDs;

elseif exist('arrowTexture', 'var')

    arrowTextureArray = arrowTexture;

elseif exist('arrowTex', 'var')

    arrowTextureArray = arrowTex;

else

    error(['SECTION 42 ERROR: Could not find the arrow texture array.' ...
           '\n\nRun:\n' ...
           '    whos *Texture*\n\n' ...
           'and send me the output so we can connect Section 39 to Section 42.']);

end


%% ---------------------------------------------------------------
% 42.3 — VERIFY TEXTURE ARRAY
% ---------------------------------------------------------------

nTextures = numel(arrowTextureArray);

fprintf('Arrow texture entries found: %d\n', nTextures);

if nTextures < 12

    error(['SECTION 42 ERROR: Expected 12 arrow textures, but only ' ...
           '%d were found.'], nTextures);

end


%% ---------------------------------------------------------------
% 42.4 — KEYBOARD SETUP
% ---------------------------------------------------------------

KbName('UnifyKeyNames');

key1 = KbName('1');
key2 = KbName('2');
key3 = KbName('3');
key4 = KbName('4');
key5 = KbName('5');

escapeKey = KbName('ESCAPE');

responseKeys = [key1 key2 key3 key4 key5];

fprintf('Response keys: 1 2 3 4 5\n');


%% ---------------------------------------------------------------
% 42.5 — DISPLAY GEOMETRY
% ---------------------------------------------------------------

[screenXpixels, screenYpixels] = Screen('WindowSize', win);

centerX = screenXpixels / 2;
centerY = screenYpixels / 2;

fprintf('Current PTB window: %d x %d pixels\n', ...
        screenXpixels, screenYpixels);


% Arrow geometry established in Section 38
arrowWidthPx  = 33;
arrowHeightPx = 53;

arrowRect = CenterRectOnPointd( ...
    [0 0 arrowWidthPx arrowHeightPx], ...
    centerX, ...
    centerY);


%% ---------------------------------------------------------------
% 42.6 — TIMING PARAMETERS
% ---------------------------------------------------------------

ifi = Screen('GetFlipInterval', win);

fprintf('Measured IFI: %.6f s\n', ifi);
fprintf('Measured refresh rate: %.2f Hz\n', 1 / ifi);


% ---------------------------------------------------------------
% IMPORTANT TIMING VALUES
% ---------------------------------------------------------------

arrowDuration = 0.16667;       % 166.67 ms
gapDuration   = 0.05000;       % 50 ms
itiDuration   = 1.50000;       % 1500 ms


fprintf('\n');
fprintf('RSVP timing:\n');
fprintf('  Arrow duration : %.2f ms\n', arrowDuration * 1000);
fprintf('  Gap duration   : %.2f ms\n', gapDuration * 1000);
fprintf('  Arrow + gap    : %.2f ms\n', ...
        (arrowDuration + gapDuration) * 1000);
fprintf('  ITI            : %.2f ms\n', itiDuration * 1000);


%% ---------------------------------------------------------------
% 42.7 — FIXATION
% ---------------------------------------------------------------
%
% Temporary value for the full RSVP implementation.
% We can change this later to the exact protocol value.
%

fixationDuration = 0.500;


%% ---------------------------------------------------------------
% 42.8 — TEST MODE
% ---------------------------------------------------------------
%
% Start with ONE complete block.
%
% This is the actual 36-trial block structure.
% Change blockType below between:
%
%       'Easy'
%       'Hard'
%
% We do NOT run both blocks automatically yet.
%

blockType = 'Easy';


fprintf('\n');
fprintf('Block selected for Section 42: %s\n', blockType);


%% ---------------------------------------------------------------
% 42.9 — SELECT BLOCK SEQUENCES AND ASSIGNMENTS
% ---------------------------------------------------------------

if strcmpi(blockType, 'Easy')

    blockSequences   = easyBlockSequences;
    blockAssignments = easyArrowAssignments;

elseif strcmpi(blockType, 'Hard')

    blockSequences   = hardBlockSequences;
    blockAssignments = hardArrowAssignments;

else

    error('SECTION 42 ERROR: blockType must be ''Easy'' or ''Hard''.');

end


nTrials = height(blockSequences);


if nTrials ~= 36

    error(['SECTION 42 ERROR: Expected 36 trials, but block contains ' ...
           '%d trials.'], nTrials);

end


if length(blockAssignments) ~= 36

    error(['SECTION 42 ERROR: Expected 36 arrow assignments, but found ' ...
           '%d.'], length(blockAssignments));

end


fprintf('%s block contains %d trials.\n', ...
        blockType, nTrials);


%% ---------------------------------------------------------------
% 42.10 — PREALLOCATE RESPONSE DATA
% ---------------------------------------------------------------

rsvpResponses = NaN(nTrials,1);
rsvpCorrect   = NaN(nTrials,1);

rsvpTargetCount = NaN(nTrials,1);

rsvpArrowOnset = cell(nTrials,1);
rsvpArrowOffset = cell(nTrials,1);

rsvpResponseRT = NaN(nTrials,1);


%% ---------------------------------------------------------------
% 42.11 — CLEAR SCREEN
% ---------------------------------------------------------------

Screen('FillRect', win, backgroundColor);
Screen('Flip', win);

WaitSecs(0.5);


%% ---------------------------------------------------------------
% 42.12 — RUN 36 RSVP TRIALS
% ---------------------------------------------------------------

for trial = 1:nTrials


    fprintf('\n');
    fprintf('---------------------------------------------------------------\n');
    fprintf('%s BLOCK — TRIAL %d / %d\n', ...
            upper(blockType), trial, nTrials);
    fprintf('---------------------------------------------------------------\n');


    %% -----------------------------------------------------------
    % GET THIS TRIAL'S SEQUENCE
    % ------------------------------------------------------------

    sequenceCode = blockSequences.Sequence{trial};


    fprintf('Sequence: %s\n', sequenceCode);


    % Convert sequence characters into numeric target/non-target code
    %
    % 1 = target
    % o = non-target
    %

    sequenceCode = char(sequenceCode);

    sequenceVector = zeros(1,length(sequenceCode));


    for s = 1:length(sequenceCode)

        if sequenceCode(s) == '1'

            sequenceVector(s) = 1;

        elseif sequenceCode(s) == 'o' || sequenceCode(s) == 'O'

            sequenceVector(s) = 0;

        else

            error(['SECTION 42 ERROR: Invalid sequence character "' ...
                   sequenceCode(s) ...
                   '" in trial ' num2str(trial) '.']);

        end

    end


    %% -----------------------------------------------------------
    % TARGET COUNT
    % ------------------------------------------------------------

    targetCount = sum(sequenceVector);

    rsvpTargetCount(trial) = targetCount;


    fprintf('Target count: %d\n', targetCount);


    %% -----------------------------------------------------------
    % GET ARROW IDENTITY ASSIGNMENT
    % ------------------------------------------------------------

    arrowIDs = blockAssignments{trial};

    arrowIDs = double(arrowIDs(:)');


    nArrowsThisTrial = length(arrowIDs);


    if nArrowsThisTrial ~= length(sequenceVector)

        error(['SECTION 42 ERROR: Number of assigned arrows (' ...
               num2str(nArrowsThisTrial) ...
               ') does not match sequence length (' ...
               num2str(length(sequenceVector)) ...
               ') in trial ' num2str(trial) '.']);

    end


    %% -----------------------------------------------------------
    % VERIFY TARGET MAPPING
    % ------------------------------------------------------------
    %
    % The assignment generated previously should already guarantee
    % the correct target/non-target identities.
    %
    % We only check that the identity IDs are valid here.
    %

    if any(arrowIDs < 1) || any(arrowIDs > 12)

        error(['SECTION 42 ERROR: Invalid arrow identity ID in trial ' ...
               num2str(trial) '.']);

    end


    %% -----------------------------------------------------------
    % FIXATION
    % ------------------------------------------------------------

    Screen('FillRect', win, backgroundColor);


    % Simple fixation cross
    fixLength = 12;
    fixWidth  = 2;


    fixColor = [0 0 0];


    Screen('FillRect', win, ...
        fixColor, ...
        [centerX-fixWidth/2 ...
         centerY-fixLength/2 ...
         centerX+fixWidth/2 ...
         centerY+fixLength/2]);


    Screen('FillRect', win, ...
        fixColor, ...
        [centerX-fixLength/2 ...
         centerY-fixWidth/2 ...
         centerX+fixLength/2 ...
         centerY+fixWidth/2]);


    fixationOnset = Screen('Flip', win);

    WaitSecs(fixationDuration);


    %% -----------------------------------------------------------
    % RSVP SEQUENCE
    % ------------------------------------------------------------
    %
    % Each arrow:
    %
    %       166.67 ms arrow
    %       50.00 ms blank gap
    %
    % The gap is the same mid-gray background.
    %

    arrowOnsets  = NaN(1,nArrowsThisTrial);
    arrowOffsets = NaN(1,nArrowsThisTrial);


    % Start RSVP with a clean background
    Screen('FillRect', win, backgroundColor);

    vbl = Screen('Flip', win);


    for a = 1:nArrowsThisTrial


        currentArrowID = arrowIDs(a);


        %% -------------------------------------------------------
        % DRAW ARROW
        % --------------------------------------------------------

        Screen('FillRect', win, backgroundColor);


        Screen('DrawTexture', ...
            win, ...
            arrowTextureArray(currentArrowID), ...
            [], ...
            arrowRect);


        % Present arrow
        arrowOnsets(a) = Screen('Flip', ...
            win, ...
            vbl + 0.5 * ifi);


        %% -------------------------------------------------------
        % HOLD ARROW FOR 166.67 ms
        % --------------------------------------------------------

        arrowOffsets(a) = arrowOnsets(a) + arrowDuration;


        % Clear to background for the 50-ms gap
        Screen('FillRect', win, backgroundColor);


        gapOnset = Screen('Flip', ...
            win, ...
            arrowOffsets(a) - 0.5 * ifi);


        %% -------------------------------------------------------
        % GAP = 50 ms
        % --------------------------------------------------------

        vbl = gapOnset + gapDuration;


        % Do not draw anything during the gap.
        % The screen remains mid-gray.


        %% -------------------------------------------------------
        % PREPARE NEXT ARROW
        % --------------------------------------------------------

        if a < nArrowsThisTrial

            % Wait until the 50-ms gap has elapsed.
            %
            % The next arrow will be scheduled relative to this time.
            %

            WaitSecs(max(0, vbl - GetSecs()));

        end

    end


    %% -----------------------------------------------------------
    % SAVE TIMING
    % ------------------------------------------------------------

    rsvpArrowOnset{trial}  = arrowOnsets;
    rsvpArrowOffset{trial} = arrowOffsets;


    %% -----------------------------------------------------------
    % RESPONSE SCREEN
    % ------------------------------------------------------------
    %
    % The participant now reports:
    %
    %       How many target arrows were in the sequence?
    %
    % Valid responses:
    %       1 2 3 4 5
    %

    Screen('FillRect', win, backgroundColor);


    responseText = 'How many target arrows?';


    textBounds = Screen('TextBounds', win, responseText);

    textX = centerX - (textBounds(3)-textBounds(1))/2;
    textY = centerY - 50;


    Screen('DrawText', ...
        win, ...
        responseText, ...
        round(textX), ...
        round(textY), ...
        [0 0 0]);


    Screen('DrawText', ...
        win, ...
        '1     2     3     4     5', ...
        round(centerX - 150), ...
        round(centerY + 20), ...
        [0 0 0]);


    responseOnset = Screen('Flip', win);


%% ================================================================
% RESPONSE COLLECTION — 1 TO 5
%
% Participant reports the number of targets seen in the RSVP sequence.
% Valid responses:
%   1, 2, 3, 4, 5
%
% ESC exits the experiment during development.
% ================================================================

fprintf('\nWaiting for participant response (1-5)...\n');

% Make sure no previous keyboard press is carried over.
KbReleaseWait;

response = NaN;
responseKey = '';
responseRT = NaN;

responseStartTime = GetSecs;

while isnan(response)

    [keyDown, keyTime, keyCode] = KbCheck;

    if keyDown

        % ------------------------------------------------------------
        % ESCAPE
        % ------------------------------------------------------------
        if keyCode(KbName('ESCAPE'))

            fprintf('\nESC pressed — ending experiment.\n');

            Screen('CloseAll');
            ShowCursor;

            return;
        end

        % ------------------------------------------------------------
        % NUMBER KEYS
        % ------------------------------------------------------------

        if keyCode(KbName('1!')) || keyCode(KbName('1'))

            response = 1;
            responseKey = '1';

        elseif keyCode(KbName('2@')) || keyCode(KbName('2'))

            response = 2;
            responseKey = '2';

        elseif keyCode(KbName('3#')) || keyCode(KbName('3'))

            response = 3;
            responseKey = '3';

        elseif keyCode(KbName('4$')) || keyCode(KbName('4'))

            response = 4;
            responseKey = '4';

        elseif keyCode(KbName('5%')) || keyCode(KbName('5'))

            response = 5;
            responseKey = '5';

        end

        % ------------------------------------------------------------
        % PREVENT THE SAME KEY PRESS FROM BEING DETECTED AGAIN
        % ------------------------------------------------------------

        if ~isnan(response)

            responseRT = keyTime - responseStartTime;

            KbReleaseWait;

        end
    end

    WaitSecs(0.001);
end

fprintf('Response received: %d target(s)\n', response);
fprintf('Response RT: %.4f s\n', responseRT);
    %% -----------------------------------------------------------
    % STORE RESPONSE
    % ------------------------------------------------------------

    rsvpResponses(trial) = response;
    rsvpResponseRT(trial) = responseRT;


    rsvpCorrect(trial) = ...
        response == targetCount;


    fprintf('Response: %d\n', response);
    fprintf('Correct target count: %d\n', targetCount);
    fprintf('Accuracy: %d\n', rsvpCorrect(trial));
    fprintf('RT: %.3f s\n', responseRT);


    %% -----------------------------------------------------------
    % ITI = 1500 ms
    % ------------------------------------------------------------

    Screen('FillRect', win, backgroundColor);

    itiOnset = Screen('Flip', win);

    WaitSecs(itiDuration);


end


%% ---------------------------------------------------------------
% 42.13 — BLOCK SUMMARY
% ---------------------------------------------------------------

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 42 — BLOCK COMPLETE\n');
fprintf('===============================================================\n');

nCorrect = sum(rsvpCorrect);

accuracy = mean(rsvpCorrect) * 100;

meanRT = mean(rsvpResponseRT);


fprintf('Block type       : %s\n', blockType);
fprintf('Trials completed : %d\n', nTrials);
fprintf('Correct          : %d / %d\n', nCorrect, nTrials);
fprintf('Accuracy         : %.2f %%\n', accuracy);
fprintf('Mean RT          : %.3f s\n', meanRT);


%% ---------------------------------------------------------------
% 42.14 — TARGET COUNT SUMMARY
% ---------------------------------------------------------------

fprintf('\nTarget-count performance:\n');

uniqueTargetCounts = unique(rsvpTargetCount);


for tc = 1:length(uniqueTargetCounts)

    thisCount = uniqueTargetCounts(tc);

    idx = rsvpTargetCount == thisCount;

    thisAccuracy = mean(rsvpCorrect(idx)) * 100;

    thisRT = mean(rsvpResponseRT(idx));

    fprintf('  %d targets: %d trials | Accuracy %.2f %% | Mean RT %.3f s\n', ...
        thisCount, ...
        sum(idx), ...
        thisAccuracy, ...
        thisRT);

end


%% ---------------------------------------------------------------
% 42.15 — RESTORE BACKGROUND
% ---------------------------------------------------------------

Screen('FillRect', win, backgroundColor);
Screen('Flip', win);


fprintf('\n');
fprintf('Section 42 completed successfully.\n');
fprintf('No textures were closed.\n');
fprintf('PTB window remains open for the next section.\n');
fprintf('===============================================================\n');



% ================================================================
% SECTION 43 — 24-BLOCK EXPERIMENTAL CONDITION MATRIX
% ================================================================
%
% PURPOSE:
%   Create the complete 24-block experimental structure.
%
% FACTORIAL DESIGN:
%
%   Load:
%       Easy
%       Hard
%
%   Awareness:
%       Aware
%       Unaware
%
%   Emotion:
%       Happy
%       Angry
%       Neutral
%
%   Each Load x Awareness x Emotion combination occurs TWICE.
%
%   Therefore:
%
%       2 Loads
%       x 2 Awareness levels
%       x 3 Emotions
%       x 2 repetitions
%       = 24 blocks
%
% Each block will later contain:
%
%       36 RSVP trials
%       + one spontaneous-thought probe
%
% IMPORTANT:
%   This section ONLY creates and checks the block structure.
%   It does NOT present the experiment yet.
%
% ================================================================


fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 43 — 24-BLOCK EXPERIMENTAL CONDITION MATRIX\n');
fprintf('===============================================================\n');


%% ---------------------------------------------------------------
% 43.1 — DEFINE EXPERIMENTAL FACTORS
% ---------------------------------------------------------------

loadLevels = { ...
    'Easy'; ...
    'Hard'};


awarenessLevels = { ...
    'Aware'; ...
    'Unaware'};


emotionLevels = { ...
    'Happy'; ...
    'Angry'; ...
    'Neutral'};


nRepetitions = 2;


fprintf('\nExperimental factors:\n');

fprintf('  Load      : Easy, Hard\n');
fprintf('  Awareness : Aware, Unaware\n');
fprintf('  Emotion   : Happy, Angry, Neutral\n');
fprintf('  Repetitions per combination : %d\n', nRepetitions);


%% ---------------------------------------------------------------
% 43.2 — CALCULATE NUMBER OF BLOCKS
% ---------------------------------------------------------------

nLoads     = length(loadLevels);
nAwareness = length(awarenessLevels);
nEmotions  = length(emotionLevels);

nConditionCombinations = ...
    nLoads * nAwareness * nEmotions;

nTotalBlocks = ...
    nConditionCombinations * nRepetitions;


fprintf('\n');
fprintf('Number of Load levels       : %d\n', nLoads);
fprintf('Number of Awareness levels : %d\n', nAwareness);
fprintf('Number of Emotion levels    : %d\n', nEmotions);
fprintf('Condition combinations      : %d\n', ...
        nConditionCombinations);
fprintf('Total experimental blocks   : %d\n', ...
        nTotalBlocks);


if nTotalBlocks ~= 24

    error(['SECTION 43 ERROR: Expected 24 total blocks, ' ...
           'but calculated %d.'], nTotalBlocks);

end


%% ---------------------------------------------------------------
% 43.3 — CREATE COMPLETE CONDITION LIST
% ---------------------------------------------------------------
%
% We create each unique Load x Awareness x Emotion
% combination twice.
%
% ---------------------------------------------------------------

blockLoad      = cell(nTotalBlocks,1);
blockAwareness = cell(nTotalBlocks,1);
blockEmotion   = cell(nTotalBlocks,1);
blockRep       = NaN(nTotalBlocks,1);


blockCounter = 0;


for L = 1:nLoads

    for A = 1:nAwareness

        for E = 1:nEmotions

            for R = 1:nRepetitions

                blockCounter = blockCounter + 1;

                blockLoad{blockCounter} = ...
                    loadLevels{L};

                blockAwareness{blockCounter} = ...
                    awarenessLevels{A};

                blockEmotion{blockCounter} = ...
                    emotionLevels{E};

                blockRep(blockCounter) = R;

            end

        end

    end

end


%% ---------------------------------------------------------------
% 43.4 — RANDOMIZE BLOCK ORDER
% ---------------------------------------------------------------
%
% The complete set of 24 blocks is shuffled.
%
% The experimental conditions themselves are NOT changed.
% Only their order is randomized.
%
% ---------------------------------------------------------------

randomOrder = randperm(nTotalBlocks);


blockLoad      = blockLoad(randomOrder);
blockAwareness = blockAwareness(randomOrder);
blockEmotion   = blockEmotion(randomOrder);
blockRep       = blockRep(randomOrder);


%% ---------------------------------------------------------------
% 43.5 — CREATE BLOCK TABLE
% ---------------------------------------------------------------

experimentalBlocks = table( ...
    (1:nTotalBlocks)', ...
    blockLoad, ...
    blockAwareness, ...
    blockEmotion, ...
    blockRep, ...
    'VariableNames', { ...
        'Block', ...
        'Load', ...
        'Awareness', ...
        'Emotion', ...
        'Repetition'});


%% ---------------------------------------------------------------
% 43.6 — ADD PLACEHOLDER FOR RSVP SEQUENCES
% ---------------------------------------------------------------
%
% These will point to the already-generated 36-trial Easy
% or Hard RSVP blocks.
%
% We are NOT generating new RSVP sequences here.
%
% ---------------------------------------------------------------

experimentalBlocks.RSVPBlock = cell(nTotalBlocks,1);


for b = 1:nTotalBlocks

    if strcmpi(experimentalBlocks.Load{b}, 'Easy')

        experimentalBlocks.RSVPBlock{b} = ...
            'Easy';

    elseif strcmpi(experimentalBlocks.Load{b}, 'Hard')

        experimentalBlocks.RSVPBlock{b} = ...
            'Hard';

    else

        error(['SECTION 43 ERROR: Invalid load at block ' ...
               num2str(b) '.']);

    end

end


%% ---------------------------------------------------------------
% 43.7 — VERIFY TOTAL NUMBER OF BLOCKS
% ---------------------------------------------------------------

if height(experimentalBlocks) ~= 24

    error(['SECTION 43 ERROR: Experimental block table should ' ...
           'contain 24 blocks, but contains %d.'], ...
           height(experimentalBlocks));

end


%% ---------------------------------------------------------------
% 43.8 — VERIFY EASY / HARD BALANCE
% ---------------------------------------------------------------

nEasyBlocks = sum( ...
    strcmpi(experimentalBlocks.Load,'Easy'));

nHardBlocks = sum( ...
    strcmpi(experimentalBlocks.Load,'Hard'));


fprintf('\n');
fprintf('Load balance:\n');
fprintf('  Easy blocks : %d\n', nEasyBlocks);
fprintf('  Hard blocks : %d\n', nHardBlocks);


if nEasyBlocks ~= 12 || nHardBlocks ~= 12

    error(['SECTION 43 ERROR: Expected 12 Easy and 12 Hard blocks. ' ...
           'Found %d Easy and %d Hard.'], ...
           nEasyBlocks, nHardBlocks);

end


%% ---------------------------------------------------------------
% 43.9 — VERIFY AWARE / UNAWARE BALANCE
% ---------------------------------------------------------------

nAwareBlocks = sum( ...
    strcmpi(experimentalBlocks.Awareness,'Aware'));

nUnawareBlocks = sum( ...
    strcmpi(experimentalBlocks.Awareness,'Unaware'));


fprintf('\n');
fprintf('Awareness balance:\n');
fprintf('  Aware blocks   : %d\n', nAwareBlocks);
fprintf('  Unaware blocks : %d\n', nUnawareBlocks);


if nAwareBlocks ~= 12 || nUnawareBlocks ~= 12

    error(['SECTION 43 ERROR: Expected 12 Aware and 12 Unaware ' ...
           'blocks. Found %d Aware and %d Unaware.'], ...
           nAwareBlocks, nUnawareBlocks);

end


%% ---------------------------------------------------------------
% 43.10 — VERIFY EMOTION BALANCE
% ---------------------------------------------------------------

nHappyBlocks = sum( ...
    strcmpi(experimentalBlocks.Emotion,'Happy'));

nAngryBlocks = sum( ...
    strcmpi(experimentalBlocks.Emotion,'Angry'));

nNeutralBlocks = sum( ...
    strcmpi(experimentalBlocks.Emotion,'Neutral'));


fprintf('\n');
fprintf('Emotion balance:\n');
fprintf('  Happy blocks   : %d\n', nHappyBlocks);
fprintf('  Angry blocks   : %d\n', nAngryBlocks);
fprintf('  Neutral blocks : %d\n', nNeutralBlocks);


if nHappyBlocks ~= 8 || ...
   nAngryBlocks ~= 8 || ...
   nNeutralBlocks ~= 8

    error(['SECTION 43 ERROR: Expected 8 blocks for each emotion. ' ...
           'Found Happy=%d, Angry=%d, Neutral=%d.'], ...
           nHappyBlocks, ...
           nAngryBlocks, ...
           nNeutralBlocks);

end


%% ---------------------------------------------------------------
% 43.11 — VERIFY EACH CONDITION OCCURS TWICE
% ---------------------------------------------------------------

fprintf('\n');
fprintf('Condition-combination check:\n');


conditionCount = 0;


for L = 1:nLoads

    for A = 1:nAwareness

        for E = 1:nEmotions


            thisLoad = loadLevels{L};
            thisAwareness = awarenessLevels{A};
            thisEmotion = emotionLevels{E};


            match = ...
                strcmpi(experimentalBlocks.Load, thisLoad) & ...
                strcmpi(experimentalBlocks.Awareness, thisAwareness) & ...
                strcmpi(experimentalBlocks.Emotion, thisEmotion);


            nMatches = sum(match);


            fprintf('  %-5s | %-7s | %-7s : %d blocks\n', ...
                    thisLoad, ...
                    thisAwareness, ...
                    thisEmotion, ...
                    nMatches);


            if nMatches ~= 2

                error(['SECTION 43 ERROR: Condition ' ...
                       thisLoad ' x ' ...
                       thisAwareness ' x ' ...
                       thisEmotion ...
                       ' occurs %d times instead of 2.'], ...
                       nMatches);

            end


            conditionCount = conditionCount + 1;

        end

    end

end


if conditionCount ~= 12

    error(['SECTION 43 ERROR: Expected 12 total experimental ' ...
           'condition combinations, but found %d.'], ...
           conditionCount);

end


%% ---------------------------------------------------------------
% 43.12 — DISPLAY FINAL BLOCK ORDER
% ---------------------------------------------------------------

fprintf('\n');
fprintf('===============================================================\n');
fprintf('FINAL RANDOMIZED BLOCK ORDER\n');
fprintf('===============================================================\n');

fprintf('\n');
fprintf('Block   Load    Awareness   Emotion   Rep\n');
fprintf('---------------------------------------------------------------\n');


for b = 1:nTotalBlocks

    fprintf('%2d      %-6s  %-10s  %-8s  %d\n', ...
            experimentalBlocks.Block(b), ...
            experimentalBlocks.Load{b}, ...
            experimentalBlocks.Awareness{b}, ...
            experimentalBlocks.Emotion{b}, ...
            experimentalBlocks.Repetition(b));

end


%% ---------------------------------------------------------------
% 43.13 — FINAL SUMMARY
% ---------------------------------------------------------------

fprintf('\n');
fprintf('===============================================================\n');
fprintf('SECTION 43 COMPLETE\n');
fprintf('===============================================================\n');

fprintf('\n');
fprintf('Total blocks       : %d\n', height(experimentalBlocks));
fprintf('Easy blocks        : %d\n', nEasyBlocks);
fprintf('Hard blocks        : %d\n', nHardBlocks);
fprintf('Aware blocks       : %d\n', nAwareBlocks);
fprintf('Unaware blocks     : %d\n', nUnawareBlocks);
fprintf('Happy blocks       : %d\n', nHappyBlocks);
fprintf('Angry blocks       : %d\n', nAngryBlocks);
fprintf('Neutral blocks     : %d\n', nNeutralBlocks);

fprintf('\n');
fprintf('Each Load x Awareness x Emotion combination occurs twice.\n');

fprintf('\n');
fprintf('The 24-block experimental structure is ready.\n');

fprintf('===============================================================\n');
%% ================================================================
% HELPER FUNCTION:
% RECURSIVE HARD ARROW ASSIGNMENT
% ================================================================

function [success,assignedIndices] = ...
    assignHardArrowRecursive( ...
        sequenceCode, ...
        position, ...
        assignedIndices, ...
        hardTargetIndices, ...
        hardNonTargetIndices, ...
        arrowIdentity)

    sequenceLength = length(sequenceCode);

    % -------------------------------------------------------------
    % BASE CASE
    % -------------------------------------------------------------

    if position > sequenceLength

        success = true;
        return;

    end


    % -------------------------------------------------------------
    % DETERMINE TARGET / NON-TARGET
    % -------------------------------------------------------------

    isTarget = sequenceCode(position) == '1';

    if isTarget

        candidateIndices = hardTargetIndices;

    else

        candidateIndices = hardNonTargetIndices;

    end


    % -------------------------------------------------------------
    % RANDOMIZE CANDIDATE ORDER
    %
    % This preserves randomization while allowing backtracking.
    % -------------------------------------------------------------

    candidateIndices = ...
        candidateIndices(randperm(numel(candidateIndices)));


    % -------------------------------------------------------------
    % TEST EACH CANDIDATE
    % -------------------------------------------------------------

    for c = 1:numel(candidateIndices)

        candidate = candidateIndices(c);

        candidateValid = true;


        % ---------------------------------------------------------
        % CONSTRAINT 1:
        % NO CONSECUTIVE COLOURS
        % ---------------------------------------------------------

        if position > 1

            previousIdentity = ...
                assignedIndices(position-1);

            previousColour = ...
                arrowIdentity(previousIdentity).Colour;

            candidateColour = ...
                arrowIdentity(candidate).Colour;

            if strcmp(candidateColour,previousColour)

                candidateValid = false;

            end

        end


        % ---------------------------------------------------------
        % CONSTRAINT 2:
        % MAXIMUM 3 CONSECUTIVE IDENTICAL ORIENTATIONS
        % ---------------------------------------------------------

        if candidateValid && position >= 4

            orientation1 = ...
                arrowIdentity( ...
                    assignedIndices(position-1)).Orientation;

            orientation2 = ...
                arrowIdentity( ...
                    assignedIndices(position-2)).Orientation;

            orientation3 = ...
                arrowIdentity( ...
                    assignedIndices(position-3)).Orientation;

            candidateOrientation = ...
                arrowIdentity(candidate).Orientation;


            if strcmp(orientation1,orientation2) && ...
               strcmp(orientation2,orientation3) && ...
               strcmp(candidateOrientation,orientation1)

                candidateValid = false;

            end

        end


        % ---------------------------------------------------------
        % IF THIS CANDIDATE IS VALID, TRY IT
        % ---------------------------------------------------------

        if candidateValid

            assignedIndices(position) = candidate;


            % -----------------------------------------------------
            % RECURSIVELY ASSIGN NEXT POSITION
            % -----------------------------------------------------

            [success,assignedIndices] = ...
                assignHardArrowRecursive( ...
                    sequenceCode, ...
                    position + 1, ...
                    assignedIndices, ...
                    hardTargetIndices, ...
                    hardNonTargetIndices, ...
                    arrowIdentity);


            % -----------------------------------------------------
            % SUCCESS
            % -----------------------------------------------------

            if success

                return;

            end


            % -----------------------------------------------------
            % FAILURE:
            % UNDO THIS CHOICE AND TRY ANOTHER CANDIDATE
            % -----------------------------------------------------

            assignedIndices(position) = 0;

        end

    end


    % -------------------------------------------------------------
    % NO CANDIDATE WORKED
    % -------------------------------------------------------------

    success = false;

end




