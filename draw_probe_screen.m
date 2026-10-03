function draw_probe_screen(win, cfg, frameTex, winRect, frameDestRects, ppd, question_lines)
% DRAW_PROBE_SCREEN  Draw fusion frames (both halves) plus a block of text
% kept INSIDE the fusion frame. If cfg.text_only_side is set ('left' or
% 'right'), the text appears only in that frame; otherwise in both.
% Does NOT call Screen('Flip') -- caller flips after this draws.

    Screen('FillRect', win, cfg.background_rgb);
    Screen('DrawTexture', win, frameTex, [], frameDestRects.left, 0, 0);
    Screen('DrawTexture', win, frameTex, [], frameDestRects.right, 0, 0);

    Screen('TextSize', win, max(9, round(0.25 * ppd)));

    draw_left = true;  draw_right = true;
    if isfield(cfg, 'text_only_side')
        draw_left  = strcmpi(cfg.text_only_side, 'left');
        draw_right = strcmpi(cfg.text_only_side, 'right');
    end

    % wrap width comes from the actual frame width, minus a margin on each side
    margin_px   = 0.3 * ppd;   % increase this if text still touches the edge
    frame_w_px  = frameDestRects.left(3) - frameDestRects.left(1);
    usable_w_px = frame_w_px - 2 * margin_px;

    sample_str = 'The quick brown fox jumps over the lazy dog 0123456789';
    sample_bounds = Screen('TextBounds', win, sample_str);
    avg_char_width_px = sample_bounds(3) / numel(sample_str);
    wrapat_chars = max(10, floor(0.98 * usable_w_px / avg_char_width_px));

    text = strjoin(question_lines, '\n');

    if draw_left
        draw_text_in_frame(win, text, frameDestRects.left, margin_px, wrapat_chars);
    end
    if draw_right
        draw_text_in_frame(win, text, frameDestRects.right, margin_px, wrapat_chars);
    end
end


function draw_text_in_frame(win, text, frameRect, margin_px, wrapat_chars)
    x = frameRect(1) + margin_px;
    [~, ~, tb] = DrawFormattedText(win, text, x, 'center', [255 255 255], wrapat_chars, [], [], 1.0);
    if tb(1) < frameRect(1) || tb(3) > frameRect(3) || tb(2) < frameRect(2) || tb(4) > frameRect(4)
        msg = sprintf(['Text extends outside the fusion frame (text box [%d %d %d %d], ' ...
            'frame [%d %d %d %d]). Shorten the text or lower the font size.'], ...
            round(tb), round(frameRect));
        warning('draw_probe_screen:textOutsideFrame', '%s', msg);
    end
end