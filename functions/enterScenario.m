function [inpname,dispname,sensor_case,parallel] = enterScenario()
%% choose a network to load from networks folder:
clc
dirName = [pwd,'\networks\*.inp'];
Allinpnames = dir(dirName);
disp(sprintf('\nChoose Water Network:'))
for i=1:length(Allinpnames)
    disp([num2str(i),'. ', Allinpnames(i).name])
end
x = input(sprintf('\nEnter Network Number: '));
if isempty(x)
    error('Invalid choice of network.')
end
inpname=['\networks\',Allinpnames(x).name];
dispname=Allinpnames(x).name(1:find(Allinpnames(x).name=='.')-1);
disp(['Loading network: ',dispname])

%% Choose sensor case:
disp(sprintf('\nChoose optimally-placed sensor number (1, 2 or 3):'))
y = input(sprintf('Enter Sensor Number: '));
if (isempty(y))||~ismember(y,[1,2,3])
    error('Wrong sensor number')
end
sensor_case = y;
fprintf(['Placing ',num2str(y),' sensors..\n'])

%% Choose parallel simulation:
disp(sprintf('\nParallel simulation? (yes=1 / no=0)'))
z = input(sprintf('Select (1 or 0): '));
if z==1
    parallel=1;
elseif z==0
    parallel=0;
else
    error('Wrong input.')
end


end

