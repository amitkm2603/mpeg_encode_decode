%%
%Test to display intra frame encoding
%
function demo_intra_frame()

blk_size = 16;
OriginalImage = (imread('uncompressed.png'));  
Image = double(OriginalImage);
Image_YUV = convert_rgb_yuv(Image);
 
Y_comp = Image_YUV(:,:,1); % Y luminance component
U_comp = sample_down(Image_YUV(:,:,2)); % U chrominance component
V_comp = sample_down(Image_YUV(:,:,3)); % V chrominance component

frame = Y_comp;

[height, width] = size(frame);
reconstructed = ones(size(frame));
for x = 1:blk_size:height
    for y = 1:blk_size:width
        for i=x:4:x+blk_size-1
            for j=y:4:y+blk_size-1
                   if(i==1) && (j == 1) % do nothing
                                  reconstructed(i:i+3,j:j+3) = frame(i:i+3,j:j+3);
                               else if(i == 1) % only horizontal shift or dc
                                       original =  frame(i:i+3,j:j+3);
                                       prediction_block = frame(i:i+3,j-1:j+3); % get the row to left
                                       encoded_frame1 = mode_1(original,prediction_block,4);
                                       encoded_frame2 = mode_2(original,prediction_block,4);
                                       %select the one with minimum error
                                       if(encoded_frame1.difference < encoded_frame2.difference)
                                           reconstructed(i:i+3,j:j+3) = encoded_frame1.encoded_frame;
%                                            disp('i==1; mode 1 selected');
                                       else
                                           reconstructed(i:i+3,j:j+3) = encoded_frame2.encoded_frame;
%                                            disp('i==1; mode 2 selected');
                                       end
                                   else if(j  == 1) % only vertical shift or dc
                                           original =  frame(i:i+3,j:j+3);
                                           prediction_block = frame(i-1:i+3,j:j+3); % get the top most row
                                           encoded_frame1 = mode_0(original,prediction_block,4);
                                           encoded_frame2 = mode_2(original,prediction_block,4);
                                           %select the one with minimum error
                                           if(encoded_frame1.difference < encoded_frame2.difference)
                                               reconstructed(i:i+3,j:j+3) = encoded_frame1.encoded_frame;
%                                                disp('j==1; mode 0 selected');
                                           else
                                               reconstructed(i:i+3,j:j+3) = encoded_frame2.encoded_frame;
%                                                disp('j==1; mode 2 selected');
                                           end
                                   else
                                           %do all
                                             original =  frame(i:i+3,j:j+3);
                                             prediction_block = frame(i-1:i+3,j-1:j+3);
                                             encoded_frame1 = mode_0(original,prediction_block(:,2:end),4); %vertical
                                             encoded_frame2 = mode_1(original,prediction_block(2:end,:),4); %hor
                                             encoded_frame3 = mode_2(original,prediction_block,4); %dc
                                             encoded_frame4 = mode_4(original,prediction_block,4); %diagonal Down right
                                             [~,position] = min([encoded_frame1.difference encoded_frame2.difference encoded_frame3.difference encoded_frame4.difference]);
                                             switch position
                                                 case 1
                                                     reconstructed(i:i+3,j:j+3) = encoded_frame1.encoded_frame;
                                                 case 2
                                                     reconstructed(i:i+3,j:j+3) = encoded_frame2.encoded_frame;
                                                 case 3
                                                      reconstructed(i:i+3,j:j+3) = encoded_frame3.encoded_frame;
                                                 case 4
                                                      reconstructed(i:i+3,j:j+3) = encoded_frame4.encoded_frame;
                                             end
                                       end
                                   end
                   end
            end
        end
    end
end

 a(:,:,1) = reconstructed;
 a(:,:,2) = sample_up(intra_8x8(U_comp,8));
a(:,:,3) = sample_up(intra_8x8(V_comp,8));
fig = figure(100);
set(fig, 'Position', [500 -100 700 700])
subplot(1,2,1);
imshow(convert_yuv_rgb(a));
title('Compressed image using h264 4x4/8x8 intra framing');
 b(:,:,1) = Y_comp;
 b(:,:,2) = sample_up(U_comp);
b(:,:,3) = sample_up(V_comp);
subplot(1,2,2);
imshow(convert_yuv_rgb(b));
title('UnCompressed image');
end  


function reconstructed = intra_8x8(frame,blk_size)
[height, width] = size(frame);
reconstructed = ones(size(frame));
for x = 1:blk_size:height
    for y = 1:blk_size:width
        for i=x:8:x+blk_size-1
            for j=y:8:y+blk_size-1
                   if(i==1) && (j == 1) % do nothing
                                  reconstructed(i:i+7,j:j+7) = frame(i:i+7,j:j+7);
                               else if(i == 1) % only horizontal shift or dc
                                       original =  frame(i:i+7,j:j+7);
                                       prediction_block = frame(i:i+7,j-1:j+7); % get the row to left
                                       encoded_frame1 = mode_1(original,prediction_block,8);
                                       encoded_frame2 = mode_2(original,prediction_block,8);
                                       %select the one with minimum error
                                       if(encoded_frame1.difference < encoded_frame2.difference)
                                           reconstructed(i:i+7,j:j+7) = encoded_frame1.encoded_frame;
%                                            disp('i==1; mode 1 selected');
                                       else
                                           reconstructed(i:i+7,j:j+7) = encoded_frame2.encoded_frame;
%                                            disp('i==1; mode 2 selected');
                                       end
                                   else if(j  == 1) % only vertical shift or dc
                                           original =  frame(i:i+7,j:j+7);
                                           prediction_block = frame(i-1:i+7,j:j+7); % get the top most row
                                           encoded_frame1 = mode_0(original,prediction_block,8);
                                           encoded_frame2 = mode_2(original,prediction_block,8);
                                           %select the one with minimum error
                                           if(encoded_frame1.difference < encoded_frame2.difference)
                                               reconstructed(i:i+7,j:j+7) = encoded_frame1.encoded_frame;
%                                                disp('j==1; mode 0 selected');
                                           else
                                               reconstructed(i:i+7,j:j+7) = encoded_frame2.encoded_frame;
%                                                disp('j==1; mode 2 selected');
                                           end
                                   else
                                           %do all
                                             original =  frame(i:i+7,j:j+7);
                                             prediction_block = frame(i-1:i+7,j-1:j+7);
                                             encoded_frame1 = mode_0(original,prediction_block(:,2:end),8); %vertical
                                             encoded_frame2 = mode_1(original,prediction_block(2:end,:),8); %hor
                                             encoded_frame3 = mode_2(original,prediction_block,8); %dc
%                                              encoded_frame4 = mode_4(original,prediction_block,4); %diagonal Down right
                                             [~,position] = min([encoded_frame1.difference encoded_frame2.difference encoded_frame3.difference]);
                                             switch position
                                                 case 1
                                                     reconstructed(i:i+7,j:j+7) = encoded_frame1.encoded_frame;
                                                 case 2
                                                     reconstructed(i:i+7,j:j+7) = encoded_frame2.encoded_frame;
                                                 case 3
                                                      reconstructed(i:i+7,j:j+7) = encoded_frame3.encoded_frame;
                                                 case 4
                                                      reconstructed(i:i+7,j:j+7) = encoded_frame4.encoded_frame;
                                             end
                                       end
                                   end
                   end
            end
        end
    end
end


end  



%vertical prediction
function encoded_frame = mode_0(orignal,prediction_block,N)

    for i=1:N
            output(i,:)=prediction_block(1,:); % Copy the top most row
    end
    difference =sum(sum(abs(orignal - output)));
    encoded_frame = struct('encoded_frame',output,'difference',difference);
end

%horizontal prediction
function encoded_frame = mode_1(orignal,prediction_block,N)

       for i=1:N
            output(:,i)=prediction_block(:,1); % Copy the left most col
       end
    difference =sum(sum(abs(orignal - output)));
    encoded_frame = struct('encoded_frame',output,'difference',difference);

end

%DC mode http://wiki.multimedia.cx/index.php?title=H.264_Prediction
function encoded_frame = mode_2(original,prediction_block,N)
%m = rows n = cols
horizontal_block = prediction_block(1,:);
vertical_block = prediction_block(:,1);
%m = rows n = cols
[m , n] = size(prediction_block);

if(m == N) && (n == N) %no block found
    mean = 128;
else if ( m > N) &&  (n == N) %only horizontal block found
             mean = (sum(horizontal_block) + N/2)/N;
    else if(m == N) && (n > N) %only vertical block found
             mean = ( sum(vertical_block) + N/2)/N;
        else
             mean = ( sum(vertical_block(2:end,:)) + sum(horizontal_block(:,2:end)) + N) / N*2;
        end
    end
end
            
    for i=1:N
       for j=1:N
            output(i,j)= mean;
        end
    end
    %changing original from into to double for sake of diff calculation
    original = double(original);
    output = double(output);
    difference =sum(sum(abs(original - output)));
    encoded_frame = struct('encoded_frame',output,'difference',difference);    
end

%Diagonal Down/Right	
function encoded_frame = mode_4(original,prediction_block,N)
 
horizontal_block = prediction_block(1,:);
vertical_block = prediction_block(:,1);

 %diagonal Down right
 a = (vertical_block(5) + 2*vertical_block(4) + vertical_block(3) + 2) / 4;
 b = (vertical_block(4) + 2*vertical_block(3) + vertical_block(2) + 2) / 4;
 c = (vertical_block(3) + 2*vertical_block(2) + vertical_block(1) + 2) / 4;
 d = (vertical_block(2) + 2*vertical_block(1) + horizontal_block(2) + 2) / 4;
 e = (vertical_block(1) + 2*horizontal_block(2) + horizontal_block(3) + 2) / 4;
 f = (horizontal_block(2) + 2*horizontal_block(3) + horizontal_block(4) + 2) / 4;
 g = (horizontal_block(2) + 2*horizontal_block(4) + horizontal_block(5) + 2) / 4;
  
 output(1,1)=d;output(1,2)=e;output(1,3)=f;output(1,4)=g;
 output(2,1)=c;output(2,2)=d;output(2,3)=e;output(2,4)=f;
 output(3,1)=b;output(3,2)=c;output(3,3)=d;output(3,4)=e;
 output(4,1)=a;output(4,2)=b;output(4,3)=c;output(4,4)=d;

 %changing original from into to double for sake of diff calculation
 original = double(original);
 output = double(output);
difference =sum(sum(abs(original - output)));
encoded_frame = struct('encoded_frame',output,'difference',difference);

end
