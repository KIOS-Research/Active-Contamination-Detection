%% Active Contamination Detection case study scenarios overall results
% Loads all simulation scenarios and creates a table with the aggregated
% overall results

%% Clear all and load paths
try 
d.unload
catch ERR
end 
fclose all; clear class; close all; clear all; clc
addpath(genpath(pwd));
disp('Toolkits Loaded.'); 

%% Choose simulation results:
for sim_numb = 1:6
% sim_num =[];
clc
sim_numb
dirName = [pwd,'\simulations\*.mat'];
% dirName = [pwd,'\simulations\Sim Server_1\*.mat'];
% dirName = [pwd,'\simulations\Sim PC_2\*.mat'];
Allinpnames = dir(dirName);
if isempty(sim_numb)
    disp(sprintf('\nChoose simulation scenario:'))
    for i=1:length(Allinpnames)
        disp([num2str(i),'. ', Allinpnames(i).name])
    end
    x = input(sprintf('\nEnter simulation scenario number: '));
else
    x = sim_numb;
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
    contamNodes{i,:} = d.getNodeNameID{i};
    contamNodesNum(i)=str2num(contamNodes{i,:});
    nodeCount(i) = double(d.getNodeCount);
end
varNames = {'Contam_Node','Det_Time_Def','Impact_Def','AFD_Solved','Pressure_Violation','Det_Time_AFD','Impact_AFD','Valves_Closed','Res_Head','Sim_Time'};
Tab = table(contamNodesNum',kdDEF',impactDEF',solutionGA',PrViolation',kdGA',impactGA',valvesClosedGA',pumpHead',time',...
    'VariableNames',varNames);
% T(find(T{:,5}>20 | T{:,6}>48),:)=[];
T{sim_numb} = sortrows(Tab,1);
d.unload
clearvars -except sim_num T nodeCount
end

%%
 for sim_numb=1:6
    if sim_numb<4
        resHead=100; 
        scLabel{sim_numb} = ['Hanoi S',num2str(sim_numb)];
    else
        resHead=0;
        scLabel{sim_numb} = ['M1 S',num2str(sim_numb-3)];
    end
    NodesDetectedDef(sim_numb) = (length(find(T{sim_numb}.Det_Time_Def<96))/nodeCount(sim_numb))*100;
    NodesDetectedAFD(sim_numb) = (length(find(T{sim_numb}.Det_Time_AFD<96))/nodeCount(sim_numb))*100;
    Det_Time_Def_Median(sim_numb) = median(T{sim_numb}.Det_Time_Def(T{sim_numb}.Det_Time_Def<96));
    Det_Time_AFD_Median(sim_numb) = median(T{sim_numb}.Det_Time_AFD(T{sim_numb}.Det_Time_AFD<96));
    Impact_Def_Median(sim_numb) = median(T{sim_numb}.Impact_Def);
    Impact_AFD_Median(sim_numb) = median(T{sim_numb}.Impact_AFD);
    valves_closed_AFD_Median(sim_numb) = median(T{sim_numb}.Valves_Closed(T{sim_numb}.Det_Time_AFD<96));
    if sim_numb<4; resHead=100; else resHead=0; end
    head_increase_AFD_Median(sim_numb) = median(T{sim_numb}.Res_Head-resHead);
 end
varNames = {'NDetPCD','NDetACD','kdPCDM','kdACDM','ImpPCDM','ImpACDM','valACDM','ResIncACDM'};
TabSmall = table(NodesDetectedDef',NodesDetectedAFD',Det_Time_Def_Median',Det_Time_AFD_Median',Impact_Def_Median',Impact_AFD_Median',valves_closed_AFD_Median',head_increase_AFD_Median','VariableNames',varNames,'RowNames',scLabel);
disp(TabSmall);
