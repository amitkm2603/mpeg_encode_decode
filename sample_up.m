%unsampling by copying the one pixel to 4 pixel places%
function output=sample_up(mat)

[m, n] = size(mat);
cols = n*2 ;
rows = m*2 ;
temp=zeros(rows,cols);

   rows = 1;
   for i=1:m
       cols = 1;
       for j=1:n
           temp(rows,cols) = mat(i,j);
           temp(rows,cols+1)= mat(i,j);
           temp(rows+1,cols)= mat(i,j);
           temp(rows+1,cols+1)= mat(i,j);
           cols = cols+2;
       end
       rows = rows+2;
   end

output = temp;
