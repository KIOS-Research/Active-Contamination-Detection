function cost = GACostFunction(u,d,Ns,kdmax,Pthr,Tthr,rub,uinit,parSim,netstr)
%% GA cost function ***v3
% Impact as the objective to be minimized.
% same input for all time steps

%% Parallel simulation settings
if parSim==1
spmd
    if ~libisloaded(d.LibEPANET)
    loadlibrary(d.LibEPANET,[d.LibEPANETpath,d.LibEPANET])
    d.loadEPANETFile(d.BinTempfile);
    end
end
end

%% Apply input
%%% Apply valve input: 
valve = u(1:end-1);
d.setLinkInitialStatus(valve)
% d.getLinkInitialStatus
%%% Appply reservoir head input:
pump = u(end);
resInd = d.getNodeReservoirIndex;
elev = d.getNodeElevations;
elev(resInd)=pump*10;
d.setNodeElevations(elev);
%%% Display current input:
% disp(u)

%% Solve Hydraulics and check for negative pressures
H=d.getComputedHydraulicTimeSeries('Pressure','Demand'); %compute pressures
D = H.Demand';
P = H.Pressure';
P(resInd,:)=[];
clc
% if any(any(P<Pthr(1))) || any(any(P>Pthr(2)))
%     disp('Pressure Constraints Violation')
% end
%%%Minimum Pressure Penalty:
PrPenaltyL = max(Pthr(1)-P(find(P<Pthr(1))));
if isempty(PrPenaltyL) 
    PrPenaltyL=0; 
end
%%%Maximum Pressure Penalty:
PrPenaltyH = max(P(find(P>Pthr(2)))-Pthr(2));
if isempty(PrPenaltyH) 
    PrPenaltyH=0; 
end
%%% Total Pressure Penalty:
PrPenalty = PrPenaltyL + PrPenaltyH;
    
%% Compute contaminant trace and find detection time kd
% solve trace simulation:
Tr = d.getComputedQualityTimeSeries('quality'); % compute trace
Tr = Tr.NodeQuality';
% find detection time kd:
if length(Ns)>1
kd = min(find(any(Tr(Ns,:)>Tthr)));
else
kd = min(find((Tr(Ns,:)>Tthr)));
end
% check if a solution was found and if it is in the defined time range:
if (isempty(kd)) %|| kd>kdmax)
    kd=2*kdmax;
%     disp('Solution not found')    
end

%% Calculate pump, valve cost and impact:
PumpCost = pump/rub; % normalized in [0,1]
ValveCost = norm(uinit-u(1:end-1),1)/length(uinit); % normalized in [0,1]
% Impact as contaminated water consumed until time of detection:
if kd>kdmax; kdet=kdmax; else kdet=kd; end
impact = D(:,1:kdet);
impact = sum(impact(Tr(:,1:kdet)>Tthr & D(:,1:kdet)>0)); 
tot_dem = sum(sum(D(D>0)));
impact_norm=impact/tot_dem; %impact normalized in [0 1]

%% Calculate cost:
cost = 100*PrPenalty + 1000*impact_norm + (PumpCost + ValveCost)/2;
clc
disp(['GA fitness function cost: ',num2str(cost)])
disp(['Scenario: ',netstr])
end






