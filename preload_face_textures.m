function faceTextures = preload_face_textures(win, cfg)
% PRELOAD_FACE_TEXTURES  Load all face images (12 identities x 3 emotions
% = 36 images) into PTB textures once at session start.
%
%   faceTextures = preload_face_textures(win, cfg)
%
% INPUTS
%   win - PsychToolbox window pointer
%   cfg - struct from config_experiment()
%
% OUTPUT
%   faceTextures - containers.Map, keyed by face_texture_key(id, gender,
%                  emotion), values are PTB texture pointers
%
% NOTE: reads real files via get_face_filename() -- untested against your
% actual folder/files. Will error with the exact missing path if a file
% isn't found, rather than silently skipping it.

    faceTextures = containers.Map();

    fprintf('Loading face textures from %s ...\n', cfg.face_folder_root);
    n_ids = numel(cfg.face_identities);
    n_emotions = numel(cfg.emotion_levels);
    total = n_ids * n_emotions;
    count = 0;

    for idx = 1:n_ids
        id = cfg.face_identities(idx).id;
        gender = cfg.face_identities(idx).gender;
        for e = 1:n_emotions
            emotion = cfg.emotion_levels{e};
            [fpath, ~] = get_face_filename(cfg, id, gender, emotion);
            if ~isfile(fpath)
                error('preload_face_textures:fileNotFound', ...
                    'Expected face file not found: %s', fpath);
            end
            img = imread(fpath);
            tex = Screen('MakeTexture', win, img);
            key = face_texture_key(id, gender, emotion);
            faceTextures(key) = tex;
            count = count + 1;
        end
    end
    fprintf('Loaded %d/%d face textures.\n', count, total);
end
