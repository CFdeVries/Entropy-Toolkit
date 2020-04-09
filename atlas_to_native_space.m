% List of open inputs

function output_fullpath = atlas_to_native_space(entropy_files, iy_files)

nrun = size(entropy_files.name, 1);
inputs = cell(4, nrun);

jobfile = {'atlas_to_native_space_job.m'};
jobs = repmat(jobfile, 1, nrun);


atlas = 'ROI_MNI_V4.nii';

for crun = 1:nrun
    inputs{1, crun} = iy_files(1, crun);
    inputs{2, crun} = {[entropy_files.path entropy_files.name(crun,:)]};
    inputs{3, crun} = {atlas};
    inputs{4, crun} = [entropy_files.name(crun,1:end-4), '_'];
   % [pwd, entropy_files.name(crun,1:end-4), '_', entropy_files.name(crun,:)]
    
    output_fullpath{crun} = fullfile(pwd, [entropy_files.name(crun,1:end-4), '_', atlas]);
end

spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});

end