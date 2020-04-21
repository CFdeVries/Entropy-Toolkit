function [  ] = entropy_whole_brain( m, tau, r, file, butter, regressors, scales, algorithm, Ndiscard, TH )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%%

V = spm_vol([file.path file.name]); % pre-processed image to be analysed
Y = spm_read_vols(V);
Y = Y(:,:,:,Ndiscard+1:end);
[x, y, z, N] = size(Y);

%% loading movement regressors

if regressors.add.ON == 1 && regressors.motion.ON == 1
	X_regressors = load(regressors.add.fullpath);
	X_motion = load([file.path, 'rp_' file.name(2:end-3), 'txt']);
	X = [X_motion X_regressors];
	X_pinv = pinv(X);
elseif regressors.add.ON == 1
	X = load(regressors.add.fullpath);
	X_pinv = pinv(X);
elseif regressors.motion.ON == 1
	X = load([file.path, 'rp_' file.name(2:end-3), 'txt']);
	X_pinv = pinv(X);
end


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
	case 'custom'
		entropy_mex = @(m, tau, r, N, data) custom(m, tau, r, N, data);
end

%% preprocessing of data

dim = size(Y);
Y_temp = reshape(Y,[prod(dim(1:3)),dim(4)])';   %reshape 4D fMRI data to 2D
mask_temp = reshape(Y_mask,[prod(dim(1:3)),1])';    % reshape 3D mask to 1D

indices = find(mask_temp == 1);


%frequency filters data
if butter.ON == 1
	Y_temp(indices) = filter(butter.b, butter.a, Y_temp(indices));
end

%removes movement regressors		% does not have to be done in for loop. What about: beta = X_pinv*Y_temp, and then Y_temp = Y_temp - X*beta?
for i = 1:length(indices)%idx = indices'

	data = Y_temp(:, indices(i));
	
	if regressors.add.ON == 1 || regressors.motion.ON == 1
		beta = X_pinv*data;
		data = data - X*beta;
	end
	
	Y_temp(:, indices(i)) = data;
end

%normalises data
Y_temp(indices) = (Y_temp(indices) - mean(Y_temp(indices)))./std(Y_temp(indices));

%% calculate and save entropy maps

entropy = zeros(prod(dim(1:3)),1);
entropy_temp = zeros(length(indices),1);

Vout.dim = [x y z];
Vout.dt = [spm_type('float64') spm_platform('BigEnd')];
Vout.pinfo = [1; 0; 0];
Vout.mat = V(6).mat;
Vout.n = [1,1];

remainder = mod(N, scales);
N = (N-remainder)./scales;

for scale = scales

	data = Y_temp(:, indices(i));

	if scale ~= 1
		data = data(1:end-remainder(scale));
		data = reshape(data, [scale N(scale)]);
		data = mean(data)';
	end

	for i = 1:length(indices)
		entropy_temp(i) = entropy_mex(int32(m), int32(tau), double(r), int32(N(scale)), double(data)); % calculates entropy
	end
	
	entropy(indices) = entropy_temp;
	entropy = reshape(entropy, dim(1), dim(2), dim(3));
	
	s = num2str(scale);
	entropy_name = [file.name(1:end-4), '-', algorithm, '-S', s];
	Vout.fname = [entropy_name, '.nii'];
	
	Vout.descrip = [algorithm, ' scale ', s];
    spm_write_vol(Vout, entropy);

    [file.name, ' scale ', s, ' has finished running']
end

clear entropy Y Y_mask

end

