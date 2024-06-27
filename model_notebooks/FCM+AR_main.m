clc; close all; clear all;

%% Values of the Variables
% parameters for the fuzzy c-means algorithm and active contouring
fuzziness = 3;
numClust = 3;
winSize = 7;
lengthPenalty = 0.000001;
iteration = 400;
epsilon = 0.3;

%% Testing
files_path = '/Desktop/data'; % Change this to your data directory
all_files = dir(fullfile(files_path,'*.mat')); % Adjusted to .mat files
for ii = 1:length(all_files)
    
    %% Load .mat DATA
    loaded_data = load(fullfile(files_path, all_files(ii).name)); % Load the .mat file
    if isfield(loaded_data, 'cjdata') % Check if 'cjdata' struct is in the loaded .mat file
        img = loaded_data.cjdata.image; % Extract image data
        tumorMask = loaded_data.cjdata.tumorMask; % Extract tumor mask
    else
        error('The .mat file does not contain the expected ''cjdata'' struct.');
    end
    disp(['Size of image: ', mat2str(size(img))]); % Check data structure
    [fPath, fname, fext] = fileparts(fullfile(files_path, all_files(ii).name)); % Extract file path, file name, and extension
    img = mat2gray(img); % Convert to intensity image
    img = uint8(255*img); % Convert from double to uint8
    
    %% SEGMENTATION 
    [nx, ny] = size(img);
    output_temp = tools_FCM(img, numClust, fuzziness); % Adjust FCM function if necessary to handle MATLAB files
    img_fuzzy = (output_temp == numClust); 
    img_fuzzy = bwareaopen(img_fuzzy, 5, 26);
    img_fuzzy = imfill(img_fuzzy, 'holes');

    Output = zeros(nx, ny); 
    ACPlot = figure('visible', 'on');
    set(ACPlot, 'Position', [200, 200, 1280, 600], 'color', 'w', 'name', 'Tumor Segmentation');

    %% Create folder to save results
    opFolder = fullfile(cd, fname);
    if ~exist(opFolder, 'dir')
        mkdir(opFolder);
    end

    figure(ACPlot);
    subplot(1, 2, 1);
    Output = ac(double(img), tumorMask, winSize, lengthPenalty, iteration, epsilon); 
    Output = imfill(Output, 'holes');
    figure(ACPlot);
    subplot(1, 2, 2);
    imshowpair(img, Output);

    %% Save results in sub folders
    imwrite(Output, fullfile(opFolder, [fname, '_tumor_mask.png']));
    maskedRgbImage = bsxfun(@times, img, cast(Output, 'like', img));
    imwrite(maskedRgbImage, fullfile(opFolder, [fname, '_ori_masked.png']));
    title(['Processed Image: ' num2str(ii)], 'fontsize', 18);
    pause(0.1);
    
    close all
end
