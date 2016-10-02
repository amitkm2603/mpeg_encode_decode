%convert YUV or YCbCr signal to rgb space
 function rgb = convert_yuv_rgb(data)

Y = single(data(:,:,1));
U = single(data(:,:,2));
V = single(data(:,:,3));

%from notes%
R = uint8((Y + 1.13983*V));
G = uint8((Y - 0.39465*U - 0.58060*V));
B = uint8((Y + 2.032110*U));


rgb = uint8(zeros(size(data)));
rgb(:,:,1)=R;
rgb(:,:,2)=G;
rgb(:,:,3)=B;
end