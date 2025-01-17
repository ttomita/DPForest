%% Plot benchmark classifier rank distributions

clear
close all
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);
rerfPath = '~/';

load('purple2green')
ColorMap = interpolate_colormap(ColorMap(round(size(ColorMap,1)/2):end,:),64,false);
LineWidth = 2;
MarkerSize = 8;
FontSize = .2;
axWidth = 2;
axHeight = 2;
cbWidth = axWidth;
cbHeight = 0.15;
axBottom = FontSize*5*ones(1,5);
axLeft = fliplr([FontSize*9+axHeight*4,FontSize*8+axHeight*3,...
    FontSize*7+axHeight*2,FontSize*6+axHeight,...
    FontSize*5]);
legWidth = axWidth*0.75;
legHeight = axHeight;
legLeft = axLeft(end) + axWidth;
legBottom = axBottom(end);
figWidth = legLeft + legWidth;
figHeight = axBottom(1) + axHeight + FontSize*2.5;

Classifiers = {'rf','rerf','rerfr','rerfz','rerfp','rerfpr','rerfpz',...
    'frc','frcr','frcz','rr_rf','rr_rfr','rr_rfz'};

inPath1 = [rerfPath 'RandomerForest/Results/2017.05.27/Benchmarks/'];
% inPath2 = '~/Benchmarks/Results/R/dat/Raw/';
contents = dir([inPath1 '*.mat']);

AbsoluteError = NaN(length(contents),length(Classifiers));
NormalizedRelativeError = NaN(length(contents),length(Classifiers)-1);
ChanceProb = NaN(length(contents),1);
nClasses = NaN(length(contents),1);
d = NaN(length(contents),length(Classifiers));
p = NaN(length(contents),1);
p_lowrank = NaN(length(contents),1);
lambda = cell(length(contents),1);   % eigenvalues of data matrix
ntrain = NaN(length(contents),1);
TraceNorm = NaN(length(contents),1);
PlotColor = NaN(length(contents),3);
iscont = NaN(length(contents),1);

DatasetNames = importdata('~/Benchmarks/Data/uci/Names.txt');

BinEdges = [-1,-0.2,-0.1,-0.05:0.01:-0.01,-0.005,0,0,0.005,0.01:0.01:0.05,0.1,0.2,1];

% S = load('~/Benchmarks/Results/Benchmark_untransformed.mat');

k = 1;

for i = 1:length(contents)
    fprintf('Dataset %d\n',i)
    Dataset = strsplit(contents(i).name,'_2017_05_27');
    Dataset = Dataset{1};
    DatasetIdx = find(strcmp(Dataset,DatasetNames));
    
    Name = strsplit(Dataset,'_task');
    Name = Name{1};
    Name = strrep(Name,'_','-');
    if ~isempty(strfind(Name,'frc')) || ~isempty(strfind(Name,'rerfp'))
        continue
    end
    
    % contains binary features?
    fid = fopen(['~/Benchmarks/Data/uci/binary/' Name '.bin']);
    hasbin = ~isnumeric(fgetl(fid));
    fclose(fid);
    
    % contains categorical features?
    fid = fopen(['~/Benchmarks/Data/uci/categorical/' Name '.cat']);
    hascat = ~isnumeric(fgetl(fid));
    fclose(fid);

    % contains ordinal features?
    fid = fopen(['~/Benchmarks/Data/uci/ordinal/' Name '.ord']);
    hasord = ~isnumeric(fgetl(fid));
    fclose(fid);

    load([inPath1 contents(i).name])

    isComplete = true;

    for c = 1:length(Classifiers)
        cl = Classifiers{c};
        if ~strcmp(cl,'xgb')
            if ~isfield(TestError,cl)
                isComplete = false;
            end
%         else
%             if ~exist([inPath2 Dataset '_testError.dat'])
%                 isComplete = false;
%             end
        end
    end

    if isComplete
        TrainSet = dlmread(['~/Benchmarks/Data/uci/processed/' Dataset '.train.csv']);
        TestSet = dlmread(['~/Benchmarks/Data/uci/processed/' Dataset '.test.csv']);
        [ntrain(k),p(k)] = size(TrainSet(:,1:end-1));
        [coeff,score,lambda{k}] = pca([TrainSet(:,1:end-1);TestSet(:,1:end-1)]);
        TraceNorm(k) = sum(sqrt(lambda{k}));
        VarCutoff = 0.9;
        AboveCutoff = find(cumsum(lambda{k})/sum(lambda{k}) >= 0.9);
        p_lowrank(k) = AboveCutoff(1);
        nClasses(k) = length(unique(TestSet(:,end)));
        ClassCounts = histcounts(TestSet(:,end),nClasses(k));
        ChanceProb(k) = 1 - max(ClassCounts)/sum(ClassCounts);
        if hasbin || hascat || hasord
            iscont(k) = 0;
        else
            iscont(k) = 1;
        end

        for c = 1:length(Classifiers)
            cl = Classifiers{c};
            if ~strcmp(cl,'xgb')
                BI = hp_optimize(OOBError.(cl)(end,1:length(Params.(cl).d)),...
                    OOBAUC.(cl)(end,1:length(Params.(cl).d)));
                BI = BI(randperm(length(BI),1));
                AbsoluteError(k,c) = TestError.(cl)(BI);
                d(k,c) = Params.(cl).d(BI);
%             else
%                 AbsoluteError(k,c) = dlmread([inPath2 Dataset '_testError.dat']);
            end
            
%             if ~strcmp(cl,'xgb')
%                 BI = hp_optimize(OOBError.(cl)(end,1:length(Params.(cl).d)),...
%                     OOBAUC.(cl)(end,1:length(Params.(cl).d)));
%                 BI = BI(end);
%                 AbsoluteError(k,c) = TestError.(cl)(BI);
%                 d(k,c) = Params.(cl).d(BI);
%             else
%                 AbsoluteError(k,c) = dlmread([inPath2 Dataset '_testError.dat']);
%             end
            if c > 1
                NormalizedRelativeError(k,c-1) = (AbsoluteError(k,c)-AbsoluteError(k,1))/ChanceProb(k);
            end
        end
        k = k + 1;
    end
end

AbsoluteError(all(isnan(NormalizedRelativeError),2),:) = [];
NormalizedRelativeError(all(isnan(NormalizedRelativeError),2),:) = [];
d(all(isnan(d),2),:) = [];
p(isnan(p)) = [];
p_lowrank(isnan(p_lowrank)) = [];
ntrain(isnan(ntrain)) = [];
TraceNorm(isnan(TraceNorm)) = [];
lambda(isnan(p_lowrank)) = [];
nClasses(isnan(nClasses)) = [];
PlotColor(all(isnan(PlotColor),2),:) = [];
iscont(isnan(iscont)) = [];
iscont = logical(iscont);

%%% continuous datasets %%%
Counts = zeros(length(BinEdges)-1,length(Classifiers)-1);

for c = 1:length(Classifiers)-1
    Counts(:,c) = histcounts(NormalizedRelativeError(:,c),BinEdges)';
end
Counts(length(BinEdges)/2,:) = sum(NormalizedRelativeError==0);
Counts(length(BinEdges)/2+1,:) = Counts(length(BinEdges)/2+1,:) - Counts(length(BinEdges)/2,:);
Fractions = Counts./repmat(sum(Counts),size(Counts,1),1);

ax = axes;
YTLabel = {'RerF','RerF(r)','RerF(z)','RerFp','RerFp(r)','RerFp(z)','F-RC','Frank','F-RC(z)','RR-RF','RR-RF(r)','RR-RF(z)'};

h = heatmap(Fractions',cellstr(num2str(BinEdges')),YTLabel,ColorMap,...
    true,'horizontal');
xlabel({'Normalized Error';'Relative to RF'})
title(sprintf('%d Real-Valued Benchmark Datasets',sum(iscont)))

% cb = colorbar;
% cb.Location = 'southoutside';
% xlh = xlabel(cb,'Fraction of Datasets');
% cb.Ticks = [];
% cb.Units = 'inches';
% cb.Position = [cbLeft(t) cbBottom(t) cbWidth cbHeight];
% cb.Box = 'off';
% cb.FontSize = 16;
% xlh.Position = [0.2237 -0.5 0];
% h.FontSize = FontSize;
hold on
for c = 2:length(Classifiers)-1
    plot(h.XLim,[c-0.5,c-0.5],'-k','LineWidth',LineWidth)
end
ax.XTick = [0.5,10,19.5];
ax.XTickLabel = {'-1';'0';'1'};
ax.XTickLabelRotation = 0;
ax.TickLength = [0 0];
ax.LineWidth = LineWidth;

save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/PAMI_fig7_error_heatmap_benchmark_updated'],{'fig','pdf','png'})

%%% continuous datasets %%%
Counts = zeros(length(BinEdges)-1,length(Classifiers)-1);

for c = 1:length(Classifiers)-1
    Counts(:,c) = histcounts(NormalizedRelativeError(iscont,c),BinEdges)';
end
Counts(length(BinEdges)/2,:) = sum(NormalizedRelativeError(iscont,:)==0);
Counts(length(BinEdges)/2+1,:) = Counts(length(BinEdges)/2+1,:) - Counts(length(BinEdges)/2,:);
Fractions = Counts./repmat(sum(Counts),size(Counts,1),1);

ax = axes;
YTLabel = {'RerF','RerF(r)','RerF(z)','RerFp','RerFp(r)','RerFp(z)','F-RC','Frank','F-RC(z)','RR-RF','RR-RF(r)','RR-RF(z)'};

h = heatmap(Fractions',cellstr(num2str(BinEdges')),YTLabel,ColorMap,...
    true,'horizontal');
xlabel({'Normalized Error';'Relative to RF'})
title(sprintf('%d Real-Valued Benchmark Datasets',sum(iscont)))

% cb = colorbar;
% cb.Location = 'southoutside';
% xlh = xlabel(cb,'Fraction of Datasets');
% cb.Ticks = [];
% cb.Units = 'inches';
% cb.Position = [cbLeft(t) cbBottom(t) cbWidth cbHeight];
% cb.Box = 'off';
% cb.FontSize = 16;
% xlh.Position = [0.2237 -0.5 0];
% h.FontSize = FontSize;
hold on
for c = 2:length(Classifiers)-1
    plot(h.XLim,[c-0.5,c-0.5],'-k','LineWidth',LineWidth)
end
ax.XTick = [0.5,10,19.5];
ax.XTickLabel = {'-1';'0';'1'};
ax.XTickLabelRotation = 0;
ax.TickLength = [0 0];
ax.LineWidth = LineWidth;

save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/PAMI_fig7_error_heatmap_benchmark_real_updated'],{'fig','pdf','png'})

%%% categorical datasets %%%

Counts = zeros(length(BinEdges)-1,length(Classifiers)-1);

for c = 1:length(Classifiers)-1
    Counts(:,c) = histcounts(NormalizedRelativeError(~iscont,c),BinEdges)';
end
Counts(length(BinEdges)/2,:) = sum(NormalizedRelativeError(~iscont,:)==0);
Counts(length(BinEdges)/2+1,:) = Counts(length(BinEdges)/2+1,:) - Counts(length(BinEdges)/2,:);
Fractions = Counts./repmat(sum(Counts),size(Counts,1),1);

figure;
ax = axes;
YTLabel = {'RerF','RerF(r)','RerF(z)','RerFp','RerFp(r)','RerFp(z)','F-RC','Frank','F-RC(z)','RR-RF','RR-RF(r)','RR-RF(z)'};

h = heatmap(Fractions',cellstr(num2str(BinEdges')),YTLabel,ColorMap,...
    true,'horizontal');
xlabel({'Normalized Error';'Relative to RF'})
title(sprintf('%d Nominal Benchmark Datasets',sum(~iscont)))

% cb = colorbar;
% cb.Location = 'southoutside';
% xlh = xlabel(cb,'Fraction of Datasets');
% cb.Ticks = [];
% cb.Units = 'inches';
% cb.Position = [cbLeft(t) cbBottom(t) cbWidth cbHeight];
% cb.Box = 'off';
% cb.FontSize = 16;
% xlh.Position = [0.2237 -0.5 0];
% h.FontSize = FontSize;
hold on
for c = 2:length(Classifiers)-1
    plot(h.XLim,[c-0.5,c-0.5],'-k','LineWidth',LineWidth)
end
ax.XTick = [0.5,10,19.5];
ax.XTickLabel = {'-1';'0';'1'};
ax.XTickLabelRotation = 0;
ax.TickLength = [0 0];
ax.LineWidth = LineWidth;

save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/PAMI_fig7_error_heatmap_benchmark_nominal_updated'],{'fig','pdf','png'})