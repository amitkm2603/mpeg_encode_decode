%DownSample the Matrix by 2
%http://stackoverflow.com/questions/1788180/how-do-i-sample-a-matrix-in-matlab?rq=1
function output=sample_down(data)
[rows,cols]=size(data);
output = data(1:2:end,1:2:end);
end