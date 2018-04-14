clear
addpath('../PDM_helpers/');
addpath(genpath('../fitting/'));
addpath('../models/');
addpath(genpath('../face_detection'));
addpath('../CCNF/');

%% loading the patch experts

[patches, pdm, clmParams, early_term_params] = Load_CECLM_general();
views = [0,0,0];

% Loading eye PDM and patch experts
[clmParams_eye, pdm_right_eye, pdm_left_eye] = Load_CLM_params_eye_28();

[patches_right_eye] = Load_Patch_Experts( '../models/hierarch/', 'ccnf_patches_*_synth_right_eye.mat', [], [], clmParams_eye);
[patches_left_eye] = Load_Patch_Experts( '../models/hierarch/', 'ccnf_patches_*_synth_left_eye.mat', [], [], clmParams_eye);
clmParams_eye.multi_modal_types  = patches_right_eye(1).multi_modal_types;
right_eye_inds = [43,44,45,46,47,48];
left_eye_inds = [37,38,39,40,41,42];

right_eye_inds_synth = [9 11 13 15 17 19];
left_eye_inds_synth = [9 11 13 15 17 19];

clmParams.multi_modal_types  = patches(1).multi_modal_types;

%%
% root_dir = 'C:\Users\Tadas\Dropbox\AAM\test data\gaze_original\p00/';
% images = dir([root_dir, '*.jpg']);

%root_dir = './sample_eye_imgs/';
%images = dir([root_dir, '/*.png']);
root_dir = '../../samples/';
images = dir([root_dir, '*.jpg']);

verbose = true;

for img=1:numel(images)
    image_orig = imread([root_dir images(img).name]);

    % MTCNN face detector
    [bboxs, det_shapes, confidences] = detect_face_mtcnn(image_orig);

    % First attempt to use the Matlab one (fastest but not as accurate, if not present use yu et al.)
    % [bboxs, det_shapes] = detect_faces(image_orig, {'cascade', 'yu'});
    % Zhu and Ramanan and Yu et al. are slower, but also more accurate 
    % and can be used when vision toolbox is unavailable
    % [bboxs, det_shapes] = detect_faces(image_orig, {'yu', 'zhu'});
    
    % The complete set that tries all three detectors starting with fastest
    % and moving onto slower ones if fastest can't detect anything
    % [bboxs, det_shapes] = detect_faces(image_orig, {'cascade', 'yu', 'zhu'});
    
    if(size(image_orig,3) == 3)
        image = rgb2gray(image_orig);
    end              

    %%

    if(verbose)
        f = figure;    
        if(max(image(:)) > 1)
            imshow(double(image_orig)/255, 'Border', 'tight');
        else
            imshow(double(image_orig), 'Border', 'tight');
        end
        axis equal;
        hold on;
    end

    for i=1:size(bboxs,1)

        % Convert from the initial detected shape to CLM model parameters,
        % if shape is available
        
        bbox = bboxs(i,:);
        
        [shape,~,~,lhood,lmark_lhood,view_used] = Fitting_from_bb_multi_hyp(image, [], bbox, pdm, patches, clmParams, views);
        
        % shape correction for matlab format
        shape = shape + 1;
             
        % Perform eye fitting now
        [shape, shape_r_eye] = Fitting_from_bb_hierarch(image, pdm, pdm_right_eye, patches_right_eye, clmParams_eye, shape, right_eye_inds, right_eye_inds_synth);
        [shape, shape_l_eye] = Fitting_from_bb_hierarch(image, pdm, pdm_left_eye, patches_left_eye, clmParams_eye, shape, left_eye_inds, left_eye_inds_synth);
        
        plot(shape_l_eye(9:20,1), shape_l_eye(9:20,2), '.g', 'MarkerSize',7);
        plot(shape_l_eye(1:8,1), shape_l_eye(1:8,2), '.b', 'MarkerSize',7);

        plot(shape_r_eye(9:20,1), shape_r_eye(9:20,2), '.g', 'MarkerSize',7);
        plot(shape_r_eye(1:8,1), shape_r_eye(1:8,2), '.b', 'MarkerSize',7);
    end
    hold off;
    
end