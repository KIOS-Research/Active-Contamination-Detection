%% Active Contamination Detection case study scenarios results
% Choose a simulation results file and display the results from the
% application of ACD on the corresponding networks (figures and tables)

%% Clear all and load paths
try 
d.unload
catch ERR
end 
fclose all; clear class; close all; clear all; clc
addpath(genpath(pwd));
disp('Toolkits Loaded.'); 

%% Choose simulation results
sim_num =[];clc
dirName = [pwd,'\simulations\*.mat'];
Allinpnames = dir(dirName);
if isempty(sim_num)
    disp(sprintf('\nChoose simulation scenario:'))
    for i=1:length(Allinpnames)
        disp([num2str(i),'. ', Allinpnames(i).name])
    end
    x = input(sprintf('\nEnter simulation scenario number: '));
else
    x = sim_num;
end
load(Allinpnames(x).name);
clearvars Allinpnames ans dirName 
d=epanet(inpname);

%% Create results table
contamNodes = cell(length(ResultsGA_node),1);
for i =1:length(ResultsGA_node)
    if ResultsGA_node{i}.PrPenalty>20 || ResultsGA_node{i}.kd>kdmax
    solutionGA(i) = 0;
    else
    solutionGA(i) = 1;
    end
    PrViolation(i) = ResultsGA_node{i}.PrPenalty;
    kdGA(i)=ResultsGA_node{i}.kd;
    kdDEF(i)=ResultsDEF_node{i}.kd;
    impactGA(i) = ResultsGA_node{i}.impact;
    impactDEF(i) = ResultsDEF_node{i}.impact;
    valvesClosedGA(i) = ResultsGA_node{i}.valvesClosed;
    pumpHead(i) = ResultsGA_node{i}.pumpHead;
    time(i) = ResultsGA_node{i}.elapsed_time/60;
    contamNodes{i,:} = d.getNodeNameID{ResultsGA_node{i}.node_ind};
    if isempty(str2num(contamNodes{i,:}))
        contamNodesNum(i) =1000+ResultsGA_node{i}.node_ind;
    else
        contamNodesNum(i)=str2num(contamNodes{i,:});
    end
end
varNames = {'Contam_Node','Det_Time_Def','Impact_Def','AFD_Solved','Pressure_Violation','Det_Time_AFD','Impact_AFD','Valves_Closed','Res_Head','Sim_Time'};
T = table(contamNodesNum',kdDEF',impactDEF',solutionGA',PrViolation',kdGA',impactGA',valvesClosedGA',pumpHead',time',...
    'VariableNames',varNames);
% T(find(T{:,5}>20 | T{:,6}>48),:)=[];
T = sortrows(T,1);

%% Create plots
%%%Text offsets for each network:
if contains(inpname,'Hanoi')
xsenoff=200; ysenoff=150; alpha=35; beta=50; yoff=150; %Hanoi
fontsizeSen=11; fontsize=11; 
fontweightSen='bold'; fontweight='bold';
remove_nodes=d.getNodeIndex({'7','10','12','17','19'});
legendNameStr = 'legends1.png';
legend_coor=d.getNodeCoordinates(24);
xlegoff=-280; 
ylegoff=-3900;
xscale_leg=1.3;
scale_leg=1.25;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif contains(inpname,'CY_DMA')
xsenoff=30; ysenoff=-20; alpha=6.5; beta=9.5; yoff=24; %CY_DMA
fontsizeSen=10; fontsize=10;
fontweightSen='bold'; fontweight='bold';
remove_nodes=d.getNodeIndex({'19','56','87','85','73','71','51','38',...
                             '26','9','25','20','18','7','1','13','30',...
                             '69','67','63','68','74','77','11','34','47'});
legendNameStr = 'legends1.png';
legend_coor=d.getNodeCoordinates(19);
xlegoff=0;%-200; 
ylegoff=0;
xscale_leg=1;
scale_leg=3;
end

%% Plot ACD times
d.plot
legend('off')
title('Sources Detected using ACD')
sen_nodes = Ns;
%%%%sensor nodes:
coor=d.getNodeCoordinates(sen_nodes);
x=coor(:,1);y=coor(:,2);
plot(x,y,'o','LineWidth',2,'MarkerEdgeColor','r','MarkerFaceColor','r','MarkerSize',5)
text(x-xsenoff,y+ysenoff,'Sensor','Color','red','FontWeight',fontweightSen,'Fontsize',fontsizeSen)
for i = 1:length(ResultsGA_node)
node=d.getNodeIndex(contamNodes{i,:});
value1=kdGA(i);
xoff1 = alpha*length(num2str(value1));
value2=impactGA(i);
xoff2 = beta*length(num2str(round(value2)));
if ismember(node,sen_nodes)
elseif ismember(node,remove_nodes) && solutionGA(i)
coor=d.getNodeCoordinates(node);
x=coor(1);y=coor(2);
plot(x,y,'o','LineWidth',2,'MarkerEdgeColor','y','MarkerFaceColor','y','MarkerSize',5)
elseif ismember(node,remove_nodes) %prints only blue dot (default)
elseif solutionGA(i)
coor=d.getNodeCoordinates(node);
x=coor(1);y=coor(2);
plot(x,y,'o','LineWidth',2,'MarkerEdgeColor','y','MarkerFaceColor','y','MarkerSize',5)
text(x-xoff1,y+yoff,num2str(value1),'FontWeight',fontweight,'Fontsize',fontsize)
text(x-xoff2,y-yoff,['(',num2str(round(value2)),')'],'FontWeight',fontweight,'Fontsize',fontsize)
else %print blue and Inf
coor=d.getNodeCoordinates(node);
x=coor(1);y=coor(2);
text(x-xoff1,y+yoff,'Inf','FontWeight',fontweight,'Fontsize',fontsize)
text(x-xoff2,y-yoff,['(',num2str(round(value2)),')'],'FontWeight',fontweight,'Fontsize',fontsize)
end
end


%% Plot PCD times
d.plot
legend('off')
title('Sources Detected in default PCD scheme')
sen_nodes = Ns;
%%%%sensor nodes:
coor=d.getNodeCoordinates(sen_nodes);
x=coor(:,1);y=coor(:,2);
plot(x,y,'o','LineWidth',2,'MarkerEdgeColor','r','MarkerFaceColor','r','MarkerSize',5)
text(x-xsenoff,y+ysenoff,'Sensor','Color','red','FontWeight',fontweightSen,'Fontsize',fontsizeSen)
for i = 1:length(ResultsGA_node)
node=d.getNodeIndex(contamNodes{i,:});
value1=kdDEF(i);
xoff1 = alpha*length(num2str(value1));
value2=impactDEF(i);
xoff2 = beta*length(num2str(round(value2)));
if ismember(node,sen_nodes)
elseif ismember(node,remove_nodes) && value1<kdmax
coor=d.getNodeCoordinates(node);
x=coor(1);y=coor(2);
plot(x,y,'o','LineWidth',2,'MarkerEdgeColor','y','MarkerFaceColor','y','MarkerSize',5)
elseif ismember(node,remove_nodes) %prints only blue dot (default)
elseif value1<kdmax
coor=d.getNodeCoordinates(node);
x=coor(1);y=coor(2);
plot(x,y,'o','LineWidth',2,'MarkerEdgeColor','y','MarkerFaceColor','y','MarkerSize',5)
text(x-xoff1,y+yoff,num2str(value1),'FontWeight',fontweight,'Fontsize',fontsize)
text(x-xoff2,y-yoff,['(',num2str(round(value2)),')'],'FontWeight',fontweight,'Fontsize',fontsize)
else %print blue dot and Inf
coor=d.getNodeCoordinates(node);
x=coor(1);y=coor(2);
text(x-xoff1,y+yoff,'Inf','FontWeight',fontweight,'Fontsize',fontsize)
text(x-xoff2,y-yoff,['(',num2str(round(value2)),')'],'FontWeight',fontweight,'Fontsize',fontsize)
end
end

%% Display scenario table
disp(T)
d.unload