%%
%@author : Amit Mandal
%Assignment 2
%Date: 22-Feb-2016
%%

function time_arr = init(mmdata,frames_to_process,quality,fps,pattern)
clc;
frames = mmdata.frames;
%encoding
% pattern = 'IPBBPI';
h = waitbar(0,'Please wait... Setting up Integer Transform and Quantization matrices');
%initialize the integer transform/quant/scaling matrix based on quality
init_global_var(quality);
waitbar(1,h,'Setting up Integer Transform and Quantization matrices complete. Encoding will start now');
close(h);


%encode
disp('encoding the video ..');
time_arr = [];
tic;
encoded_mpeg = encoder(frames, pattern, frames_to_process);
time_arr(end+1) = toc;

%decode
disp('decoding the video..');
tic;
decoded_mpeg = decoder(encoded_mpeg, frames_to_process);
time_arr(end+1) = toc;
implay(decoded_mpeg,fps);
end
%%

function encoded_mpeg = encoder(frames,pattern,frames_to_process)

%%%%%%
%% frames are in the form of struct -> cdata and colormap 
%% cdata in the form: height x width x 3 -> uint8 form
%%%%%%%
n = frames_to_process;
step = 1;
%counter to keep track of the pattern
pattern_pos  = 1;
%saving previous frame
previous_frame = []; 
h = waitbar(0,'Please wait... Encoding of P and I frames');
    for frame_index = 1:step: n
               
         
        frame_data = frames(1,frame_index); %iframe
        current_frame = double(frame_data.cdata); %cdata height x width x 3 -> uint8 form
        
        %RBG - > YUV
        temp_frame = convert_rgb_yuv(current_frame);
        %implementing 4:2:0 Chroma sub sampling
        current_frame = struct('Y_comp',temp_frame(:,:,1),'U_comp',sample_down(temp_frame(:,:,2)) ,'V_comp'  , sample_down(temp_frame(:,:,3)));
        
        % deciding which frame coding to apply
        frame_pattern = mod(pattern_pos,length(pattern));
        if(frame_pattern == 0) %last element
            frame_pattern = pattern(length(pattern)); 
        else
            frame_pattern = pattern(frame_pattern);
        end
        pattern_pos = pattern_pos +1 ;
        
        waitbar(frame_index / n, h, strcat('Encoding frame number:    ',num2str(frame_index), ' of type:    ',frame_pattern));
        
        %if its frame B then skip it as we don't have the processed future frame
        if frame_pattern == 'B'
            encoded_mpeg_t = struct('type','B','data',[],'motion_estimation',[] );
            encoded_mpeg{frame_index} = encoded_mpeg_t;
            continue;
        end
        
        %encode the frame
        [encoded_mpeg{frame_index}, previous_frame ]  = encode_frame(current_frame,frame_pattern,previous_frame,[]);
        
    
    end
    close(h); 
    
  %process the unprocessed B frames
  pattern_pos  = 1; % reset pattern position
  h = waitbar(0,'Please wait... Encoding B frames..'); 
     for frame_index = 1:step: n
          frame_pattern = mod(pattern_pos,length(pattern));
        if(frame_pattern == 0) %last element
            frame_pattern = pattern(length(pattern)); 
        else
            frame_pattern = pattern(frame_pattern);
        end
        pattern_pos = pattern_pos +1 ;
        
        %process b frames
        % condition: the next/previous cannot be a b frame, if they are, we
        % look further +/- 1 frames to look for it
        if frame_pattern == 'B'
            
             waitbar(frame_index / n, h, strcat('Encoding frame number:    ',num2str(frame_index), ' of type:    ',frame_pattern));
             
             frame_data = frames(1,frame_index); %iframe
             current_frame = double(frame_data.cdata); %cdata height x width x 3 -> uint8 form
             
             %RBG - > YUV
             temp_frame = convert_rgb_yuv(current_frame);
             
             %implementing 4:2:0 Chroma sub sampling
             current_frame = struct('Y_comp',temp_frame(:,:,1),'U_comp',sample_down(temp_frame(:,:,2)) ,'V_comp'  , sample_down(temp_frame(:,:,3)));
             
             previous_frame = encoded_mpeg{frame_index-step};
%            encoded_mpeg = struct('type',[],'data',[],'motion_estimation',[] );
             if(previous_frame.type== 'B')
                previous_frame = encoded_mpeg{frame_index - (2*step)}; 
             end
             
             next_frame = encoded_mpeg{frame_index+step};
             if(next_frame.type == 'B')
                next_frame = encoded_mpeg{frame_index+(2*step)}; 
             end
             
            [encoded_mpeg{frame_index}, reconst_mpeg ]  = encode_frame(current_frame,frame_pattern,previous_frame,next_frame);
        end
        
        %generate motion vector plot for 2nd frame
        if frame_index == 2
            frame_data = frames(1,frame_index); %iframe
            current_frame = double(frame_data.cdata);
             frame_data = frames(1,frame_index-1); %iframe
            previous_frame = double(frame_data.cdata);
          display_mv(encoded_mpeg{frame_index},frame_index,frame_pattern,current_frame,previous_frame);
        end

        
     end
    close(h);
end

%% Decoder
function mov = decoder(encoded_frames,frames_to_process)
n = frames_to_process;
step = 1;
%each frame to be saved in the below format so that implay can play the
%frame sequences as video
mov = struct('cdata',[],'colormap',[]);

h = waitbar(0,'Please wait... Decoding in progress ..');

    for frame_index = 1:step: n
    current_frame = encoded_frames{frame_index};
    
    waitbar(frame_index / n, h, strcat('Decoding frame number:    ',num2str(frame_index), ' of type:    ',current_frame.type));

    decode  = decode_frame(current_frame,current_frame.prev_frame,[]);
    
      %Reversing the 4:2:0 chroma sub sampling
      decoded_frame(:,:,1) =decode.Y_comp;
      decoded_frame(:,:,2) =sample_up(decode.U_comp);
      decoded_frame(:,:,3) =sample_up(decode.V_comp);
      
      %converting YUV back to RGB
      decode = convert_yuv_rgb(decoded_frame);
      mov(frame_index) = struct('cdata',decode,'colormap',[]);
    end
    close(h);
end

%%
function [encoded_mpeg, reconst_mpeg] = encode_frame(current_frame,frame_pattern,previous_frame, next_frame)
     encoded_mpeg = struct('type',[],'data',[],'motion_estimation',[] );
     
     encoded_frame = struct('Y_comp',[],'U_comp',[] ,'V_comp'  ,[]);
     reconst_mpeg = struct('Y_comp',[],'U_comp',[] ,'V_comp'  ,[]);
     difference = struct('Y_comp',[],'U_comp',[] ,'V_comp'  ,[]);

     %using h264 integer intra frame coding to encode I frame
     if(frame_pattern == 'I')
         %http://iphome.hhi.de/wiegand/assets/pdfs/h264-AVC-Standard.pdf

              %8x8 encoding for chroma
              encoded_frame.Y_comp = encode_intra_frame(current_frame.Y_comp,4,16);
              %4x16 encoding for luma
              encoded_frame.U_comp = encode_intra_frame(current_frame.U_comp,8,8);
              encoded_frame.V_comp = encode_intra_frame(current_frame.V_comp,8,8);
              
              %using integer transform to encode the frame
              enc_i_frame.Y_comp = integer_dct_quant(double(encoded_frame.Y_comp));
              enc_i_frame.U_comp = integer_dct_quant(double(encoded_frame.U_comp));
              enc_i_frame.V_comp = integer_dct_quant(double(encoded_frame.V_comp));
              
              %Decoding the frame to use it as reference for future frames
              reconst_mpeg.Y_comp = integer_idct_dequant(double(enc_i_frame.Y_comp));
              reconst_mpeg.U_comp = integer_idct_dequant(double(enc_i_frame.U_comp));
              reconst_mpeg.V_comp = integer_idct_dequant(double(enc_i_frame.V_comp));
             
             
             %store the frame in frame data structure
             encoded_mpeg.type = 'I';
             encoded_mpeg.data = enc_i_frame;
             encoded_mpeg.motion_estimation = 0; %no motion estimation for I frame
             encoded_mpeg.prev_frame = []; %no reference frame for I frames

     end
    
     %Encoding P frame using logarithmic motion vector search
     if(frame_pattern == 'P')
         % only using Luma(Y) component to find out MV
         [~, difference.Y_comp, motion_est] = encode_p_frame(current_frame.Y_comp,previous_frame.Y_comp);
         
         %simply find out difference of U and V component
          difference.U_comp = current_frame.U_comp - previous_frame.U_comp;
          difference.V_comp = current_frame.V_comp - previous_frame.V_comp;
          
          %using integer transform to encode the difference
          difference.Y_comp = integer_dct_quant(difference.Y_comp);
          difference.U_comp = integer_dct_quant(difference.U_comp);
          difference.V_comp = integer_dct_quant(difference.V_comp);
          
          %store the frame in frame data structure
          encoded_mpeg.type = 'P';
          encoded_mpeg.data = difference; % difference is stored
          encoded_mpeg.motion_estimation = motion_est;
          encoded_mpeg.prev_frame = previous_frame;
          
          
          %Decoding the frame to use it as reference for future frames
          reconst_mpeg = decode_p_frame(difference,motion_est,previous_frame);
     end
     
     %http://dsp.stackexchange.com/questions/2486/video-compression-when-would-an-average-of-the-previous-and-next-i-or-p-frame?lq=1
     if frame_pattern == 'B'
        
         %need to decode the previously encoded frame
         if previous_frame.type == 'I'
             
             previous_frame_temp_y = integer_idct_dequant(previous_frame.data.Y_comp);
             previous_frame_temp_u = integer_idct_dequant(previous_frame.data.U_comp);
             previous_frame_temp_v = integer_idct_dequant(previous_frame.data.V_comp);
             
             previous_frame = struct('Y_comp',previous_frame_temp_y,'U_comp',previous_frame_temp_u ,'V_comp'  ,previous_frame_temp_v);
         elseif previous_frame.type == 'P'
                 previous_frame = decode_p_frame(previous_frame.data,previous_frame.motion_estimation,previous_frame.prev_frame);
         end
         %need to decode the next encoded frame
         if next_frame.type == 'I'
             previous_frame_temp_y = integer_idct_dequant(previous_frame.Y_comp);
             previous_frame_temp_u = integer_idct_dequant(previous_frame.U_comp);
             previous_frame_temp_v = integer_idct_dequant(previous_frame.V_comp);
             
             next_frame = struct('Y_comp',previous_frame_temp_y,'U_comp',previous_frame_temp_u ,'V_comp'  ,previous_frame_temp_v);
             
          elseif next_frame.type == 'P'
                 next_frame = decode_p_frame(next_frame.data,next_frame.motion_estimation,next_frame.prev_frame);
         end
         
        
          %Calculating forward MV and difference
          [~, difference_forward.Y_comp, motion_est] = encode_p_frame(current_frame.Y_comp,previous_frame.Y_comp);        
          difference_forward.U_comp = current_frame.U_comp - previous_frame.U_comp;
          difference_forward.V_comp = current_frame.V_comp - previous_frame.V_comp;
          %Calculating backward MV and difference
          [~, difference_backward.Y_comp, motion_est] = encode_p_frame(next_frame.Y_comp,current_frame.Y_comp);        
          difference_backward.U_comp = next_frame.U_comp - current_frame.U_comp;
          difference_backward.V_comp = next_frame.V_comp - current_frame.V_comp;
          
         %calculating average of differences
         difference.Y_comp = ( (difference_forward.Y_comp + difference_backward.Y_comp) / 2 );
         difference.Y_comp = integer_dct_quant(difference.Y_comp);
         difference.U_comp = ( (difference_forward.U_comp + difference_backward.U_comp) / 2 );
         difference.U_comp = integer_dct_quant(difference.U_comp);
         difference.V_comp = ( (difference_forward.V_comp + difference_backward.V_comp) / 2 );
         difference.V_comp = integer_dct_quant(difference.V_comp);
         
         %averaging the motion vectors of the forward and backward mv
          [m, n, ~] = size(difference);
           macro_blk_size = [m, n] / 16;
            for m = 1: macro_blk_size(1)
                for n = 1: macro_blk_size(2)
                   motion_est(m,n).mvx = round( (motion_est_forward(m,n).mvx + motion_est_backward(m,n).mvx ) / 2 );
                   motion_est(m,n).mvy = round( (motion_est_forward(m,n).mvy + motion_est_backward(m,n).mvy ) / 2 );
                end
            end
            
          %reconstructing the image
          reconst_mpeg = decode_p_frame(difference,motion_est,previous_frame);
          
          encoded_mpeg.data = difference;
          encoded_mpeg.motion_estimation = motion_est;
          encoded_mpeg.prev_frame = previous_frame;
          encoded_mpeg.type = 'B';
     end
     
end


%%
% Decoding the frames
%
function decoded_frame = decode_frame(current_frame,previous_frame,~)
decoded_frame = struct('Y_comp',[],'U_comp',[] ,'V_comp'  ,[]);
difference = struct('Y_comp',[],'U_comp',[] ,'V_comp'  ,[]);

frame_pattern =current_frame.type;
        if(frame_pattern == 'I')
            current_frame = current_frame.data;
            decoded_frame.Y_comp = integer_idct_dequant(double(current_frame.Y_comp));
            decoded_frame.U_comp = integer_idct_dequant(double(current_frame.U_comp));
            decoded_frame.V_comp = integer_idct_dequant(double(current_frame.V_comp));
         end
         
         if(frame_pattern == 'P' || frame_pattern == 'B')
            difference_temp = current_frame.data;
            difference.Y_comp = difference_temp.Y_comp;
            difference.U_comp = difference_temp.U_comp;
            difference.V_comp = difference_temp.V_comp;
            
            motion_estimation = current_frame.motion_estimation;
            decoded_frame = decode_p_frame(difference,motion_estimation,previous_frame);
         end
end
%%

%http://www2.cs.sfu.ca/CourseCentral/820/li/material/source/H264_Codec_Notes.pdf
%% calculating Integer dct-quant-scaling and reverse matrices
function init_global_var(QP)

%test - sample macro block
% f = [72 82 85 79;
% 74 75 86 82;
% 84 73 78 80;
% 77 81 76 84];
global H;
H = [1 1 1 1;
    2 1 -1 -2
    1 -1 -1 1
    1 -2 2 -1];
global H_inv;
H_inv = [1 1 1 0.5;
    1 0.5 -1 -1;
    1 -0.5 -1 1;  
    1 -1 1 -0.5];
m = [13107 5243 8066;
    11916 4660 7490;
    10082 4194 6554;
    9362 3647 5825;
    8192 3355 5243;
    7282 2893 4559];
v = [10 16 13;
    11 18 14;
    13 20 16;
    14 23 18;
    16 25 20;
    18 29 23];

global M_f;
M_f = [m(mod(QP,6)+1, 0+1) m(mod(QP,6)+1, 2+1) m(mod(QP,6)+1, 0+1) m(mod(QP,6)+1, 2+1);
    m(mod(QP,6)+1, 2+1) m(mod(QP,6)+1, 1+1) m(mod(QP,6)+1, 2+1) m(mod(QP,6)+1, 1+1);
    m(mod(QP,6)+1, 0+1) m(mod(QP,6)+1, 2+1) m(mod(QP,6)+1, 0+1) m(mod(QP,6)+1, 2+1);
    m(mod(QP,6)+1, 2+1) m(mod(QP,6)+1, 1+1) m(mod(QP,6)+1, 2+1) m(mod(QP,6)+1, 1+1)];



global V_i;

V_i =  [v(mod(QP,6)+1, 0+1) v(mod(QP,6)+1, 2+1) v(mod(QP,6)+1, 0+1) v(mod(QP,6)+1, 2+1);
        v(mod(QP,6)+1, 2+1) v(mod(QP,6)+1, 1+1) v(mod(QP,6)+1, 2+1) v(mod(QP,6)+1, 1+1);
        v(mod(QP,6)+1, 0+1) v(mod(QP,6)+1, 2+1) v(mod(QP,6)+1, 0+1) v(mod(QP,6)+1, 2+1);
        v(mod(QP,6)+1, 2+1) v(mod(QP,6)+1, 1+1) v(mod(QP,6)+1, 2+1) v(mod(QP,6)+1, 1+1)];
    
if(QP>=6)
    M_f = round(M_f ./power(2,floor(QP/6))); %eq 12.6
    V_i = round(V_i .*power(2,floor(QP/6))); %eq 12.8
end
 
%f_hat = round( (H * f * H') .* (M_f ./power(2,15))); %eq 12.5
%f_tilde = round( (H_inv * (f_hat .* V_i) * H_inv')./power(2,6)); %eq 12.7
 display_matrix(M_f,V_i);
end


