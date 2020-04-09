function calc_avg_entropy(entropy_maps, atlases)

load('ROI_MNI_V4_List.mat')

Nfiles = size(entropy_maps, 2);

ROI_averages = zeros(Nfiles, 116);

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

    for m = 1:116
         entropy2 = Y_entropy;
         entropy2(Y_atlas ~= ROI(m).ID) = [];
         entropy2(isnan(entropy2)) = [];
         entropy2(entropy2 == 0) = [];
         ROI_averages(i, m) = mean(entropy2);
    end

end

ROI_averages_cell = num2cell(ROI_averages);
ROI_averages_cell = [{'file', ROI(:).Nom_L}; entropy_maps' ROI_averages_cell];
xlswrite('regionwise_entropy.xls', ROI_averages_cell);
        
end