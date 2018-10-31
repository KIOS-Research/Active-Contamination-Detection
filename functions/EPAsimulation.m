function [Q, H, CL] = EPAsimulation(inpname)
%load network
d=epanet(inpname);
th = double(d.getTimeHydraulicStep); 
tq = double(d.getTimeQualityStep);

if th==tq
%%Run simulation and return results
allParameters=d.getComputedTimeSeries;
Q = allParameters.Flow;
H = allParameters.Head;
CL = allParameters.NodeQuality;
else
d.setTimeReportingStep(th);
allParameters=d.getComputedTimeSeries;
Q = allParameters.Flow;
H = allParameters.Head;
d.setTimeReportingStep(tq);
allParameters=d.getComputedTimeSeries;
CL = allParameters.NodeQuality;
end

d.unload
end