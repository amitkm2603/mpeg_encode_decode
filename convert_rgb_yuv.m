%convert rgb signal to YUV or YCbCr space
function output =convert_rgb_yuv(data)
     R = data(:,:,1);
     G = data(:,:,2);
     B = data(:,:,3);
     output = zeros(size(data));
     [height, width] = size(R);
     %initialize
     Y = zeros(height,width);
     U = zeros(height,width);
     V = zeros(height,width);
 
%from notes%
    Y = 0.299*R + 0.587*G + 0.114*B ;

    U = -0.299*R - 0.587*G + 0.886*B;

    V = 0.701*R - 0.587*G - 0.114*B;

    
    output(:,:,1)=Y;
    output(:,:,2)=U;
    output(:,:,3)=V;
 end

 
 