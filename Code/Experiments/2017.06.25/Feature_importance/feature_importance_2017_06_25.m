% train and test classifiers on cancer classification dataset

close all
clear
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);
if isempty(rerfPath)
    rerfPath = '~/';
end

rng(1);

Classifiers = {'rerfr','rerfpr'};

TrainFile = '/scratch/groups/jvogels3/tyler/Data/Table_S8_clean.csv';
OutFile = [rerfPath 'RandomerForest/Results/2017.06.25/Feature_importance/Cancer_feature_importance_gini_2017_06_25.mat'];

rng(1);

Xtrain = dlmread(TrainFile,',')';
Ytrain = cellstr(num2str(Xtrain(:,end)));
Xtrain(:,end) = [];

[ntrain,p] = size(Xtrain);

Labels = unique(Ytrain);
nClasses = length(Labels);

% mtrys = ceil(p.^[1/2 1]);
mtrys = ceil(p.^[1/4 1/2 3/4 1 2]);
mtrys_rf = mtrys(mtrys<=p);

for c = 1:length(Classifiers)
    cl = Classifiers{c};
    fprintf('%s start\n',cl)

    Params.(cl).nTrees = 500;
    Params.(cl).Stratified = true;
    Params.(cl).NWorkers = 20;
    if strcmp(cl,'rerfr') || strcmp(cl,'rr_rfr')
        Params.(cl).Rescale = 'rank';
    else
        Params.(cl).Rescale = 'off';
    end
    Params.(cl).mdiff = 'off';
    if strcmp(cl,'rf')
        Params.(cl).ForestMethod = 'rf';
        Params.(cl).d = mtrys_rf;
    elseif strcmp(cl,'rerf') || strcmp(cl,'rerfr')
        Params.(cl).ForestMethod = 'rerf';
        Params.(cl).RandomMatrix = 'binary';
        Params.(cl).d = mtrys;
        Params.(cl).rho = 1/p;
    elseif strcmp(cl,'rerfb') || strcmp(cl,'rerfbr')
        Params.(cl).ForestMethod = 'rerf';
        Params.(cl).RandomMatrix = 'uniform-nnzs-binary';
        Params.(cl).d = mtrys;
        Params.(cl).nmix = 1:5;
        Params.(cl).rho = 1/p;
    elseif strcmp(cl,'rerfc') || strcmp(cl,'rerfcr')
        Params.(cl).ForestMethod = 'rerf';
        Params.(cl).RandomMatrix = 'uniform-nnzs-continuous';
        Params.(cl).d = mtrys;
        Params.(cl).nmix = 1:5;
        Params.(cl).rho = 1/p;
    elseif strcmp(cl,'rerfp') || strcmp(cl,'rerfpr')
        Params.(cl).ForestMethod = 'rerf';
        Params.(cl).RandomMatrix = 'poisson';
        Params.(cl).d = mtrys;
        Params.(cl).lambda = 3;            
    elseif strcmp(cl,'frc') || strcmp(cl,'frcr')
        Params.(cl).ForestMethod = 'rerf';
        Params.(cl).RandomMatrix = 'frc';
        Params.(cl).d = mtrys;
        Params.(cl).L = 2:5;       
    elseif strcmp(cl,'rr_rf') || strcmp(cl,'rr_rfr')
        Params.(cl).ForestMethod = 'rf';   
        Params.(cl).Rotate = true;
        Params.(cl).d = mtrys_rf;
    end
    
    if strcmp(Params.(cl).ForestMethod,'rf')
        OOBError.(cl) = NaN(1,length(Params.(cl).d));
        OOBAUC.(cl) = NaN(1,length(Params.(cl).d));
        TrainTime.(cl) = NaN(1,length(Params.(cl).d));
        Depth.(cl) = NaN(Params.(cl).nTrees,length(Params.(cl).d));
        NumNodes.(cl) = NaN(Params.(cl).nTrees,length(Params.(cl).d));
        NumSplitNodes.(cl) = NaN(Params.(cl).nTrees,length(Params.(cl).d));
    else
        if strcmp(Params.(cl).RandomMatrix,'frc')
            OOBError.(cl) = NaN(1,length(Params.(cl).d)*length(Params.(cl).L));
            OOBAUC.(cl) = NaN(1,length(Params.(cl).d)*length(Params.(cl).L));
            TrainTime.(cl) = NaN(1,length(Params.(cl).d)*length(Params.(cl).L));
            Depth.(cl) = NaN(Params.(cl).nTrees,length(Params.(cl).d)*length(Params.(cl).L));
            NumNodes.(cl) = NaN(Params.(cl).nTrees,length(Params.(cl).d)*length(Params.(cl).L));
            NumSplitNodes.(cl) = NaN(Params.(cl).nTrees,length(Params.(cl).d)*length(Params.(cl).L));
        elseif strcmp(Params.(cl).RandomMatrix,'poisson')
            OOBError.(cl) = NaN(1,length(Params.(cl).d)*length(Params.(cl).lambda));
            OOBAUC.(cl) = NaN(1,length(Params.(cl).d)*length(Params.(cl).lambda));
            TrainTime.(cl) = NaN(1,length(Params.(cl).d)*length(Params.(cl).lambda));
            Depth.(cl) = NaN(Params.(cl).nTrees,length(Params.(cl).d)*length(Params.(cl).lambda));
            NumNodes.(cl) = NaN(Params.(cl).nTrees,length(Params.(cl).d)*length(Params.(cl).lambda));
            NumSplitNodes.(cl) = NaN(Params.(cl).nTrees,length(Params.(cl).d)*length(Params.(cl).lambda));
        else
            OOBError.(cl) = NaN(1,length(Params.(cl).d)*length(Params.(cl).rho));
            OOBAUC.(cl) = NaN(1,length(Params.(cl).d)*length(Params.(cl).rho));
            TrainTime.(cl) = NaN(1,length(Params.(cl).d)*length(Params.(cl).rho));
            Depth.(cl) = NaN(Params.(cl).nTrees,length(Params.(cl).d)*length(Params.(cl).rho));
            NumNodes.(cl) = NaN(Params.(cl).nTrees,length(Params.(cl).d)*length(Params.(cl).rho));
            NumSplitNodes.(cl) = NaN(Params.(cl).nTrees,length(Params.(cl).d)*length(Params.(cl).rho));
        end
    end

    % train classifier
    poolobj = gcp('nocreate');
    if isempty(poolobj)
        parpool('local',Params.(cl).NWorkers,...
            'IdleTimeout',360);
    end

    [Forest,~,TrainTime.(cl)] = ...
        RerF_train(Xtrain,Ytrain,Params.(cl));

    fprintf('Training complete\n')

    % compute oob auc, oob error, and tree stats

    for k = 1:length(Forest)
        fprintf('Computing metrics for forest %d of %d\n',k,length(Forest))
        Labels = Forest{k}.classname;
        nClasses = length(Labels);
        Scores = rerf_oob_classprob(Forest{k},...
            Xtrain,'last');
        Predictions = predict_class(Scores,Labels);
        OOBError.(cl)(k) = ...
            misclassification_rate(Predictions,Ytrain,...
        false);        
        if nClasses > 2
            Yb = binarize_labels(Ytrain,Labels);
            [~,~,~,OOBAUC.(cl)(k)] = ... 
                perfcurve(Yb(:),Scores(:),'1');
        else
            [~,~,~,OOBAUC.(cl)(k)] = ...
                perfcurve(Ytrain,Scores(:,2),'1');
        end
        Depth.(cl)(:,k) = forest_depth(Forest{k})';
        NN = NaN(Forest{k}.nTrees,1);
        NS = NaN(Forest{k}.nTrees,1);
        Trees = Forest{k}.Tree;
        parfor kk = 1:Forest{k}.nTrees
            NN(kk) = Trees{kk}.numnodes;
            NS(kk) = sum(Trees{kk}.isbranch);
        end
        NumNodes.(cl)(:,k) = NN;
        NumSplitNodes.(cl)(:,k) = NS;
    end

    % select best model based on OOB errors and AUCs
    BI = hp_optimize([],OOBAUC.(cl)(end,:));
    BestIdx.(cl) = BI(randperm(length(BI),1));

    tic;
    [importance.(cl),features.(cl)] = feature_importance(Forest{BestIdx.(cl)},'gini');
    Time.importance.(cl) = toc;
    
    save(OutFile,'Params','OOBError','OOBAUC','TrainTime','Depth',...
        'NumNodes','NumSplitNodes','BestIdx','importance','features','Time')
end  