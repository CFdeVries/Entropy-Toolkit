function output_fullpath = generate_iy_files(seg8_files)

% Code that generates the transform from MNI space to native space.
% This avoids having to rerun the segmentation if the '*_seg8.mat' files are available.

% However, if the files have been moved, MATLAB will show an error message.
% This is because the code will look for the original T1-weighted nii-file, and its
% path is hard-coded into the '*_seg8.mat' files. The original path can be accessed by
% the command 'res.image.fname', after running 'res = load(file_path);'

Nfiles = size(seg8_files.name, 1);

for i = 1:Nfiles
    
    file_path = [seg8_files.path, seg8_files.name(i,:)];
    res = load(file_path);

    [T1W_path T1W_name T1W_ext] = fileparts(res.image.fname);

    iy_name = ['iy_', T1W_name, T1W_ext];
    iy_fullpath = fullfile(T1W_path, iy_name);
    
    if exist(iy_fullpath, 'file') ~= 2   % if the inverse transfrom does not exist yet
        
        tc = false(max(res.lkp),4);
        bf = [false false];	% [field, corrected]
        df = [true false];	% [inverse forward]

        spm_preproc_write8(res,tc,bf,df);	% writes the inverse iy_*.nii file
    end
    
    output_fullpath{i} = fullfile(T1W_path, iy_name);

end

end