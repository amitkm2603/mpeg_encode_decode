function output=integer_dct_quant(frame)

    fun = @proc;
	output(:,:,1)=round(blkproc(frame(:,:),[4 4],fun));
% 	output(:,:,2)=round(blkproc(frame(:,:,2),[4 4],fun));
% 	output(:,:,3)=round(blkproc(frame(:,:,3),[4 4],fun));
end


function f_hat=proc(f)
global H;
global M_f;
f_hat = round( (H * f * H') .* (M_f ./power(2,15))); %eq 12.5
end