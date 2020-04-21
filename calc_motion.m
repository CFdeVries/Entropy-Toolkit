function [  ] = calc_motion(fMRI)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

Nfiles = size(fMRI.name, 1);

motion = zeros(Nfiles, 6);

for i = 1:Nfiles

    % Import data from text file.
    % Initialize variables.
    filename = [fMRI.path(i,:), 'rp_' fMRI.name(i,2:end-3), 'txt'];

    % Format string for each line of text:
    %   columns 1to 6: double (%f)
    formatSpec = '%16f%16f%16f%16f%16f%f%[^\n\r]';

    % Open the text file.
    fileID = fopen(filename,'r');

    % Read columns of data according to format string.
    % This call is based on the structure of the file used to generate this
    % code. If an error occurs for a different file, try regenerating the code
    % from the Import Tool.
    dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '',  'ReturnOnError', false);

    % Close the text file.
    fclose(fileID);

    % Allocate imported array to column variable names
    e1 = dataArray{:, 1};   % x translation
    e2 = dataArray{:, 2};   % y translation
    e3 = dataArray{:, 3};   % z translation
    e4 = dataArray{:, 4};   % x rotation, pitch
    e5 = dataArray{:, 5};   % y rotation, roll
    e6 = dataArray{:, 6};   % z rotation, yaw
    
    % delete excess text file variables
    clearvars filename formatSpec fileID dataArray ans;   
    
    x = e1(2:end)-e1(1:end-1);
    y = e2(2:end)-e2(1:end-1);
    z = e3(2:end)-e3(1:end-1);
    
    phi = e4(2:end)-e4(1:end-1);
    theta = e5(2:end)-e5(1:end-1);
    psi = e6(2:end)-e6(1:end-1);
    
    
    motion(i, 1) = mean(abs(x));		% mean_x_displacement
    motion(i, 2) = mean(abs(y));		% mean_y_displacement
    motion(i, 3) = mean(abs(z));		% mean_z_displacement
    
    motion(i, 4) = mean(abs(phi));		% mean_phi_displacement
    motion(i, 5) = mean(abs(theta));	% mean_theta_displacement
    motion(i, 6) = mean(abs(psi));		% mean_psi_displacement
end


motion_cell = num2cell(motion);
motion_cell = [{'file', 'x', 'y', 'z', 'phi', 'theta', 'psi'}; fullfile(fMRI.path, fMRI.name) motion_cell];

outputfile = 'motion_parameters.xlsx';

if exist(outputfile, 'file')
	error('A motion parameter output file already exists: %s. Delete or rename it to run this function.', outputfile);
else
	xlswrite(outputfile, motion_cell);
end

end

