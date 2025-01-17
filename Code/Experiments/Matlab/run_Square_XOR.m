close all
clear
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

rng(1);

n = 500;
d = 2;
ntrials = 10;

xmin = -1;
xmax = 1;
ymin = xmin;
ymax = xmax;
npoints = 50;
[xgv,ygv] = meshgrid(linspace(xmin,xmax,npoints),linspace(ymin,ymax,npoints));
Xpost{1} = xgv(:);
Ypost{1} = ygv(:);
Zpost{1} = zeros(npoints^2,d-2);
xmin = -sqrt(2);
xmax = sqrt(2);
ymin = xmin;
ymax = xmax;
npoints = 50;
[xgv,ygv] = meshgrid(linspace(xmin,xmax,npoints),linspace(ymin,ymax,npoints));
Xpost{2} = xgv(:);
Ypost{2} = ygv(:);
Zpost{2} = zeros(npoints^2,d-2);

ntrees = 500;
NWorkers = 2;
Stratified = true;
Classifiers = {'rf' 'rerf'};

Params.rf.RandomForest = true;
Params.rf.SparseMethod = '';
Params.rf.Rotate = false;
Params.rf.nmix = [];

Params.rerf.RandomForest = false;
Params.rerf.SparseMethod = 'sparse';
Params.rerf.Rotate = false;
Params.rerf.nmix = [];

for c = 1:length(Classifiers)
    Params.(Classifiers{c}).ntrees = ntrees;
    Params.(Classifiers{c}).Stratified = Stratified;
    Params.(Classifiers{c}).NWorkers = NWorkers;
end

for trial = 1:ntrials  
    x1 = rand(n/4,2);
    x2 = [-rand(n/4,1),rand(n/4,1)];
    x3 = -rand(n/4,2);
    x4 = [rand(n/4,1),-rand(n/4,1)];
    XX = [x1;x2;x3;x4];
    Y.train = cellstr(num2str(double((XX(:,1)<0 & XX(:,2)>0)...
        | (XX(:,1)>0 & XX(:,2)<0))));
    theta = pi/4;
    Xrot = XX*[cos(theta),sin(theta);-sin(theta),cos(theta)];
    X.train{1} = XX;
    X.train{2} = Xrot;

    x1 = rand(n/4,2);
    x2 = [-rand(n/4,1),rand(n/4,1)];
    x3 = -rand(n/4,2);
    x4 = [rand(n/4,1),-rand(n/4,1)];
    XX = [x1;x2;x3;x4];
    Y.test = cellstr(num2str(double((XX(:,1)<0 & XX(:,2)>0)...
        | (XX(:,1)>0 & XX(:,2)<0))));
    theta = pi/4;
    Xrot = XX*[cos(theta),sin(theta);-sin(theta),cos(theta)];
    X.test{1} = XX;
    X.test{2} = Xrot;

    for i = 1:length(X.train)    
        for c = 1:length(Classifiers)

            cl = Classifiers{c};

            if Params.(cl).RandomForest
                if d <= 5
                    Params.(cl).mtry{i} = 1:d;
                else
                    Params.(cl).mtry{i} = ceil(d.^[0 1/4 1/2 3/4 1]);
                end
            else
                if d <= 5
                    Params.(cl).mtry{i} = [1:d ceil(d.^[1.5 2])];
                elseif d > 5 && d <= 10
                    Params.(cl).mtry{i} = ceil(d.^[0 1/4 1/2 3/4 1 1.5 2]);
                else
                    Params.(cl).mtry{i} = [ceil(d.^[0 1/4 1/2 3/4 1]) 5*d 10*d];
                end
            end

            if isempty(Params.(cl).nmix) || Params.(cl).nmix <= d
                for j = 1:length(Params.(cl).mtry{i})
                    Forest.(cl){i}{trial,j} = rpclassificationforest(Params.(cl).ntrees,...
                        X.train{i},Y.train,...
                        'RandomForest',Params.(cl).RandomForest,...
                        'sparsemethod',Params.(cl).SparseMethod,...
                        'nvartosample',Params.(cl).mtry{i}(j),...
                        'nmix',Params.(cl).nmix,...
                        'rotate',Params.(cl).Rotate,...
                        'Stratified',Stratified,...
                        'NWorkers',NWorkers);

                    Predictions = predict(Forest.(cl){i}{trial,j},X.test{i});
                    GE.(cl){i}(trial,j) = misclassification_rate(Predictions,Y.test);
                end
                [~,MinIdx.(cl){i}(trial)] = min(GE.(cl){i}(trial,:));
                Posteriors.(cl){i}(:,:,trial) =...
                    rerf_classprob(Forest.(cl){i}{trial,MinIdx.(cl){i}(trial)},...
                    [Xpost{i},Ypost{i}]);
            else
               GE.(cl){i} = [];
            end
        end
    end
end

for i = 1:length(X.train)
    for c = 1:length(Classifiers)
        cl = Classifiers{c};
        SEM.(cl){i} = std(GE.(cl){i})/sqrt(ntrials);
        GE.(cl){i} = mean(GE.(cl){i});
        Posteriors.(cl){i} = mean(Posteriors.(cl){i},3);
    end
end


% subplot(1,2,1)
% hold on
% errorbar(1:2,M.rf{1},SEM.rf{1})
% errorbar(1:4,M.rerf{1},SEM.rerf{1})
% title('XOR')
% xlabel('mtry')
% ylabel('misclassification rate')
% legend(Classifiers)
% subplot(1,2,2)
% hold on
% errorbar(1:2,M.rf{2},SEM.rf{2})
% errorbar(1:4,M.rerf{2},SEM.rerf{2})
% title('Rotated XOR')
% xlabel('mtry')
% ylabel('misclassification rate')
% legend(Classifiers)

save([rerfPath 'RandomerForest/Results/Square_XOR_posteriors_npoints_50.mat'],...
    'Posteriors','SEM','GE','Xpost','Ypost','Zpost')