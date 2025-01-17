close all
clear
clc

fpath = mfilename('fullpath');
findex = strfind(fpath,'/');
rootDir=fpath(1:findex(end-1));
p = genpath(rootDir);
gits=strfind(p,'.git');
colons=strfind(p,':');
for i=0:length(gits)-1
endGit=find(colons>gits(end-i),1);
p(colons(endGit-1):colons(endGit)-1)=[];
end
addpath(p);

n = 100;
dims = round(logspace(log10(2),3,10));
ntrials = 10;
ntrees = 1500;
NWorkers = 2;
cumrferr = NaN(ntrials,length(dims));
cumf2err = NaN(ntrials,length(dims));
cumf3err = NaN(ntrials,length(dims));
cumf4err = NaN(ntrials,length(dims));
trf = NaN(ntrials,length(dims));
tf2 = NaN(ntrials,length(dims));
tf3 = NaN(ntrials,length(dims));
tf4 = NaN(ntrials,length(dims));
Class = [0;1];

poolobj = gcp('nocreate');
if isempty(poolobj)
    parpool('local',NWorkers,'IdleTimeout',360);
end

for trial = 1:ntrials
    fprintf('trial %d\n',trial)
    for i = 1:length(dims)
        d = dims(i);
        fprintf('dimensions = %d\n',dims(i))
        d_idx = 1:d;
        nvartosample = ceil(d^(2/3));
        mu1 = 1./sqrt(d_idx);
        mu0 = -1*mu1;
        Mu = cat(1,mu0,mu1);
        Sigma = ones(1,d);
        obj = gmdistribution(Mu,Sigma);
        [X,idx] = random(obj,n);
        Y = cellstr(num2str(Class(idx)));
        
        tic
        rf = rpclassificationforest(ntrees,X,Y,'nvartosample',nvartosample,'RandomForest',true,'NWorkers',NWorkers);
        trf(trial,i) = toc;
        cumrferr(trial,i) = oobpredict(rf,X,Y,'last');
        
        fprintf('Random Forest complete\n')
        
        tic
        f2 = rpclassificationforest(ntrees,X,Y,'s',3,'nvartosample',nvartosample,'mdiff','off','sparsemethod','jovo','NWorkers',NWorkers);
        tf2(trial,i) = toc;
        cumf2err(trial,i) = oobpredict(f2,X,Y,'last');
        
        fprintf('TylerForest+ complete\n')
        
        tic
        f3 = rpclassificationforest(ntrees,X,Y,'s',3,'nvartosample',nvartosample,'mdiff','all','sparsemethod','jovo','NWorkers',NWorkers);
        tf3(trial,i) = toc;
        cumf3err(trial,i) = oobpredict(f3,X,Y,'last');
        
        fprintf('TylerForest+meandiff all complete\n')
        
        tic
        f4 = rpclassificationforest(ntrees,X,Y,'s',3,'nvartosample',nvartosample,'mdiff','node','sparsemethod','jovo','NWorkers',NWorkers);
        tf4(trial,i) = toc;
        cumf4err(trial,i) = oobpredict(f4,X,Y,'last');
        
        fprintf('TylerForest+meandiff node complete\n')
    end
end

save('Trunk_vary_d.mat','cumrferr','cumf2err','cumf3err','cumf4err','trf','tf2','tf3','tf4')
rfsem = std(cumrferr)/sqrt(ntrials);
f2sem  = std(cumf2err)/sqrt(ntrials);
f3sem = std(cumf3err)/sqrt(ntrials);
f4sem = std(cumf4err)/sqrt(ntrials);
cumrferr = mean(cumrferr);
cumf2err = mean(cumf2err);
cumf3err = mean(cumf3err);
cumf4err = mean(cumf4err);
Ynames = {'cumrferr' 'cumf2err' 'cumf3err' 'cumf4err'};
Enames = {'rfsem' 'f2sem' 'f3sem' 'f4sem'};
lspec = {'-bo','-rx','-gd','-ks'};
hold on
for i = 1:length(Ynames)
    errorbar(dims,eval(Ynames{i}),eval(Enames{i}),lspec{i});
end
set(gca,'XScale','log')
xlabel('# ambient dimensions')
ylabel('oob error')
title('Trunk')
legend('RandomForest','TylerForest+','TylerForest+meandiff all','TylerForest+meandiff node')
fname = sprintf('Trunk_ooberror_vs_d_n%d_var%d_ntrees%d_ntrials%d_meandiff_node',n,Sigma(1),ntrees,ntrials);
save_fig(gcf,fname)

figure(2)
rfsem = std(trf)/sqrt(ntrials);
f2sem  = std(tf2)/sqrt(ntrials);
f3sem = std(tf3)/sqrt(ntrials);
f4sem = std(tf4)/sqrt(ntrials);
trf = mean(trf);
tf2 = mean(tf2);
tf3 = mean(tf3);
tf4 = mean(tf4);
Ynames = {'trf' 'tf2' 'tf3' 'tf4'};
Enames = {'rfsem' 'f2sem' 'f3sem' 'f4sem'};
lspec = {'-bo','-rx','-gd','-ks'};
hold on
for i = 1:length(Ynames)
    errorbar(dims,eval(Ynames{i}),eval(Enames{i}),lspec{i});
end
set(gca,'XScale','log')
xlabel('# ambient dimensions')
ylabel('Training time (sec)')
title('Trunk')
legend('RandomForest','TylerForest+','TylerForest+meandiff all','TylerForest+meandiff node')
fname = sprintf('Trunk_time_vs_d_n%d_var%d_ntrees%d_ntrials%d_meandiff_node',n,Sigma(1),ntrees,ntrials);
save_fig(gcf,fname)