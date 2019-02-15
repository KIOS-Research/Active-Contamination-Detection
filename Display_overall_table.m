%% Results Processing

%% Clear all and load paths
try 
d.unload
catch ERR
end 
fclose all; clear class; close all; clear all; clc
addpath(genpath(pwd));
disp('Toolkits Loaded.'); 

%% Choose simulation results:
for sim_num = 1:6
% sim_num =[];
clc
sim_num
dirName = [pwd,'\simulations\*.mat'];
% dirName = [pwd,'\simulations\Sim Server_1\*.mat'];
% dirName = [pwd,'\simulations\Sim PC_2\*.mat'];
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
if contains(inpname,'Hanoi')
inpname = '\networks\Hanoi.inp';
end
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
    contamNodes{i,:} = d.getNodeNameID{i};
    contamNodesNum(i)=str2num(contamNodes{i,:});
end

varNames = {'Contam_Node','Det_Time_Def','Impact_Def','AFD_Solved','Pressure_Violation',...
            'Det_Time_AFD','Impact_AFD','Valves_Closed','Res_Head','Sim_Time'};
Tab = table(contamNodesNum',kdDEF',impactDEF',solutionGA',PrViolation',kdGA',...
            impactGA',valvesClosedGA',pumpHead',time',...
            'VariableNames',varNames);
% T(find(T{:,5}>20 | T{:,6}>48),:)=[];
T{sim_num} = sortrows(Tab,1);
d.unload
clearvars -except sim_num T nodeCount
end

%%
for sim_num=1:6
    if sim_num<4
        scLabel{sim_num} = ['CY-DMA S',num2str(sim_num)];
        nodeCount=91;
    else
        scLabel{sim_num} = ['Hanoi S',num2str(sim_num-3)];
        nodeCount=32;
    end
    NodesDetectedDef(sim_num) = (length(find(T{sim_num}.Det_Time_Def<96))/nodeCount)*100;
    NodesDetectedAFD(sim_num) = (length(find(T{sim_num}.Det_Time_AFD<96))/nodeCount)*100;
    Det_Time_Def_Median(sim_num) = median(T{sim_num}.Det_Time_Def(T{sim_num}.Det_Time_Def<96));
    Det_Time_AFD_Median(sim_num) = median(T{sim_num}.Det_Time_AFD(T{sim_num}.Det_Time_AFD<96));
    Impact_Def_Median(sim_num) = median(T{sim_num}.Impact_Def);
    Impact_AFD_Median(sim_num) = median(T{sim_num}.Impact_AFD);
    valves_closed_AFD_Median(sim_num) = median(T{sim_num}.Valves_Closed(T{sim_num}.Det_Time_AFD<96));
    head_AFD_Median(sim_num) = median(T{sim_num}.Res_Head);
end

varNames = {'NDetDef','NDetAFD','kdDefM','kdAFDM','ImpDefM','ImpAFDM','valAFDM','ResHeadAFDM'};
TabSmall = table(NodesDetectedDef',NodesDetectedAFD',Det_Time_Def_Median',Det_Time_AFD_Median',...
                 Impact_Def_Median',Impact_AFD_Median',valves_closed_AFD_Median',...
                 head_AFD_Median','VariableNames',varNames,'RowNames',scLabel);
TabSmall = TabSmall([4:6,1:3],:)

