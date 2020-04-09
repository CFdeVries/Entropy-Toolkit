function check_reg(entropy_maps, atlases)

Nfiles = size(entropy_maps, 2);

spm_check_registration(char(entropy_maps(1)));

for i = 1:Nfiles
    
    atlas = char(atlases(i));
    entropy = char(entropy_maps(i));
    
    spm_orthviews('Delete', 1)
    H = spm_orthviews('Image', entropy);

    alpha = 0.2;
    spm_orthviews('Addtruecolourimage',H, [atlas, ',1'],jet,alpha);
    spm_orthviews('Redraw');
	
	pause
    
end

end