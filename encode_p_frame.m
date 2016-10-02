%http://www.cs.cf.ac.uk/Dave/Multimedia/Lecture_Examples/Compression/mpegproj/
function [reconstruct_img, difference_macro_blk, motion_est] = encode_p_frame(current_frame,reference_frame)
% img0 = im2double(imread('foreman001.png'));
% img1 = im2double(imread('foreman002.png'));
[reconstruct_img, difference_macro_blk, motion_est] = encode_macroblock(current_frame,reference_frame);
% % figure(1);
% imshow(rgb2gray(reconstruct_img)-rgb2gray(img0), []);
% 
% [reconstruct_img difference_macro_blk mpeg] = encode_macroblock(img0,img1);
% figure(2);
% imshow(rgb2gray(reconstruct_img)-rgb2gray(img1), []);
% figure(3)
% quiver(rgb2gray(reconstruct_img),rgb2gray(img1));
%              figure(3);
%             imshow(uint8(reference_frame));
end

function [reconstruct_img, difference_macro_blk, mostion_estimation]=encode_macroblock(current_frame,reference_frame)

[m, n, index] = size(current_frame);
macro_blk_size = [m, n] / 16;
mostion_estimation = struct('type',[],'mvx',[],'mvy',[]);
mostion_estimation(macro_blk_size(1),macro_blk_size(2)).type = [];

difference_macro_blk = zeros(m,n);
reconstruct_img = reference_frame; %copying the ref frame
for m = 1: macro_blk_size(1)
    for n = 1: macro_blk_size(2)
        %get macro blocks
        x = (m-1) * 16 +1 : (m-1)*16 + 16;
        y = (n-1) * 16 +1 : (n-1)*16 + 16;
        [mostion_estimation(m,n), difference_macro_blk(x,y), reconstruct_img(x,y)] = log_search(current_frame(x,y,1),reference_frame,x,y);
    end
end
% figure(1);
% imshow(reference_frame - current_frame);
% figure(2);
% imshow(reference_frame - reconstruct_img);
% imshow(rgb2gray(reconstruct_img)-rgb2gray(reference_frame), []);
end


%get motion vectors, motion compensation and difference
function [motion_estimation,difference_macro_blk, recons_mb]=log_search(macro_blk,ref_frame,x,y)

%only y component
macro_blk_y = macro_blk(:,:);
ref_frame_y = ref_frame(:,:);

%direction vectors
xy = [0,0; 1,0; 1,1; 0,1; -1,1; -1,0; -1,-1; 0,-1; 1,-1];
x_range = xy(:,1)';
y_range = xy(:,2)';
step_size = 8;
[m, n] = size(ref_frame_y);

motion_estimation.type ='P';
min_x = 0;
min_y = 0;

    while step_size >=1
        min_error = inf; 
        for i = 1: length(x_range)
            
            search_window_x = x + min_x + x_range(i)* step_size;
            search_window_y = y + min_y + y_range(i)* step_size;
           
            %limit the search window
            if(search_window_x(1) <1) || (m < search_window_x(end))
                continue;
            end
            
            if(search_window_y(1) <1) || (n < search_window_y(end))
                continue;
            end
             %sum of absolute differences
            error = sum(sum(abs(macro_blk_y-ref_frame_y(search_window_x,search_window_y))));
            
            if (error < min_error)
                min_error = error;
                min_i = i;
            end       
        end
        min_x = min_x + x_range(min_i)*step_size;
        min_y = min_y + y_range(min_i)*step_size;
        
        step_size = step_size / 2;
    end
    motion_estimation.mvx = min_x;
    motion_estimation.mvy = min_y;
    %calculating difference between current macro block and motion
    %estimated macro block

    difference_macro_blk = macro_blk - ref_frame(x+min_x,y+min_y);
%     difference_macro_blk = integer_dct_quant(difference_macro_blk);
%     difference_macro_blk = integer_idct_dequant(difference_macro_blk);
    
    recons_mb = ref_frame(x+min_x,y+min_y);
    recons_mb =recons_mb + difference_macro_blk;
end