%decode the p frame
%http://dsp.stackexchange.com/questions/986/how-do-the-motion-vectors-work-in-predictive-coding-for-mpeg/1023#1023
function decoded_frame = decode_p_frame(difference,motion_estimation,previous_frame)
          decoded_frame = struct('Y_comp',[],'U_comp',[] ,'V_comp'  ,[]);
          difference.Y_comp = integer_idct_dequant(difference.Y_comp);
          difference.U_comp = integer_idct_dequant(difference.U_comp);
          difference.V_comp = integer_idct_dequant(difference.V_comp);
          
          %copying previous frame
           previous_frame_copy = previous_frame.Y_comp;
           
           %Motion Estimation - applying on only Y component since it was
           %calculated using Y
           [m, n] = size(difference.Y_comp);
           macro_blk_size = [m, n] / 16;
            for m = 1: macro_blk_size(1)
                for n = 1: macro_blk_size(2)
                    x = (m-1) * 16 +1 : (m-1)*16 + 16;
                    y = (n-1) * 16 +1 : (n-1)*16 + 16;
                   min_x = motion_estimation(m,n).mvx ;
                   min_y = motion_estimation(m,n).mvy ;
                   previous_frame_copy(x,y) = previous_frame.Y_comp(x+min_x,y+min_y,1);
                end
            end
            %adding the difference to the previous frame after adding mv to
            %get the decoded frame
            decoded_frame.Y_comp = previous_frame_copy +   difference.Y_comp;
            decoded_frame.U_comp = previous_frame.U_comp + difference.U_comp;
            decoded_frame.V_comp = previous_frame.V_comp + difference.V_comp;
end