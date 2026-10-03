function [label, rt_s] = run_probe2(win, cfg, winRect, frameTex, frameDestRects, ppd)
% RUN_PROBE2  "Which stimulus from the task was your thought related to?"
% Only shown if Probe 1's answer was SDT. Fixed display order (not
% counterbalanced -- only probe1's order was specified as needing that).
%
%   [label, rt_s] = run_probe2(win, cfg, winRect, frameTex, frameDestRects)
%
% OUTPUT
%   label - 'arrows', 'masks', 'faces', or 'other'
%   rt_s  - response time in seconds

    lines = {'Which stimulus from the task was your thought related to?', ''};
    for i = 1:numel(cfg.probe2_options)
        lines{end+1} = sprintf('%d - %s', i, cfg.probe2_display_text(cfg.probe2_options{i})); %#ok<AGROW>
    end

    draw_probe_screen(win, cfg, frameTex, winRect, frameDestRects, ppd, lines);
    Screen('Flip', win);

    [key, rt_s] = collect_keypress_response(cfg.keys.probe2_keys, win);
    idx = str2double(key);
    label = cfg.probe2_options{idx};
end
