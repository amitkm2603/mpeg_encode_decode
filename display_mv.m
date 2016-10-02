%http://ugweb.cs.ualberta.ca/~vis/courses/CompVis/assign/motionAssign/
function display_mv(encoded_mpeg,index,frame_pattern,current_frame,previous_frame)
  macro_blk_size = size(encoded_mpeg.data.Y_comp);
   macro_blk_size = macro_blk_size/16; 
            motion_est = encoded_mpeg.motion_estimation;
            for m = 1: macro_blk_size(1)
                for n_1 = 1: macro_blk_size(2)
                   mvx(m,n_1) =  motion_est(m,n_1).mvy;
                   mvy(m,n_1) =  motion_est(m,n_1).mvx;
                end
            end
    
hFig = figure(10);
set(hFig, 'Position', [0 0 1200 1200])

                  subplot(2,2,1);
                quiver(flipud(mvx),flipud(mvy));
                set(gca,'XLim',[-1, macro_blk_size(2)+2],'YLim',[-1, macro_blk_size(1)+2]);
                title(sprintf('Motion vectors for frame %i and pattern %c',index,frame_pattern));
              
                difference = encoded_mpeg.data;
                decoded_difference(:,:,1) = integer_idct_dequant(difference.Y_comp);
%                 decoded_difference(:,:,2)= integer_idct_dequant(difference.Y_comp);
%                 decoded_difference(:,:,3) =integer_idct_dequant(difference.Y_comp);
%                 decoded_difference =  convert_yuv_rgb(decoded_difference);
%                 figure(11);
                 subplot(2,2,4);
                imshow(mat2gray(decoded_difference));
                title(sprintf('Decoded difference for frame %i and frame type %c',index,frame_pattern));
                subplot(2,2,3);
%                 figure(20);
                imshow( mat2gray( current_frame(:,:,1) - previous_frame(:,:,1)));
                 title(sprintf('Difference between uncoded frames 1 and 2'));
                
end