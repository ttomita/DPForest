close all
clear
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

rng(1);

ns = [100 300 1000 3000];
Y = loadMNISTLabels('train-labels-idx1-ubyte');
Ystr = cellstr(num2str(Y));
Labels = [3,7,8];

ntrials = 10;

for k = 1:length(ns)
        nTrain = ns(k);
    
    for trial = 1:ntrials

        Idx = [];
        for l = 1:length(Labels)
            Idx = [Idx randsample(find(Y==Labels(l)),round(nTrain/length(Labels)))'];
        end
        TrainIdx{k}(trial,:) = Idx;
    end
end

save([rerfPath 'RandomerForest/Data/mnist_378_data.mat'],'ns','ntrials',...
    'TrainIdx')