function show_instructions(win, cfg, frameTex, winRect, frameDestRects, ppd)
% SHOW_INSTRUCTIONS  Multi-page instruction screens for the whole task.
% Text is drawn in BOTH eyes' frames (via draw_probe_screen) so it fuses.
%
%   show_instructions(win, cfg, frameTex, winRect, frameDestRects, ppd)
%
% NAVIGATION: any key = next page, Backspace = previous page,
%             Escape = abort (throws an error, like the rest of the code).
%
% KEY LABELS are read from cfg (face-report keys, pause key, count keys),
% so if you change a key in config_experiment.m the instructions update
% automatically.
%
% To change wording, edit the strings in the "pages" section below.
% Each page is a cell array of lines; '' gives a blank line, and long
% lines wrap automatically.
%
% Call this AFTER fusion calibration (it needs frameDestRects).

    KbName('UnifyKeyNames');
    escKey  = KbName('ESCAPE');
    backKey = KbName('BackSpace');

    pauseLbl = key_label(cfg.keys.pause_key);
    countLo  = cfg.keys.target_count_keys{1};
    countHi  = cfg.keys.target_count_keys{end};

    %% ---- pages ----
    pages = {};

    pages{end+1} = { ...
        'WELCOME', '', ...
        'Thank you for taking part. In this experiment you will do a counting task while looking at a stream of arrows.', ...
        '', ...
        'The next few screens explain what to do.'};

    pages{end+1} = { ...
        'THE DISPLAY', '', ...
        'You will see two identical square frames, one for each eye. They should merge into a single frame.', ...
        '', ...
        'Keep both eyes open and keep looking at the center of the frame for the whole experiment. Try not to move your eyes or head.', ...
        '', ...
        'Before every block you will adjust the frames until they merge (arrow keys, then Return).'};

    pages{end+1} = { ...
        'THE ARROW STREAM', '', ...
        'On each trial, a rapid stream of arrows appears at the center of the frame, one after another.', ...
        '', ...
        'The arrows differ in color and in direction (pointing up or pointing down).'};

    pages{end+1} = { ...
        'YOUR MAIN TASK: COUNT', '', ...
        'Your main task is to count how many TARGET arrows appear in each stream.', ...
        '', ...
        'The targets change from block to block. Before each block you will be told which arrows to count, for example:', ...
        '   - only the RED arrows, or', ...
        '   - the YELLOW UPRIGHT arrows and the GREEN DOWNWARD arrows.', ...
        '', ...
        sprintf('At the end of each stream, the question "How many targets?" appears. Press the number key (%s to %s) for the number you counted.', countLo, countHi)};

    pages{end+1} = { ...
        'THOUGHT QUESTIONS', '', ...
        'Now and then, during a block, a few short questions will appear about what was going through your mind just before.', ...
        '', ...
        'Please answer honestly and quickly. There are no right or wrong answers.'};

    pages{end+1} = { ...
        'BREAKS', '', ...
        sprintf('You can pause at any time during the blank pause between trials by pressing %s. The experiment waits until you press a key to continue.', pauseLbl), ...
        '', ...
        'There is also a break between blocks.'};

    pages{end+1} = { ...
        'PRACTICE', '', ...
        'You will start with a short practice session.', ...
        '', ...
        'If anything is unclear, please ask the experimenter now.', ...
        '', ...
        'Press any key to begin.'};

    %% ---- page loop ----
    n_pages = numel(pages);
    i = 1;
    while i <= n_pages
        lines = pages{i};
        if i < n_pages
            if i > 1
                lines = [lines, {'', '', 'Press any key to continue.   (Backspace = go back)'}];
            else
                lines = [lines, {'', '', 'Press any key to continue.'}];
            end
        end

        draw_probe_screen(win, cfg, frameTex, winRect, frameDestRects, ppd, lines);
        Screen('Flip', win);

        nav = wait_for_nav_key(escKey, backKey);
        if strcmp(nav, 'back')
            i = max(1, i - 1);
        else
            i = i + 1;
        end
    end
end


function nav = wait_for_nav_key(escKey, backKey)
% Wait for a key press. Returns 'back' for Backspace, 'next' for any other
% key. Escape aborts. Waits for any held key to be released first, so a
% single press cannot skip two pages.
    while KbCheck; end
    while true
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(escKey)
                error('show_instructions:userAbort', 'User pressed Escape -- aborting.');
            end
            if keyCode(backKey)
                nav = 'back';
            else
                nav = 'next';
            end
            while KbCheck; end
            return;
        end
        WaitSecs(0.001);
    end
end


function s = key_label(k)
% Turn a KbName string into something readable: 'z' -> 'Z',
% 'LeftArrow' -> 'Left Arrow'.
    if isnumeric(k)
        k = KbName(k);
    end
    if iscell(k)
        k = k{1};
    end
    if numel(k) == 1
        s = upper(k);
    else
        s = regexprep(k, '([a-z])([A-Z])', '$1 $2');
    end
end
