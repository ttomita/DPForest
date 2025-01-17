% Generate 2d spherical Gaussian binary classification datasets

close all
clear
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

rng(1);

ps = [2,4];                         % numbers of dimensions
ns = [5 10,100,1000];      % numbers of train samples for ps(1)
ntest = 10000;                  % number of test samples
ntrials = 100;                   % number of replicate experiments
Class = [0;1];

% generate data
for j = 1:length(ps)
    p = ps(j);
    fprintf('p = %d\n',p)
    
    %orthogonal decision surface
    fprintf('orthogonal\n')
    mu0 = [-1 zeros(1,p-1)];
    mu1 = [1 zeros(1,p-1)];
    Mu = cat(1,mu0,mu1);
    Sigma = eye(p);
    obj = gmdistribution(Mu,Sigma);
    for i = 1:length(ns)
        ntrain = ns(i);
        fprintf('n = %d\n',ntrain)
        for trial = 1:ntrials
            if ntrain <= 10
                go = true;
                while go
                    [Xtrain,idx] = random(obj,ntrain);
                    Ytrain = Class(idx);
                    if mean(Ytrain) >= 0.4 && mean(Ytrain) <= 0.6
                        go = false;
                    end
                end
            else
                [Xtrain,idx] = random(obj,ntrain);
                Ytrain = Class(idx);
            end
            dlmwrite(sprintf('~/R/Data/Gaussian/dat/Train/Gaussian_orthogonal_train_set_n%d_p%d_trial%d.dat',ntrain,p,trial),...
                [Xtrain,Ytrain],'delimiter',',','precision','%0.15f');
        end
    end
    [Xtest,idx] = random(obj,ntest);
    Ytest = Class(idx);
    dlmwrite(sprintf('~/R/Data/Gaussian/dat/Test/Gaussian_orthogonal_test_set_p%d.dat',p),...
    [Xtest,Ytest],'delimiter',',','precision','%0.15f');

    ClassPosteriors = posterior(obj,Xtest);
    dlmwrite(sprintf('~/R/Data/Gaussian/dat/Test/Gaussian_orthogonal_test_set_posteriors_p%d.dat',p),...
    ClassPosteriors,'delimiter',',','precision','%0.15f');
    
    %oblique decision surface
    fprintf('oblique\n')
    mu0 = -1*ones(1,p)/norm(ones(1,p));
    mu1 = ones(1,p)/norm(ones(1,p));
    Mu = cat(1,mu0,mu1);
    Sigma = eye(p);
    obj = gmdistribution(Mu,Sigma);
    for i = 1:length(ns)
        ntrain = ns(i);
        fprintf('n = %d\n',ntrain)
        for trial = 1:ntrials
            if ntrain <= 10
                go = true;
                while go
                    [Xtrain,idx] = random(obj,ntrain);
                    Ytrain = Class(idx);
                    if mean(Ytrain) >= 0.4 && mean(Ytrain) <= 0.6
                        go = false;
                    end
                end
            else
                [Xtrain,idx] = random(obj,ntrain);
                Ytrain = Class(idx);
            end
            dlmwrite(sprintf('~/R/Data/Gaussian/dat/Train/Gaussian_oblique_train_set_n%d_p%d_trial%d.dat',ntrain,p,trial),...
                [Xtrain,Ytrain],'delimiter',',','precision','%0.15f');
        end
    end
    [Xtest,idx] = random(obj,ntest);
    Ytest = Class(idx);
    dlmwrite(sprintf('~/R/Data/Gaussian/dat/Test/Gaussian_oblique_test_set_p%d.dat',p),...
    [Xtest,Ytest],'delimiter',',','precision','%0.15f');

    ClassPosteriors = posterior(obj,Xtest);
    dlmwrite(sprintf('~/R/Data/Gaussian/dat/Test/Gaussian_oblique_test_set_posteriors_p%d.dat',p),...
    ClassPosteriors,'delimiter',',','precision','%0.15f');

end