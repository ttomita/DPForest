%% Plot Sparse Parity and Trunk

clear
close all
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

Colors.rerf = 'c';
Colors.rerf2 = 'g';
LineStyles.rerf = '-';
LineStyles.rerf2 = '-';
LineWidth = 2;
MarkerSize = 12;
FontSize = .2;
axWidth = 1.5;
axHeight = 1.5;
axLeft = repmat([FontSize*4,FontSize*8+axWidth],1,3);
axBottom = [...
    (FontSize*9+axHeight*2)*ones(1,2),(FontSize*6+axHeight)*ones(1,2),...
    FontSize*3*ones(1,2)];
legWidth = axWidth;
legHeight = axHeight;
legLeft = axLeft(end) + axWidth + FontSize;
legBottom = axBottom(5);
figWidth = axLeft(end) + axWidth + FontSize;
figHeight = axBottom(1) + axHeight + FontSize*1.5;

fig = figure;
fig.Units = 'inches';
fig.PaperUnits = 'inches';
fig.Position = [0 0 figWidth figHeight];
fig.PaperPosition = [0 0 figWidth figHeight];
fig.PaperSize = [figWidth figHeight];

%% Plot Sparse Parity

ax = axes;

n = 100;
p = 2;
p_prime = min(3,p);

X = rand(n,p)*2 - 1;
Y = mod(sum(X(:,1:p_prime)>0,2),2);

plot(X(Y==0,1),X(Y==0,2),'b.',X(Y==1,1),X(Y==1,2),'r.','MarkerSize',MarkerSize)

title('(A)','Units','normalized','Position',[0.025 .975],'HorizontalAlignment','left','VerticalAlignment','top')
text(0.5,1.05,'Sparse Parity','FontSize',16,'FontWeight','bold','Units',...
    'normalized','HorizontalAlignment','center','VerticalAlignment'...
    ,'bottom')
xlabel('X_1')
ylabel('X_2')
[lh1,objh1] = legend('Class 1','Class 2');
lh1.Location = 'southwest';
lh1.Box = 'off';
lh1.FontSize = 11;
objh1(4).XData = 0.75*(objh1(3).XData(2) - objh1(3).XData(1)) + objh1(3).XData(1);
objh1(6).XData = 0.75*(objh1(5).XData(2) - objh1(5).XData(1)) + objh1(5).XData(1);
ax.LineWidth = LineWidth;
ax.FontUnits = 'inches';
ax.FontSize = FontSize;
ax.Units = 'inches';
ax.Position = [axLeft(1) axBottom(1) axWidth axHeight];
ax.Box = 'off';
ax.XLim = [-2 2];
ax.YLim = [-2 2];
ax.XTick = [-2 0 2];
ax.YTick = [-2 0 2];
ax.XTickLabel = {'-2';'0';'2'};
ax.YTickLabel = {'-2';'0';'2'};

runSims = false;

if runSims
    run_Sparse_parity
else
    load Sparse_parity_partial
end

ax = axes;

for i = 1:length(TestError)
    Classifiers = fieldnames(TestError{i});
    Classifiers(~ismember(Classifiers,{'rerf','rerf2'})) = [];
    for j = 1:length(Classifiers)
        ntrials = length(TestError{i}.(Classifiers{j}).Untransformed(:,end));
        for trial = 1:ntrials
            BestIdx = hp_optimize(OOBError{i}.(Classifiers{j}).Untransformed(trial,:,end),...
                OOBAUC{i}.(Classifiers{j}).Untransformed(trial,:,end));
            if length(BestIdx) > 1
                BestIdx = BestIdx(end);
            end
            PlotTime.(Classifiers{j})(trial,i) = ...
                TrainTime{i}.(Classifiers{j}).Untransformed(trial,BestIdx);
            PlotError.(Classifiers{j})(trial,i) = ...
                TestError{i}.(Classifiers{j}).Untransformed(trial,end);
        end
    end
end

for i = 1:length(Classifiers)
    cl = Classifiers{i};
    hTestError(i) = errorbar(dims(1:length(TestError)),mean(PlotError.(cl)),...
        std(PlotError.(cl))/sqrt(size(PlotError.(cl),1)),...
        'LineWidth',LineWidth,'Color',Colors.(cl),...
        'LineStyle',LineStyles.(cl));
    hold on
end

title('(C)','Units','normalized','Position',[0.025 .975],'HorizontalAlignment','left','VerticalAlignment','top')
% text(0.5,1.05,{'Error Rate';'(relative to RF)'},'FontSize',16,'FontWeight','bold','Units','normalized','HorizontalAlignment','center','VerticalAlignment','bottom')
xlabel('p')
ylabel('Error Rate')
ax.LineWidth = LineWidth;
ax.FontUnits = 'inches';
ax.FontSize = FontSize;
ax.Units = 'inches';
ax.Position = [axLeft(3) axBottom(3) axWidth axHeight];
ax.Box = 'off';
ax.XLim = [1 6];
% ax.XScale = 'log';
ax.XTick = [2 5 10 20 40];
ax.XTickLabel = {'2' '5' '10' '20' '40'};
ax.YLim = [0 0.1];

ax = axes;

for i = 1:length(Classifiers)
    cl = Classifiers{i};
    hTrainTime(i) = errorbar(dims(1:length(TestError)),mean(PlotTime.(cl)),...
        std(PlotTime.(cl))/sqrt(size(PlotTime.(cl),1)),...
        'LineWidth',LineWidth,'Color',Colors.(cl),...
        'LineStyle',LineStyles.(cl));
    hold on
end

title('(E)','Units','normalized','Position',[0.025 .975],'HorizontalAlignment','left','VerticalAlignment','top')
% text(0.5,1.05,'Training Time','FontSize',16,'FontWeight','bold','Units','normalized','HorizontalAlignment','center','VerticalAlignment','bottom')
xlabel('p')
ylabel('Train Time (s)')
ax.LineWidth = LineWidth;
ax.FontUnits = 'inches';
ax.FontSize = FontSize;
ax.Units = 'inches';
ax.Position = [axLeft(5) axBottom(5) axWidth axHeight];
ax.Box = 'off';
ax.XLim = [1 6];
ax.YLim = [1 25];
% ax.XScale = 'log';
ax.YScale = 'log';
ax.XTick = [2 5 10 20 40];
ax.XTickLabel = {'2' '5' '10' '20' '40'};
ax.YTickLabel = {'1','10','100'};

clear hTestError hTrainTime TestError minTestError trainTime
%% Plot Trunk

ax = axes;

n = 100;
p = 2;

d_idx = 1:p;
mu1 = 1./sqrt(d_idx);
mu0 = -1*mu1;
Mu = cat(1,mu0,mu1);
Sigma = ones(1,p);
obj = gmdistribution(Mu,Sigma);
[X,idx] = random(obj,n);
Class = [0;1];
Y = Class(idx);

plot(X(Y==0,1),X(Y==0,2),'b.',X(Y==1,1),X(Y==1,2),'r.','MarkerSize',MarkerSize)

title('(B)','Units','normalized','Position',[0.025 .975],'HorizontalAlignment','left','VerticalAlignment','top')
text(0.5,1.05,'Trunk','FontSize',16,'FontWeight','bold','Units',...
    'normalized','HorizontalAlignment','center','VerticalAlignment'...
    ,'bottom')
xlabel('X_1')
ylabel('X_2')
ax.LineWidth = LineWidth;
ax.FontUnits = 'inches';
ax.FontSize = FontSize;
ax.Units = 'inches';
ax.Position = [axLeft(2) axBottom(2) axWidth axHeight];
ax.Box = 'off';
ax.XLim = [-5 5];
ax.YLim = [-5 5];
% ax.XTick = [-5 0 5];
%ax.YTick = [-5 0 5];
% ax.XTickLabel = {'-5';'0';'5'};
%ax.YTickLabel = {'-5';'0';'5'};

if runSims
    run_Trunk
else
    load Trunk_partial
end

ax = axes;

clear PlotError PlotTime

for i = 1:length(TestError)
    Classifiers = fieldnames(TestError{i});
    Classifiers(~ismember(Classifiers,{'rerf','rerf2'})) = [];
    for j = 1:length(Classifiers)
        ntrials = length(TestError{i}.(Classifiers{j}).Untransformed(:,end));
        for trial = 1:ntrials
            BestIdx = hp_optimize(OOBError{i}.(Classifiers{j}).Untransformed(trial,:,end),...
                OOBAUC{i}.(Classifiers{j}).Untransformed(trial,:,end));
            if length(BestIdx) > 1
                BestIdx = BestIdx(end);
            end
            PlotTime.(Classifiers{j})(trial,i) = ...
                TrainTime{i}.(Classifiers{j}).Untransformed(trial,BestIdx);
            PlotError.(Classifiers{j})(trial,i) = ...
                TestError{i}.(Classifiers{j}).Untransformed(trial);
        end
    end
end

for i = 1:length(Classifiers)
    cl = Classifiers{i};
    hTestError(i) = errorbar(dims(1:length(TestError)),mean(PlotError.(cl)),...
        std(PlotError.(cl))/sqrt(size(PlotError.(cl),1)),...
        'LineWidth',LineWidth,'Color',Colors.(cl),...
        'LineStyle',LineStyles.(cl));
    hold on
end

title('(D)','Units','normalized','Position',[0.025 .975],'HorizontalAlignment','left','VerticalAlignment','top')
xlabel('p')
ylabel('Error Rate')
ax.LineWidth = LineWidth;
ax.FontUnits = 'inches';
ax.FontSize = FontSize;
ax.Units = 'inches';
ax.Position = [axLeft(4) axBottom(4) axWidth axHeight];
ax.Box = 'off';
ax.XLim = [1 30];
ax.YLim = [0.15 0.35];
% ax.XScale = 'log';
% ax.XTick = [10,100,500];
% ax.XTickLabel = {'10','100','500'};

ax = axes;

for i = 1:length(Classifiers)
    cl = Classifiers{i};
    hTrainTime(i) = errorbar(dims(1:length(TestError)),mean(PlotTime.(cl)),...
        std(PlotTime.(cl))/sqrt(size(PlotTime.(cl),1)),...
        'LineWidth',LineWidth,'Color',Colors.(cl),...
        'LineStyle',LineStyles.(cl));
    hold on
end

title('(F)','Units','normalized','Position',[0.025 .975],'HorizontalAlignment','left','VerticalAlignment','top')
xlabel('p')
ylabel('Train Time (s)')
ax.LineWidth = LineWidth;
ax.FontUnits = 'inches';
ax.FontSize = FontSize;
ax.Units = 'inches';
ax.Position = [axLeft(6) axBottom(6) axWidth axHeight];
ax.Box = 'off';
ax.XLim = [1 30];
ax.YLim = [1 30];
% ax.XScale = 'log';
ax.YScale = 'log';
% ax.XTick = [10,100,500];
ax.YTick = [1,10,100];
% ax.XTickLabel = {'10','100','500'};
ax.YTickLabel = {'1','10','100'};
[lh2,objh2] = legend('RerF','Rerf2');
lh2.Location = 'southwest';
lh2.Box = 'off';
lh2.FontSize = 11;

for i = 7:length(objh2)
    objh2(i).Children.Children(2).XData = [(objh2(i).Children.Children(2).XData(2)-objh2(i).Children.Children(2).XData(1))*.75+objh2(i).Children.Children(2).XData(1),objh2(i).Children.Children(2).XData(2)];
end

save_fig(gcf,[rerfPath 'RandomerForest/Figures/Fig2_RerF2'])