function display_matrix(M_f,V_i)
 
f = figure('position',[0,0,900,500]);
b = uicontrol('Style','text');
set(b,'String','The integer transform and quantization table - M_f');
set(b,'Position',[50 450 300 20]);

t = uitable('Position',[50 250 400 100],'data', M_f);
% Set width and height
tableextent = get(t,'Extent');
oldposition = get(t,'Position');
newposition = [oldposition(1) oldposition(2) tableextent(3) tableextent(4)];
set(t, 'Position', newposition);
set(t,'ColumnWidth',{75});

b1 = uicontrol('Style','text');
set(b1,'String','The inverse integer transform and de-quantization table - V_i');
set(b1,'Position',[50 220 300 20]);


u = uitable('Position',[50 30 400 100],'data', V_i);
% Set width and height
tableextent = get(u,'Extent');
oldposition = get(u,'Position');
newposition = [oldposition(1) oldposition(2) tableextent(3) tableextent(4)];
set(u, 'Position', newposition);
set(u,'ColumnWidth',{75});

end