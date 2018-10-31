function [ cost, kd, valvesClosed, valvesClosedInd, pumpHead, PrPenalty, impact ] = extra_sim_results(u,d,Ns,kdmax,Pthr,Tthr,rub,uinit)
%EXTRA_SIM_RESULTS
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

%% Solve Hydraulics and check for negative pressures
H=d.getComputedHydraulicTimeSeries('Pressure','Demand'); %compute pressures
D = H.Demand';
P = H.Pressure';
P(resInd,:)=[];
clc
if any(any(P<Pthr(1))) || any(any(P>Pthr(2)))
    disp('Pressure Constraints Violation')
end
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
% solve trace simulation
Tr = d.getComputedQualityTimeSeries('quality'); % compute trace
Tr = Tr.NodeQuality';

% find detection time kd
if length(Ns)>1
kd = min(find(any(Tr(Ns,:)>Tthr)));
else
kd = min(find((Tr(Ns,:)>Tthr)));
end

% check if a solution was found and if it is in the defined time range
if (isempty(kd)) %|| kd>kdmax)
    kd=2*kdmax;
    disp('Solution not found')    
end

%% Calculate pump head, valve closed and impact:
PumpCost = pump/rub; % normalized in [0,1]
pumpHead= pump*10; % normalized in [0,1]
ValveCost = norm(uinit-u(1:end-1),1)/length(uinit); % normalized in [0,1]
valvesClosed = norm(uinit-u(1:end-1),1); % normalized in [0,1]
valvesClosedInd = find(u(1:end-1)==0);
% Impact as contaminated water consumed until time of detection:
if kd>kdmax; kdet=kdmax; else kdet=kd; end
impact = D(:,1:kdet);
impact = sum(impact(Tr(:,1:kdet)>Tthr & D(:,1:kdet)>0)); 

%% Calculate cost:
cost = kd + PumpCost + ValveCost + 100*PrPenalty;

end

