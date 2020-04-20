function calc_avg_entropy(entropy_maps, atlases, MNI_atlas)

if strcmp(MNI_atlas, 'AAL')
	load('ROI_MNI_V4_List.mat', 'ROI')
elseif strcmp(MNI_atlas, 'AAL2')
	load('ROI_MNI_V5_List.mat', 'ROI')
elseif strcmp(MNI_atlas, 'AAL3')
	load('ROI_MNI_V6_List.mat', 'ROI')
end

Nfiles = size(entropy_maps, 2);
Nregions = length(ROI);

ROI_averages = zeros(Nfiles, Nregions);

for i = 1:Nfiles

    V_atlas = spm_vol(char(atlases(i))); % pre-processed image to be analysed
    Y_atlas = spm_read_vols(V_atlas);
    
    V_entropy = spm_vol(char(entropy_maps(i)));
    Y_entropy = spm_read_vols(V_entropy);
    
    clear V_atlas V_entropy

%        for s = 1:5
		
%            dir_entropy = [path, 'scale ', int2str(s), '\']; 

        %	files = dir([dir_entropy, 'ST*.mat']);
		
	%		file_entropy = [dir_entropy file.name];
	%		load(file_entropy)

    %% calculates average signal for each region

    for m = 1:Nregions
         entropy2 = Y_entropy;
         entropy2(Y_atlas ~= ROI(m).ID) = [];
         entropy2(isnan(entropy2)) = [];
         entropy2(entropy2 == 0) = [];
         ROI_averages(i, m) = mean(entropy2);
    end

end

ROI_averages_cell = num2cell(ROI_averages);
ROI_averages_cell = [{'file', ROI(:).Nom_L}; entropy_maps' ROI_averages_cell];

outputfile = ['regionwise_entropy_', MNI_atlas, '.xlsx'];

if exist(outputfile, 'file')
	error('A region-wise output file already exists: %s. Delete or rename it to run this function.', outputfile);
else
	xlswrite(outputfile, ROI_averages_cell);
end
        
end