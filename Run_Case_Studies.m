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
[inpname,dispname,sensor_case,parallel] = enterScenario();
netnum = find([contains(inpname,'Hanoi')...
               contains(inpname,'CY_DMA')]);
           
%% Load EPANET Input File and define sensor and contamination nodes
switch netnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 1 %%% Hanoi:
    netstr = [dispname,'_S',num2str(sensor_case)];
    d=epanet(inpname);
    switch sensor_case
        case 1
        NsID = {'27'}; % define sensor nodes    
        case 2
        NsID = {'11','27'}; % define sensor nodes
        case 3
        NsID = {'11','27','21'}; % define sensor nodes
    end
    PopulationSize = 500;
    StallGenLimit=20;
    Pthr=[20 150]; % define min/max pressure requirement (numerical isssue minus zero)
    valvesInd = double(d.getLinkIndex(d.getLinkNameID)); % links that can be closed
    rlb = 6; rub = 20; % Reservoir head discrete state bounds
    contaminationNodesInd = 1:d.getNodeCount;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    case 2 %%% CY_DMA:
    netstr = [dispname,'_S',num2str(sensor_case)];
    d=epanet(inpname);
    switch sensor_case
        case 1
        NsID = {'41'}; % define sensor nodes
        case 2
        NsID = {'41','90'}; % define sensor nodes
        case 3
        NsID = {'41','48','90'}; % define sensor nodes        
    end
    PopulationSize = 500;
    StallGenLimit=20;
    Pthr=[20 90]; % define min/max pressure requirement (numerical isssue minus zero)
%     valvesInd =find(d.getLinkLength>50); % links that can be closed
    valvesInd = double(d.getLinkIndex(d.getLinkNameID)); % links that can be closed
    valvesInd([1 10 12 14 17 23 31 44 65 67 69 86 90 101 106 116])=[]; %links that can't be closed 
    rlb = 3; rub = 8; % Reservoir head discrete state bounds
    contaminationNodesInd = 1:d.getNodeCount;
    contaminationNodesInd([2 4 6 12 14 22 24 29 49 54 58 70 70 72 81 83])=[]; % nodes that won't be simulated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

%% Initialization parameters:
Ns = d.getNodeIndex(NsID); % set sensors
nl = double(d.getLinkCount); % number of links
nn = double(d.getNodeCount); % number of nodes
sim_time = d.getTimeSimulationDuration/3600; %hours
hyd_step = double(d.getTimeHydraulicStep)/3600; %hours
simSteps = sim_time/hyd_step; %steps
kdmax = sim_time / hyd_step ;   % define maximum time constraint in hours
Tthr = 7;                      % define minimum detection threshold
uinit = d.getLinkInitialStatus; % get link initial status
lb=ones(1,nl); % all links initially open
ub=ones(1,nl); % all links initially open
lb(valvesInd)=0; % links that can be closed

%% GA options:
options = gaoptimset(@ga);
% options.MutationFcn = @mutationgaussian; % select mutation function
% options.PlotFcns = @gaplotbestf; % plot the fitness function
options.PopulationSize = PopulationSize; % population in each generation
% options.Generations=1; % set maximum generations
options.StallGenLimit=StallGenLimit; % generation stall limit
options.UseParallel=parallel; % parallel simulation
options.InitialPopulation=[uinit rub];
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
ind = 1;
for Na = contaminationNodesInd % for all nodes being contaminated
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
ResultsGA_node{ind}=struct(...
    'node_ind',Na,...
    'cost',cost,...
    'input',x,...
    'kd',kd,... 
    'valvesClosed',valvesClosed,...
    'valvesClosedInd',valvesClosedInd,...
    'pumpHead',pumpHead,... 
    'PrPenalty',PrPenalty,... 
    'impact',impact,...
    'elapsed_time',elapsed_time);
ind=ind+1;
end

%% PCD sensor detectability simulations:
d.unload
d=epanet(inpname);
ind = 1;
for Na = contaminationNodesInd
d.setQualityType('trace',d.NodeNameID{Na})
d.setNodeInitialQuality(zeros(1,nn))
pump = d.getNodeElevations(d.getNodeReservoirIndex)/10;
x=[uinit pump];
[ cost, kd, valvesClosed, valvesClosedInd, pumpHead, PrPenalty, impact ] = ...
    extra_sim_results(x,d,Ns,kdmax,Pthr,Tthr,rub,uinit);
ResultsDEF_node{ind}=struct(...
    'node_ind',Na,...
    'cost',cost,...
    'input',x,...
    'kd',kd,... 
    'valvesClosed',valvesClosed,...
    'valvesClosedInd',valvesClosedInd,...
    'pumpHead',pumpHead,... 
    'PrPenalty',PrPenalty,... 
    'impact',impact); 
ind=ind+1;
end

%% Save results in "simulations" folder
clearvars ans cost elapsed_time fval exitflag impact kd Na PrPenalty pumpHead valvesClosed valvesClosedInd x
FileName=['simulations\contamSim_',netstr,datestr(now, '_yyyy-mm-dd_HH-MM-SS')];
save(FileName)
d.unload