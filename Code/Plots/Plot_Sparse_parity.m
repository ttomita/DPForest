clear
close all
clc

LineWidth = 3;
FontSize = .25;
axWidth = 2;
axHeight = 2;
axLeft = [FontSize*4 FontSize*8+axWidth FontSize*4 FontSize*8+axWidth];
axBottom = [FontSize*8+axHeight FontSize*8+axHeight FontSize*4 FontSize*4];
cbWidth = .25;
cbHeight = axHeight;
cbLeft = axLeft(4) + axWidth + FontSize;
cbBottom = axBottom(4);
figWidth = cbLeft + cbWidth + FontSize*4;
figHeight = axBottom(1) + axHeight + FontSize*4;

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

runSims = true;

if runSims
    run_Sparse_parity
else
    load Sparse_parity.mat
end

[Lhat.rf,minIdx.rf] = min(mean_err_rf(end,:,:),[],2);
[Lhat.rerf,minIdx.rerf] = min(mean_err_rerf(end,:,:),[],2);
[Lhat.rerfdn,minIdx.rerfdn] = min(mean_err_rerfdn(end,:,:),[],2);
[Lhat.rf_rot,minIdx.rf_rot] = min(mean_err_rf_rot(end,:,:),[],2);

for i = 1:length(dims)
    sem.rf(i) = sem_rf(end,minIdx.rf(i),i);
    sem.rerf(i) = sem_rerf(end,minIdx.rerf(i),i);
    sem.rerfdn(i) = sem_rerfdn(end,minIdx.rerfdn(i),i);
    sem.rf_rot(i) = sem_rf_rot(end,minIdx.rf_rot(i),i);
end

classifiers = fieldnames(Lhat);

for i = 1:length(classifiers)
    cl = classifiers{i};
    h(i) = errorbar(dims,Lhat.(cl)(:)',sem.(cl));
    i = i + 1;
    hold on
end

ax = gca;
ax.XScale = 'log';
xlabel('d')
ylabel('Lhat')
title('Parity')
legend('RF','RerF','RerFdn','Rotation RF')

Date = strsplit(date,'-');
save_fig(gcf,['~/RandomerForest/Figures/Sparse_parity_' Date{end} '_' Date{2} '_' Date{1}])