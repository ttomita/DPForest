%% Plot Performance Profiles for Benchmark Transformations
close all
clear
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

LineWidth = 2;
FontSize = .16;
axWidth = 1.75;
axHeight = 1.75;
axLeft = [FontSize*4,FontSize*7+axWidth,FontSize*10+axWidth*2,...
    FontSize*13+axWidth*3];
axBottom = [FontSize*4,FontSize*4,FontSize*4,FontSize*4];
figWidth = axLeft(end) + axWidth + FontSize*4;
figHeight = axBottom(1) + axHeight + FontSize*4;
fig = figure;
fig.Units = 'inches';
fig.PaperUnits = 'inches';
fig.Position = [0 0 figWidth figHeight];
fig.PaperPosition = [0 0 figWidth figHeight];

Titles = {'(A) Untransformed' '(B) Rotated' '(C) Scaled' '(D) Affine'};

runSims = false;

if runSims
    run_Performance_profile_untransformed
else
    load Performance_profile_untransformed.mat
end

ax = subplot(1,4,1);
hold on

xmin = min(tau);
xmax = max(tau);
ymin = .7;
ymax = max(rho_ps(:));

for i = 1:length(clnames)-1
     plot(tau,rho_ps(:,i),'LineWidth',LineWidth)
end

title(Titles{1})
xlabel('Relative Performance')
ylabel('Emperical Distribution')
ax.LineWidth = LineWidth;
ax.FontUnits = 'inches';
ax.FontSize = FontSize;
ax.Units = 'inches';
ax.Position = [axLeft(1) axBottom(1) axWidth axHeight];
ax.Box = 'off';
ax.XLim = [xmin xmax];
ax.YLim = [ymin ymax];
ax.YTick = [.7 .8 .9 1];


if runSims
    run_Performance_profile_rotate
else
    load Performance_profile_rotate.mat
end

ax = subplot(1,4,2);
hold on

xmin = min(tau);
xmax = max(tau);
ymin = .7;
ymax = max(rho_ps(:));

for i = 1:length(clnames)-1
     plot(tau,rho_ps(:,i),'LineWidth',LineWidth)
end

title(Titles{2})
xlabel('Relative Performance')
% ylabel('Emperical Distribution')
ax.LineWidth = LineWidth;
ax.FontUnits = 'inches';
ax.FontSize = FontSize;
ax.Units = 'inches';
ax.Position = [axLeft(2) axBottom(2) axWidth axHeight];
ax.Box = 'off';
ax.XLim = [xmin xmax];
ax.YLim = [ymin ymax];
ax.YTick = [.7 .8 .9 1];

if runSims
    run_Performance_profile_scale
else
    load Performance_profile_scale.mat
end

ax = subplot(1,4,3);
hold on

xmin = min(tau);
xmax = max(tau);
ymin = .9;
ymax = max(rho_ps(:));

for i = 1:length(clnames)-1
     plot(tau,rho_ps(:,i),'LineWidth',LineWidth)
end

title(Titles{3})
xlabel('Relative Performance')
% ylabel('Emperical Distribution')
ax.LineWidth = LineWidth;
ax.FontUnits = 'inches';
ax.FontSize = FontSize;
ax.Units = 'inches';
ax.Position = [axLeft(3) axBottom(3) axWidth axHeight];
ax.Box = 'off';
ax.XLim = [xmin xmax];
ax.YLim = [ymin ymax];
ax.XTick = 2:6:14;
ax.YTick = [.9 .95 1];


if runSims
    run_Performance_profile_affine
else
    load Performance_profile_affine.mat
end

ax = subplot(1,4,4);
hold on

xmin = min(tau);
xmax = max(tau);
ymin = .9;
ymax = max(rho_ps(:));


for i = 1:length(clnames)-1
     plot(tau,rho_ps(:,i),'LineWidth',LineWidth)
end

title(Titles{4})
xlabel('Relative Performance')
% ylabel('Emperical Distribution')
ax.LineWidth = LineWidth;
ax.FontUnits = 'inches';
ax.FontSize = FontSize;
ax.Units = 'inches';
ax.Position = [axLeft(4) axBottom(4) axWidth axHeight];
ax.Box = 'off';
ax.XLim = [xmin xmax];
ax.YLim = [ymin ymax];
ax.YTick = [.9 .95 1];

l = legend({'RF';'RerF';'RotRF';'RerFd'});
l.Location = 'southeast';
l.Box = 'off';

save_fig(gcf,[rerfPath 'RandomerForest/Figures/Fig4_benchmark'])