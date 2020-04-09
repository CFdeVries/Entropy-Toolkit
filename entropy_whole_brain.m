function [  ] = entropy_whole_brain( m, tau, r, file, filter, regressors, Nscales, algorithm, Ndiscard, TH )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%%

scales = 1:Nscales;

V = spm_vol([file.path file.name]); % pre-processed image to be analysed
Y = spm_read_vols(V);
Y = Y(:,:,:,Ndiscard+1:end);
[x, y, z, N] = size(Y);

%% load and remove movement regressors

X = load([file.path, 'rp_' file.name(2:end-3), 'txt']);    % loading movement regressors

if regressors.ON == 1
	X_regressors = load(regressors.fullpath);
	X = [X X_regressors];
end

X_pinv = pinv(X);

%% brain mask

Y_mask = ones(x, y, z);

for i = 1:N
	Y_slice = Y(:,:,:,i);
	Y_slice2 = Y_slice;
	Y_slice2 = Y_slice2(isfinite(Y_slice2));
	Y_slice2(Y_slice2 < mean(Y_slice2(:))/8) = [];
	Y_global = mean(Y_slice2);
	Y_mask = Y_mask.*(Y_slice > Y_global * TH);
end

%https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind1704&L=SPM&P=R46465
%https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=spm;1a959328.1112

clear Y_slice Y_slice2 Y_global

%% select entropy algorithm

switch algorithm
	case 'ApEn'
		entropy_mex = @(m, tau, r, N, data) ApEn_mex(m, tau, r, N, data);
	case 'SampEn'
		entropy_mex = @(m, tau, r, N, data) SampEn_mex(m, tau, r, N, data);
	case 'fApEn'
		entropy_mex = @(m, tau, r, N, data) fApEn_mex(m, tau, r, N, data);
	case 'fSampEn'
		entropy_mex = @(m, tau, r, N, data) fSampEn_mex(m, tau, r, N, data);
end

%% calculate entropy

entropy = zeros(x, y, z);

for scale = scales

	if scale ~= 1
		remainder = mod(N, scale);
		N2 = (N-remainder)/scale;
	else
		N2 = N;
	end	

    for k = 1:z % parallel loop (instead of 'for')
        for j = 1:y
            for i = 1:x
                if Y_mask(i, j, k) == 1
                    data = Y(i,j,k,:); % reads the fMRI time series of one voxel
                    data = data(:);
					
					%removes movement regressors
                    beta = X_pinv*data;
                    data = data - X*beta;
					
                    %filters data
					if filter.ON == 1
						data = butter(filter.b, filter.a, data);
					end
                    
					data = (data - mean(data))/(std(data)); % normalises data

                    if scale ~= 1
                        data = data(1:end-remainder);
                        data = reshape(data, [scale N2]);
                        data = mean(data)';
                    end

                    entropy(i, j, k) = entropy_mex(int32(m), int32(tau), double(r), int32(N2), double(data)); % calculates fApEn
                    clear data
                end
            end
        end
		
    end
	
	s = num2str(scale);
	
	entropy_name = [file.name(1:end-4), '-', algorithm, '-S', s];
	
    Vout.fname = [entropy_name, '.nii'];
	Vout.dim = [x y z];
    Vout.dt = [spm_type('float64') spm_platform('BigEnd')];
	Vout.pinfo = [1; 0; 0];
	Vout.mat = V(6).mat;
	Vout.n = [1,1];
	Vout.descrip = [algorithm, ' scale ', s];
    spm_write_vol(Vout, entropy);

    [file.name, ' scale ', s, ' has finished running']
    
end

clear entropy Y Y_mask

end

