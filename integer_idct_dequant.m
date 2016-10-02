function output=integer_idct_dequant(frame)

    fun = @proc;
	output(:,:,1)=round(blkproc(frame(:,:),[4 4],fun));
% 	output(:,:,2)=round(blkproc(frame(:,:,2),[4 4],fun));
% 	output(:,:,3)=round(blkproc(frame(:,:,3),[4 4],fun));
end


function f_tilde=proc(f_hat)
global H_inv;
global V_i;
f_tilde = round( (H_inv * (f_hat .* V_i) * H_inv')./power(2,6)); %eq 12.7
end