close all
clear
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

rng(1);

load Trunk_vary_n_data
load Random_matrix_adjustment_factor

for j = 1:length(ps)
    p = ps(j);
    fprintf('p = %d\n',p)

    if p <= 10
        dx = 2^p;
    elseif p > 10 && p <= 100
        dx = p^2;
    elseif p > 100 && p <= 1000
        dx = round(p^1.5);
    else
        dx = 10*p;
    end
    
    if p <= 5
        mtrys = [1:p ceil(p.^[1.5 2])];
    elseif p > 5 && p <= 10
        mtrys = ceil(p.^[1/4 1/2 3/4 1 1.5 2]);
    else
        mtrys = [ceil(p.^[1/4 1/2 3/4 1]) 10*p 20*p];
    end
    mtrys_rf = mtrys(mtrys<=p);
    
    if dx <= 5
        mtrys_rerf2 = 1:dx;
    else
        mtrys_rerf2 = ceil(dx.^[1/4 1/2 3/4 1]);
    end
      
    Classifiers = {'rerf2'};
    
    for i = 1:length(ns{j})
        fprintf('n = %d\n',ns{j}(i))

        for c = 1:length(Classifiers)
            fprintf('%s start\n',Classifiers{c})
            
            Params{i,j}.(Classifiers{c}).nTrees = 499;
            Params{i,j}.(Classifiers{c}).Stratified = true;
            Params{i,j}.(Classifiers{c}).NWorkers = 24;
            Params{i,j}.(Classifiers{c}).Rescale = 'off';
            Params{i,j}.(Classifiers{c}).mdiff = 'off';
            if strcmp(Classifiers{c},'rf')
                Params{i,j}.(Classifiers{c}).ForestMethod = 'rf';
                Params{i,j}.(Classifiers{c}).d = mtrys_rf;
            elseif strcmp(Classifiers{c},'rerfb')
                Params{i,j}.(Classifiers{c}).ForestMethod = 'sparse-binary';
                Params{i,j}.(Classifiers{c}).d = mtrys;
                for k = 1:length(Params{i,j}.(Classifiers{c}).d)
                    Params{i,j}.(Classifiers{c}).dprime(k) = ...
                        ceil(Params{i,j}.(Classifiers{c}).d(k)^(1/interp1(dims,...
                        slope,p)));
                end
            elseif strcmp(Classifiers{c},'rerfc')
                Params{i,j}.(Classifiers{c}).ForestMethod = 'sparse-continuous';
                Params{i,j}.(Classifiers{c}).d = mtrys;
                for k = 1:length(Params{i,j}.(Classifiers{c}).d)
                    Params{i,j}.(Classifiers{c}).dprime(k) = ...
                        ceil(Params{i,j}.(Classifiers{c}).d(k)^(1/interp1(dims,...
                        slope,p)));
                end
            elseif strcmp(Classifiers{c},'rerf2')
                Params{i,j}.(Classifiers{c}).ForestMethod = 'rerf2';
                Params{i,j}.(Classifiers{c}).d = mtrys_rerf2;
                Params{i,j}.(Classifiers{c}).dx = dx;
            elseif strcmp(Classifiers{c},'frc2') || strcmp(Classifiers{c},'frc3') || ...
                    strcmp(Classifiers{c},'frc4')
                Params{i,j}.(Classifiers{c}).ForestMethod = 'frc';
                Params{i,j}.(Classifiers{c}).d = mtrys;
            end
            if strcmp(Classifiers{c},'frc2')
                Params{i,j}.(Classifiers{c}).nmix = 2;
            elseif strcmp(Classifiers{c},'frc3')
                Params{i,j}.(Classifiers{c}).nmix = 3;
            elseif strcmp(Classifiers{c},'frc4')
                Params{i,j}.(Classifiers{c}).nmix = 4;
            end

            OOBError{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d));
            OOBAUC{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d));
            TrainTime{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d));
            Depth{i,j}.(Classifiers{c}) = NaN(ntrials,Params{i,j}.(Classifiers{c}).nTrees,length(Params{i,j}.(Classifiers{c}).d));
            NumNodes{i,j}.(Classifiers{c}) = NaN(ntrials,Params{i,j}.(Classifiers{c}).nTrees,length(Params{i,j}.(Classifiers{c}).d));
            NumSplitNodes{i,j}.(Classifiers{c}) = NaN(ntrials,Params{i,j}.(Classifiers{c}).nTrees,length(Params{i,j}.(Classifiers{c}).d));

            for trial = 1:ntrials
                fprintf('Trial %d\n',trial)

                % train classifier
                poolobj = gcp('nocreate');
                if isempty(poolobj)
                    parpool('local',Params{i,j}.(Classifiers{c}).NWorkers,...
                        'IdleTimeout',360);
                end

                [Forest,~,TrainTime{i,j}.(Classifiers{c})(trial,:)] = ...
                    RerF_train(Xtrain{i,j}(:,:,trial),...
                    Ytrain{i,j}(:,trial),Params{i,j}.(Classifiers{c}));

                % compute oob auc, oob error, and tree stats

                for k = 1:length(Forest)
                    Scores = rerf_oob_classprob(Forest{k},...
                        Xtrain{i,j}(:,:,trial),'last');
                    Predictions = predict_class(Scores,Forest{k}.classname);
                    OOBError{i,j}.(Classifiers{c})(trial,k) = ...
                        misclassification_rate(Predictions,Ytrain{i,j}(:,trial),...
                        false);
                    if size(Scores,2) > 2
                        Yb = binarize_labels(Ytrain{i,j}(:,trial),Forest{k}.classname);
                        [~,~,~,OOBAUC{i,j}.(Classifiers{c})(trial,k)] = ...
                            perfcurve(Yb(:),Scores(:),'1');
                    else
                        [~,~,~,OOBAUC{i,j}.(Classifiers{c})(trial,k)] = ...
                            perfcurve(Ytrain{i,j}(:,trial),Scores(:,2),'1');
                    end
                    Depth{i,j}.(Classifiers{c})(trial,:,k) = forest_depth(Forest{k})';
                    NN = NaN(1,Forest{k}.nTrees);
                    NS = NaN(1,Forest{k}.nTrees);
                    parfor kk = 1:Forest{k}.nTrees
                        NN(kk) = Forest{k}.Tree{kk}.numnodes;
                        NS(kk) = sum(Forest{k}.Tree{kk}.isbranch);
                    end
                    NumNodes{i,j}.(Classifiers{c})(trial,:,k) = NN;
                    NumSplitNodes{i,j}.(Classifiers{c})(trial,:,k) = NS;
                end
                
                %select best model for test predictions
                BestIdx = hp_optimize(OOBError{i,j}.(Classifiers{c})(trial,:),...
                    OOBAUC{i,j}.(Classifiers{c})(trial,:));
                if length(BestIdx)>1
                    BestIdx = BestIdx(end);
                end

                if strcmp(Forest{BestIdx}.Rescale,'off')
                    Scores = rerf_classprob(Forest{BestIdx},Xtest{j},'last');
                else
                    Scores = rerf_classprob(Forest{BestIdx},Xtest{j},...
                        'last',Xtrain{i,j}(:,:,trial));
                end
                Predictions = predict_class(Scores,Forest{BestIdx}.classname);
                TestError{i,j}.(Classifiers{c})(trial) = misclassification_rate(Predictions,...
                    Ytest{j},false);

                clear Forest

                save([rerfPath 'RandomerForest/Results/Trunk_vary_n_RerF2.mat'],'ps',...
                    'ns','Params','OOBError','OOBAUC','TestError',...
                    'TrainTime','Depth','NumNodes','NumSplitNodes')
            end
            fprintf('%s complete\n',Classifiers{c})
        end
    end   
end
