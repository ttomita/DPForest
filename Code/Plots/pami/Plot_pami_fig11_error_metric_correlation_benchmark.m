%% Plot benchmark classifier rank distributions

clear
close all
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);
if isempty(rerfPath)
    rerfPath = '~/';
end

load('purple2green')
Colors.cat = ColorMap(3,:);
Colors.cont= ColorMap(9,:);
LineWidth = 2;
MarkerSize = 10;
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

% fig = figure;
% fig.Units = 'inches';
% fig.PaperUnits = 'inches';
% fig.Position = [0 0 figWidth figHeight];
% fig.PaperPosition = [0 0 figWidth figHeight];
% fig.PaperSize = [figWidth figHeight];

Classifiers = {'rf','rerf','frc','rr_rf'};

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
pcat = NaN(length(contents),1);
missingness = NaN(length(contents),1);

DatasetNames = importdata('~/Benchmarks/Data/uci/Names.txt');

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
        
        % contains binary features?
        fid = fopen(['~/Benchmarks/Data/uci/binary/' Name '.bin']);
        fline = fgetl(fid);
        fclose(fid);
        hasbin = ~isnumeric(fline);
        if hasbin
            pcat(k) = length(strsplit(fline,','));
        else
            pcat(k) = 0;
        end

        % contains categorical features?
        fid = fopen(['~/Benchmarks/Data/uci/categorical/' Name '.cat']);
        fline = fgetl(fid);
        fclose(fid);
        hascat = ~isnumeric(fline);
        if hascat
            pcat(k) = length(strsplit(fline,',')) + pcat(k);
        end

        % contains ordinal features?
        fid = fopen(['~/Benchmarks/Data/uci/ordinal/' Name '.ord']);
        hasord = ~isnumeric(fgetl(fid));
        fclose(fid);
        
        if hasbin || hascat || hasord
            PlotColor(k,:) = Colors.cat;
            iscont(k) = 0;
        else
            PlotColor(k,:) = Colors.cont;
            iscont(k) = 1;
        end
        
        % get percent missing
        fid = fopen(['~/Benchmarks/Data/uci/missingness/' Name '.missingness']);
        missingness(k) = str2num(fgetl(fid));
        fclose(fid);
        
        if hasbin || hascat || hasord
            PlotColor(k,:) = Colors.cat;
            iscont(k) = 0;
        else
            PlotColor(k,:) = Colors.cont;
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
pcat(isnan(pcat)) = [];
missingness(isnan(missingness)) = [];

% [~,srtidx] = sort(NormalizedRelativeError(:,1));
% Top15 = srtidx(1:15);
% threshold = 1;
% RerFIsBetter = NormalizedRelativeError(:,1)<threshold;

% ran=range(NormalizedRelativeError(:,1)); %finding range of data
% min_val=min(NormalizedRelativeError(:,1));%finding maximum value of data
% max_val=max(NormalizedRelativeError(:,1));%finding minimum value of data
% y=floor(((NormalizedRelativeError(:,1)-min_val)/ran)*63)+1; 
% plotColor=zeros(size(NormalizedRelativeError,1),3);
% pp=cool(64);
% for i=1:size(NormalizedRelativeError,1)
%   a=y(i);
%   plotColor(i,:)=pp(a,:);
% end

% Compute area under scree plots

AUC = zeros(size(NormalizedRelativeError,1),1);
for i = 1:size(NormalizedRelativeError,1)
%     axh(i) = subplot(5,3,i);
    csum = cumsum(lambda{i});
%     if NormalizedRelativeError(i,1) < 0
%         plotColor = ColorMap(9,:);
%     elseif NormalizedRelativeError(i,1) == 0
%         plotColor = 'k';
%     else
%         plotColor = ColorMap(3,:);
%     end
%     plot((1:length(lambda{i}))/length(lambda{i}),csum/csum(end),...
%         'LineWidth',1.5,'Color',plotColor(i,:))
%     xlabel('no. PCs retained (normalized)')
%     ylabel('fraction of explained variance')
%     axis square
%     axh(i).FontSize = 6;
    AUC(i) = trapz((1:length(lambda{i}))/length(lambda{i}),csum/csum(end));
end

% figure;
% k = 1;
% ax(k) = axes;
% hold on
% % for c = 2
% %     cl = Classifiers{c};
% %     plot(log10(p),NormalizedRelativeError(:,c-1),'.','MarkerSize',MarkerSize,...
% %         'Color',Colors.(cl),'MarkerSize',14)
% % end
% 
% % plot continuous
% plot(log10(p(iscont)),NormalizedRelativeError(iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cont)
% logx = log10(p);
% linmod = fitlm(logx(iscont),NormalizedRelativeError(iscont,1),'linear');
% beta.cont = linmod.Coefficients.Estimate;
% Rsq.cont = linmod.Rsquared.Ordinary;
% yfit = beta.cont(1) + beta.cont(2)*logx;
% hold on
% plot(logx,yfit,'k','LineWidth',2)
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % plot categorical
% plot(log10(p(~iscont)),NormalizedRelativeError(~iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cat)
% linmod = fitlm(logx(~iscont),NormalizedRelativeError(~iscont,1),'linear');
% beta.cat = linmod.Coefficients.Estimate;
% Rsq.cat = linmod.Rsquared.Ordinary;
% yfit = beta.cat(1) + beta.cat(2)*logx;
% hold on
% plot(logx,yfit,'m','LineWidth',2);
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % ax(k).XScale = 'log';
% ax(k).Box = 'off';
% xlabel('log_{10}p')
% ylabel('Normalized Error of RerF Relative to RF')
% title('Updated Benchmark Datasets')
% l = legend('Numeric',sprintf('Fit on numeric (R^2 = %0.3f)',Rsq.cont),sprintf('Slope = %0.3f',beta.cont(2)),'Nominal',sprintf('Fit on nominal (R^2 = %0.3f)',Rsq.cat),sprintf('Slope = %0.3f',beta.cat(2)));
% l.Location = 'southwest';
% % l.Box = 'off';
% save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/pami_benchmark_p_vs_error'],{'fig','pdf','png'})
% 
% figure;
% k = 2;
% ax(k) = axes;
% hold on
% % for c = 2
% %     cl = Classifiers{c};
% %     plot(log10(d(:,c)./p),NormalizedRelativeError(:,c-1),'.','MarkerSize',MarkerSize,...
% %         'Color',Colors.(cl),'MarkerSize',14)
% % end
% 
% % plot continuous
% plot(log10(d(iscont,2)./p(iscont)),NormalizedRelativeError(iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cont)
% logx = log10(d(:,2)./p);
% linmod = fitlm(logx(iscont),NormalizedRelativeError(iscont,1),'linear');
% beta.cont = linmod.Coefficients.Estimate;
% Rsq.cont = linmod.Rsquared.Ordinary;
% yfit = beta.cont(1) + beta.cont(2)*logx;
% hold on
% plot(logx,yfit,'k','LineWidth',2)
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % plot categorical
% plot(log10(d(~iscont,2)./p(~iscont)),NormalizedRelativeError(~iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cat)
% linmod = fitlm(logx(~iscont),NormalizedRelativeError(~iscont,1),'linear');
% beta.cat = linmod.Coefficients.Estimate;
% Rsq.cat = linmod.Rsquared.Ordinary;
% yfit = beta.cat(1) + beta.cat(2)*logx;
% hold on
% plot(logx,yfit,'m','LineWidth',2);
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % ax(k).XScale = 'log';
% ax(k).Box = 'off';
% xlabel('log_{10}(d/p)')
% ylabel('Normalized Error of RerF Relative to RF')
% l = legend('Numeric',sprintf('Fit on numeric (R^2 = %0.3f)',Rsq.cont),sprintf('Slope = %0.3f',beta.cont(2)),'Nominal',sprintf('Fit on nominal (R^2 = %0.3f)',Rsq.cat),sprintf('Slope = %0.3f',beta.cat(2)));
% l.Location = 'southwest';
% % l.Box = 'off';
% title('Updated Benchmark Datasets')
% save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/pami_benchmark_d_over_p_vs_error'],{'fig','pdf','png'})
% 
% figure;
% k = 3;
% ax(k) = axes;
% hold on
% % for c = 2
% %     cl = Classifiers{c};
% %     plot(log10(ntrain),NormalizedRelativeError(:,c-1),'.','MarkerSize',MarkerSize,...
% %         'Color',Colors.(cl),'MarkerSize',14)
% % end
% 
% % plot continuous
% plot(log10(ntrain(iscont)),NormalizedRelativeError(iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cont)
% logx = log10(ntrain);
% linmod = fitlm(logx(iscont),NormalizedRelativeError(iscont,1),'linear');
% beta.cont = linmod.Coefficients.Estimate;
% Rsq.cont = linmod.Rsquared.Ordinary;
% yfit = beta.cont(1) + beta.cont(2)*logx;
% hold on
% plot(logx,yfit,'k','LineWidth',2)
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % plot categorical
% plot(log10(ntrain(~iscont)),NormalizedRelativeError(~iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cat)
% linmod = fitlm(logx(~iscont),NormalizedRelativeError(~iscont,1),'linear');
% beta.cat = linmod.Coefficients.Estimate;
% Rsq.cat = linmod.Rsquared.Ordinary;
% yfit = beta.cat(1) + beta.cat(2)*logx;
% hold on
% plot(logx,yfit,'m','LineWidth',2);
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % ax(k).XScale = 'log';
% ax(k).Box = 'off';
% xlabel('log_{10}(n_{train})')
% ylabel('Normalized Error of RerF Relative to RF')
% l = legend('Numeric',sprintf('Fit on numeric (R^2 = %0.3f)',Rsq.cont),sprintf('Slope = %0.3f',beta.cont(2)),'Nominal',sprintf('Fit on nominal (R^2 = %0.3f)',Rsq.cat),sprintf('Slope = %0.3f',beta.cat(2)));
% l.Location = 'southwest';
% % l.Box = 'off';
% title('Updated Benchmark Datasets')
% save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/pami_benchmark_ntrain_vs_error'],{'fig','pdf','png'})
% 
% figure;
% k = 4;
% ax(k) = axes;
% hold on
% % for c = 2
% %     cl = Classifiers{c};
% %     plot(log10(p./ntrain),NormalizedRelativeError(:,c-1),'.','MarkerSize',MarkerSize,...
% %         'Color',Colors.(cl),'MarkerSize',14)
% % end
% 
% % plot continuous
% plot(log10(p(iscont)./ntrain(iscont)),NormalizedRelativeError(iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cont)
% logx = log10(p./ntrain);
% linmod = fitlm(logx(iscont),NormalizedRelativeError(iscont,1),'linear');
% beta.cont = linmod.Coefficients.Estimate;
% Rsq.cont = linmod.Rsquared.Ordinary;
% yfit = beta.cont(1) + beta.cont(2)*logx;
% hold on
% plot(logx,yfit,'k','LineWidth',2)
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % plot categorical
% plot(log10(p(~iscont)./ntrain(~iscont)),NormalizedRelativeError(~iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cat)
% linmod = fitlm(logx(~iscont),NormalizedRelativeError(~iscont,1),'linear');
% beta.cat = linmod.Coefficients.Estimate;
% Rsq.cat = linmod.Rsquared.Ordinary;
% yfit = beta.cat(1) + beta.cat(2)*logx;
% hold on
% plot(logx,yfit,'m','LineWidth',2);
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % ax(k).XScale = 'log';
% ax(k).Box = 'off';
% xlabel('log_{10}(p/n_{train})')
% ylabel('Normalized Error of RerF Relative to RF')
% l = legend('Numeric',sprintf('Fit on numeric (R^2 = %0.3f)',Rsq.cont),sprintf('Slope = %0.3f',beta.cont(2)),'Nominal',sprintf('Fit on nominal (R^2 = %0.3f)',Rsq.cat),sprintf('Slope = %0.3f',beta.cat(2)));
% l.Location = 'southwest';
% % l.Box = 'off';
% title('Updated Benchmark Datasets')
% save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/pami_benchmark_p_over_ntrain_vs_error'],{'fig','pdf','png'})
% 
% figure;
% k = 5;
% ax(k) = axes;
% hold on
% % for c = 2
% %     cl = Classifiers{c};
% %     plot(log10(p_lowrank),NormalizedRelativeError(:,c-1),'.','MarkerSize',MarkerSize,...
% %         'Color',Colors.(cl),'MarkerSize',14)
% % end
% 
% % plot continuous
% plot(log10(p_lowrank(iscont)),NormalizedRelativeError(iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cont)
% logx = log10(p_lowrank);
% linmod = fitlm(logx(iscont),NormalizedRelativeError(iscont,1),'linear');
% beta.cont = linmod.Coefficients.Estimate;
% Rsq.cont = linmod.Rsquared.Ordinary;
% yfit = beta.cont(1) + beta.cont(2)*logx;
% hold on
% plot(logx,yfit,'k','LineWidth',2)
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % plot categorical
% plot(log10(p_lowrank(~iscont)),NormalizedRelativeError(~iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cat)
% linmod = fitlm(logx(~iscont),NormalizedRelativeError(~iscont,1),'linear');
% beta.cat = linmod.Coefficients.Estimate;
% Rsq.cat = linmod.Rsquared.Ordinary;
% yfit = beta.cat(1) + beta.cat(2)*logx;
% hold on
% plot(logx,yfit,'m','LineWidth',2);
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % ax(k).XScale = 'log';
% ax(k).Box = 'off';
% xlabel('log_{10}p^*')
% ylabel('Normalized Error of RerF Relative to RF')
% l = legend('Numeric',sprintf('Fit on numeric (R^2 = %0.3f)',Rsq.cont),sprintf('Slope = %0.3f',beta.cont(2)),'Nominal',sprintf('Fit on nominal (R^2 = %0.3f)',Rsq.cat),sprintf('Slope = %0.3f',beta.cat(2)));
% l.Location = 'southwest';
% % l.Box = 'off';
% title('Updated Benchmark Datasets')
% save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/pami_benchmark_pstar_vs_error'],{'fig','pdf','png'})
% 
% figure;
% k = 6;
% ax(k) = axes;
% hold on
% % for c = 2
% %     cl = Classifiers{c};
% %     plot(log10(p_lowrank./p),NormalizedRelativeError(:,c-1),'.','MarkerSize',MarkerSize,...
% %         'Color',Colors.(cl),'MarkerSize',14)
% % end
% 
% % plot continuous
% plot(log10(p_lowrank(iscont)./p(iscont)),NormalizedRelativeError(iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cont)
% logx = log10(p_lowrank./p);
% linmod = fitlm(logx(iscont),NormalizedRelativeError(iscont,1),'linear');
% beta.cont = linmod.Coefficients.Estimate;
% Rsq.cont = linmod.Rsquared.Ordinary;
% yfit = beta.cont(1) + beta.cont(2)*logx;
% hold on
% plot(logx,yfit,'k','LineWidth',2)
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % plot categorical
% plot(log10(p_lowrank(~iscont)./p(~iscont)),NormalizedRelativeError(~iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cat)
% linmod = fitlm(logx(~iscont),NormalizedRelativeError(~iscont,1),'linear');
% beta.cat = linmod.Coefficients.Estimate;
% Rsq.cat = linmod.Rsquared.Ordinary;
% yfit = beta.cat(1) + beta.cat(2)*logx;
% hold on
% plot(logx,yfit,'m','LineWidth',2);
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % ax(k).XScale = 'log';
% ax(k).Box = 'off';
% xlabel('log_{10}(p^*/p)')
% ylabel('Normalized Error of RerF Relative to RF')
% l = legend('Numeric',sprintf('Fit on numeric (R^2 = %0.3f)',Rsq.cont),sprintf('Slope = %0.3f',beta.cont(2)),'Nominal',sprintf('Fit on nominal (R^2 = %0.3f)',Rsq.cat),sprintf('Slope = %0.3f',beta.cat(2)));
% l.Location = 'southwest';
% % l.Box = 'off';
% title('Updated Benchmark Datasets')
% save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/pami_benchmark_pstar_over_p_vs_error'],{'fig','pdf','png'})
% 
% figure;
% k = 7;
% ax(k) = axes;
% hold on
% % for c = 2
% %     cl = Classifiers{c};
% %     plot(log10(TraceNorm),NormalizedRelativeError(:,c-1),'.','MarkerSize',MarkerSize,...
% %         'Color',Colors.(cl),'MarkerSize',14)
% % end
% 
% % plot continuous
% plot(log10(TraceNorm(iscont)),NormalizedRelativeError(iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cont)
% logx = log10(TraceNorm);
% linmod = fitlm(logx(iscont),NormalizedRelativeError(iscont,1),'linear');
% beta.cont = linmod.Coefficients.Estimate;
% Rsq.cont = linmod.Rsquared.Ordinary;
% yfit = beta.cont(1) + beta.cont(2)*logx;
% hold on
% plot(logx,yfit,'k','LineWidth',2)
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % plot categorical
% plot(log10(TraceNorm(~iscont)),NormalizedRelativeError(~iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cat)
% linmod = fitlm(logx(~iscont),NormalizedRelativeError(~iscont,1),'linear');
% beta.cat = linmod.Coefficients.Estimate;
% Rsq.cat = linmod.Rsquared.Ordinary;
% yfit = beta.cat(1) + beta.cat(2)*logx;
% hold on
% plot(logx,yfit,'m','LineWidth',2);
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % ax(k).XScale = 'log';
% ax(k).Box = 'off';
% xlabel('log_{10}(Trace-norm)')
% ylabel('Normalized Error of RerF Relative to RF')
% l = legend('Numeric',sprintf('Fit on numeric (R^2 = %0.3f)',Rsq.cont),sprintf('Slope = %0.3f',beta.cont(2)),'Nominal',sprintf('Fit on nominal (R^2 = %0.3f)',Rsq.cat),sprintf('Slope = %0.3f',beta.cat(2)));
% l.Location = 'southwest';
% % l.Box = 'off';
% title('Updated Benchmark Datasets')
% save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/pami_benchmark_trace_norm_vs_error'],{'fig','pdf','png'})
% 
% figure;
% k = 8;
% ax(k) = axes;
% hold on
% % for c = 2
% %     cl = Classifiers{c};
% %     plot(log10(nClasses),NormalizedRelativeError(:,c-1),'.','MarkerSize',MarkerSize,...
% %         'Color',Colors.(cl),'MarkerSize',14)
% % end
% 
% % plot continuous
% plot(log10(nClasses(iscont)),NormalizedRelativeError(iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cont)
% logx = log10(nClasses);
% linmod = fitlm(logx(iscont),NormalizedRelativeError(iscont,1),'linear');
% beta.cont = linmod.Coefficients.Estimate;
% Rsq.cont = linmod.Rsquared.Ordinary;
% yfit = beta.cont(1) + beta.cont(2)*logx;
% hold on
% plot(logx,yfit,'k','LineWidth',2)
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % plot categorical
% plot(log10(nClasses(~iscont)),NormalizedRelativeError(~iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cat)
% linmod = fitlm(logx(~iscont),NormalizedRelativeError(~iscont,1),'linear');
% beta.cat = linmod.Coefficients.Estimate;
% Rsq.cat = linmod.Rsquared.Ordinary;
% yfit = beta.cat(1) + beta.cat(2)*logx;
% hold on
% plot(logx,yfit,'m','LineWidth',2);
% plot(logx,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % ax(k).XScale = 'log';
% ax(k).Box = 'off';
% xlabel('log_{10}(Number of Classes)')
% ylabel('Normalized Error of RerF Relative to RF')
% l = legend('Numeric',sprintf('Fit on numeric (R^2 = %0.3f)',Rsq.cont),sprintf('Slope = %0.3f',beta.cont(2)),'Nominal',sprintf('Fit on nominal (R^2 = %0.3f)',Rsq.cat),sprintf('Slope = %0.3f',beta.cat(2)));
% l.Location = 'southwest';
% % l.Box = 'off';
% title('Updated Benchmark Datasets')
% save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/pami_benchmark_nclasses_vs_error'],{'fig','pdf','png'})
% 
% figure;
% k = 9;
% ax(k) = axes;
% hold on
% % for c = 2
% %     cl = Classifiers{c};
% %     plot(AUC,NormalizedRelativeError(:,c-1),'.','MarkerSize',MarkerSize,...
% %         'Color',Colors.(cl),'MarkerSize',14)
% % end
% 
% % plot continuous
% plot(AUC(iscont),NormalizedRelativeError(iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cont)
% linmod = fitlm(AUC(iscont),NormalizedRelativeError(iscont,1),'linear');
% beta.cont = linmod.Coefficients.Estimate;
% Rsq.cont = linmod.Rsquared.Ordinary;
% yfit = beta.cont(1) + beta.cont(2)*AUC;
% hold on
% plot(AUC,yfit,'k','LineWidth',2)
% plot(AUC,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % plot categorical
% plot(AUC(~iscont),NormalizedRelativeError(~iscont,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cat)
% linmod = fitlm(AUC(~iscont),NormalizedRelativeError(~iscont,1),'linear');
% beta.cat = linmod.Coefficients.Estimate;
% Rsq.cat = linmod.Rsquared.Ordinary;
% yfit = beta.cat(1) + beta.cat(2)*AUC;
% hold on
% plot(AUC,yfit,'m','LineWidth',2);
% plot(AUC,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % ax(k).XScale = 'log';
% ax(k).Box = 'off';
% xlabel('Area under scree')
% ylabel('Normalized Error of RerF Relative to RF')
% l = legend('Numeric',sprintf('Fit on numeric (R^2 = %0.3f)',Rsq.cont),sprintf('Slope = %0.3f',beta.cont(2)),'Nominal',sprintf('Fit on nominal (R^2 = %0.3f)',Rsq.cat),sprintf('Slope = %0.3f',beta.cat(2)));
% l.Location = 'southwest';
% % l.Box = 'off';
% title('Updated Benchmark Datasets')
% save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/pami_benchmark_scree_vs_error'],{'fig','pdf','png'})
% 
% figure;
% k = 10;
% ax(k) = axes;
% hold on
% fcat = pcat./p;
% plot(fcat,NormalizedRelativeError(:,1),'.','MarkerSize',MarkerSize,...
%     'Color',Colors.cont)
% linmod = fitlm(fcat,NormalizedRelativeError(:,1),'linear');
% beta = linmod.Coefficients.Estimate;
% Rsq = linmod.Rsquared.Ordinary;
% yfit = beta(1) + beta(2)*fcat;
% hold on
% plot(fcat,yfit,'k','LineWidth',2)
% plot(fcat,yfit,'LineStyle','none','Marker','none','Visible','off');
% 
% % ax(k).XScale = 'log';
% ax(k).Box = 'off';
% xlabel('p_{cat}/p')
% ylabel('Normalized Error of RerF Relative to RF')
% l = legend('RerF',sprintf('Fit (R^2 = %0.3f)',Rsq),sprintf('Slope = %0.3f',beta(2)));
% l.Location = 'southeast';
% % l.Box = 'off';
% title('Updated Benchmark Datasets')
% save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/pami_benchmark_categorical_vs_error'],{'fig','pdf','png'})

figure;
k = 11;
ax(k) = axes;
hold on
plot(missingness,NormalizedRelativeError(:,1),'.','MarkerSize',MarkerSize,...
    'Color',Colors.cont)
linmod = fitlm(missingness,NormalizedRelativeError(:,1),'linear');
beta = linmod.Coefficients.Estimate;
Rsq = linmod.Rsquared.Ordinary;
yfit = beta(1) + beta(2)*missingness;
hold on
plot(missingness,yfit,'k','LineWidth',2)
plot(missingness,yfit,'LineStyle','none','Marker','none','Visible','off');

% ax(k).XScale = 'log';
ax(k).Box = 'off';
xlabel('Percent Missing')
ylabel('Normalized Error of RerF Relative to RF')
l = legend('RerF',sprintf('Fit (R^2 = %0.3f)',Rsq),sprintf('Slope = %0.3f',beta(2)));
l.Location = 'southeast';
% l.Box = 'off';
title('Updated Benchmark Datasets')
save_fig(gcf,[rerfPath 'RandomerForest/Figures/pami/pami_benchmark_missingness_vs_error'],{'fig','pdf','png'})