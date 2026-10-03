function draw_face_texture(win, cfg, ppd, frame_center, tex, side)
% DRAW_FACE_TEXTURE  Draw one face texture offset left/right of frame_center,
% at the contrast given by cfg.face_contrast (1 = the face image's native
% contrast, 0.2 = 20% of it). If cfg.face_contrast is missing, 1 is used.
%
% Contrast is reduced by alpha-blending the face toward whatever is already
% on screen (the mid-gray background). Because the faces were RMS-contrast
% and mean-luminance matched, with a background that equals the experiment
% background, blending by alpha scales the face's contrast by alpha and
% leaves its mean luminance unchanged.
%
%   draw_face_texture(win, cfg, ppd, frame_center, tex, side)

    ecc_px = cfg.face_eccentricity_deg * ppd;
    w_px   = cfg.face_width_deg  * ppd;
    h_px   = cfg.face_height_deg * ppd;

    switch lower(side)
        case 'left'
            x = frame_center(1) - ecc_px;
        case 'right'
            x = frame_center(1) + ecc_px;
        otherwise
            error('draw_face_texture:badSide', ...
                  'side must be ''left'' or ''right'', got: %s', string(side));
    end
    y = frame_center(2);

    dstRect = CenterRectOnPointd([0 0 w_px h_px], x, y);

    contrast = 1;
    if isfield(cfg, 'face_contrast') && ~isempty(cfg.face_contrast)
        contrast = cfg.face_contrast;
    end

    if contrast >= 1
        Screen('DrawTexture', win, tex, [], dstRect);
    else
        [srcOld, dstOld] = Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        Screen('DrawTexture', win, tex, [], dstRect, 0, [], contrast);
        Screen('BlendFunction', win, srcOld, dstOld);
    end
end
