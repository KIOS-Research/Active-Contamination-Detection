%% Active Contamination Detection - case studies
% Simulate networks with optimally placed sensors and assess contamination 
% detectability from all nodes using the Active (ACD) and Passive (PCD) 
% contamination detection scheme

%% Clear all variables and load toolkit
try 
d.unload
catch ERR
end 
clear all;fclose all; clear class; clc
addpath(genpath(pwd));
disp('Toolkits Loaded.');  

%% Select simulation scenario
[inpname,sensor_case,parallel] = enterScenario();
if strfind(inpname,'Hanoi') 
    Hanoi=1; M1=0;
elseif strfind(inpname,'M1')
    M1=1; Hanoi=0;
else
    error('Invalid network selection')
end
if Hanoi
    netstr = ['Hanoi_S',num2str(sensor_case)];
else
    netstr = ['M1_S',num2str(sensor_case)];
end

%% Load EPANET Input File and define sensor and contamination nodes
%%% Hanoi:
if Hanoi
d=epanet(inpname);
switch sensor_case
    case 1
    NsID = {'27'}; % define sensor nodes    
    case 2
    NsID = {'11','27'}; % define sensor nodes
    case 3
    NsID = {'11','27','21'}; % define sensor nodes
end
% valvesInd = d.getLinkIndex(d.getLinkNameID); % links that can be closed
valvesInd = d.getLinkIndex({'34','25','26','28','16','15','13','10','9',...
'3','19','20','23','21','29','24'}); % links that can be closed
rlb = 10; rub = 20; % Reservoir head discrete state bounds
end

%%% M1:
if M1
d=epanet(inpname);
switch sensor_case
    case 1
    NsID = {'26'}; % define sensor nodes
    case 2
    NsID = {'9','28'}; % define sensor nodes
    case 3
    NsID = {'9','28','36'}; % define sensor nodes        
end
valvesInd = d.getLinkIndex(d.getLinkNameID); % links that can be closed
rlb = 0; rub = 10; % Reservoir head discrete state bounds
end

%% Initialization parameters:
Ns = d.getNodeIndex(NsID); % set sensors
nl = double(d.getLinkCount); % number of links
nn = double(d.getNodeCount); % number of nodes
sim_time = d.getTimeSimulationDuration/3600; %hours
hyd_step = double(d.getTimeHydraulicStep)/3600; %hours
simSteps = sim_time/hyd_step; %steps
kdmax = sim_time / hyd_step ;   % define maximum time constraint in hours
Pthr=[20 150];                % define min/max pressure requirement (numerical isssue minus zero)
Tthr = 7;                      % define minimum detection threshold
uinit = d.getLinkInitialStatus; % get link initial status
lb=ones(1,nl); % all links initially open
ub=ones(1,nl); % all links initially open
lb(valvesInd)=0; % links that can be closed

%% GA options:
options = gaoptimset(@ga);
% options.MutationFcn = @mutationgaussian; % select mutation function
% options.PlotFcns = @gaplotbestf; % plot the fitness function
options.PopulationSize = 300; % population in each generation
% options.Generations=1; % set maximum generations
options.StallGenLimit=20; % generation stall limit
options.UseParallel=parallel; % parallel simulation
options.InitialPopulation=[uinit rlb];
%%%%%% GA Problem struct:
problem = struct(...
'fitnessfcn',@(u)GACostFunction(u,d,Ns,kdmax,Pthr,Tthr,rub,uinit,options.UseParallel,netstr),... %Fitness function (@ParticleTracking OR @GACostFunction)
'nvars',nl+1,... %Number of design variables
'Aineq',[],...
'bineq',[],...
'Aeq',[],...
'beq',[],...
'lb',[lb rlb],...
'ub',[ub rub],...
'nonlcon',[],... %Nonlinear constraint function
'intcon',[1:nl+1],... %Index vector for integer variables
'options',options,...%Options created with gaoptimset
'rngstate',[]); %state of the random number generator

%% ACD sensor detectability simulations
for Na = 1:d.getNodeCount % for all nodes being contaminated
%% Set nodes suspect for contamination and sensor nodes
d.setQualityType('trace',d.NodeNameID{Na})
d.setNodeInitialQuality(zeros(1,nn))
d.saveInputFile(d.BinTempfile)

%%% Parallel simulation settings
if options.UseParallel==1
delete(gcp('nocreate'))
parpool('AttachedFiles',{[d.LibEPANETpath,d.LibEPANET,'.h'],[d.LibEPANETpath,d.LibEPANET,'.dll']})
end

%%% Solve GA and save results
tic
[x,fval,exitflag,output] = ga(problem)
elapsed_time = toc;
[ cost, kd, valvesClosed, valvesClosedInd, pumpHead, PrPenalty, impact ] = ...
    extra_sim_results(x,d,Ns,kdmax,Pthr,Tthr,rub,uinit);
ResultsGA_node{Na}=struct(...
    'cost',cost,...
    'input',x,...
    'kd',kd,... 
    'valvesClosed',valvesClosed,...
    'valvesClosedInd',valvesClosedInd,...
    'pumpHead',pumpHead,... 
    'PrPenalty',PrPenalty,... 
    'impact',impact,...
    'elapsed_time',elapsed_time);
end

%% PCD sensor detectability simulations:
d.unload
d=epanet(inpname);
for Na = 1:d.getNodeCount
d.setQualityType('trace',d.NodeNameID{Na})
d.setNodeInitialQuality(zeros(1,nn))
pump = d.getNodeElevations(d.getNodeReservoirIndex)/10;
x=[uinit pump];
[ cost, kd, valvesClosed, valvesClosedInd, pumpHead, PrPenalty, impact ] = ...
    extra_sim_results(x,d,Ns,kdmax,Pthr,Tthr,rub,uinit);
ResultsDEF_node{Na}=struct(...
    'cost',cost,...
    'input',x,...
    'kd',kd,... 
    'valvesClosed',valvesClosed,...
    'valvesClosedInd',valvesClosedInd,...
    'pumpHead',pumpHead,... 
    'PrPenalty',PrPenalty,... 
    'impact',impact); 
end

%% Save results in "simulations" folder
clearvars ans cost elapsed_time fval exitflag impact kd Na PrPenalty pumpHead valvesClosed valvesClosedInd x
if Hanoi; netstr = ['Hanoi_S',num2str(sensor_case)]; else netstr = ['M1_S',num2str(sensor_case)]; end
FileName=['simulations\contamSim_',netstr,datestr(now, '_yyyy-mm-dd_HH-MM-SS')];
save(FileName)
d.unload