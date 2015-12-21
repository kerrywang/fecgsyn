%function FECGSYN_exp3results
% this script generates the plots for experiment 3 of the paper
%
% NI-FECG simulator toolbox, version 1.0, February 2014
% Released under the GNU General Public License
%
% Copyright (C) 2014 Joachim Behar & Fernando Andreotti
% Oxford university, Intelligent Patient Monitoring Group - Oxford 2014
% joachim.behar@eng.ox.ac.uk, fernando.andreotti@mailbox.tu-dresden.de
%
% Last updated : 30-05-2014
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
%


%% Auxiliary code to merge multiple result files
% fls = dir('*.mat');     % looking for .mat (creating index)
% fls =  arrayfun(@(x)x.name,fls,'UniformOutput',false);
% morphall = struct('JADEICA',[],'PCA',[],'tsc',[],'tspca',[],'tsekf',[],'alms',[],'arls',[],'aesn',[]);
% for met = {'JADEICA','PCA','tsc','tspca','tsekf','alms','arls','aesn'}
%        morphall.(met{:}) = cell(1750,7);
%  end
% for i = 1:length(fls)
%     load(fls{i})
%     for met = {'JADEICA','PCA','tsc','tspca','tsekf','alms','arls','aesn'}
%         morph.(met{:})(1751:end,:) = [];
%         idx = cellfun(@(x) ~isempty(x),morph.(met{:}));
%         morphall.(met{:})(idx) = morph.(met{:})(idx);
%     end
%
% end
%                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
%

%% Generating scatter FQT / FTQRS plots

if isunix
   load('/home/andreotti/Dropbox/sharelatex/[Andreotti et al 2016] Standardising FECGSYN (in review)/fecgsyn_morphology/mats/exp3_morphall.mat') 
else
    load('D:\Users\Andreotti\Dropbox\sharelatex\[Andreotti et al 2016] Standardising FECGSYN (in review)\fecgsyn_morphology\mats\exp3_morphall.mat')
end

c0 = cellfun(@(x) ~isempty(regexp(x,'.c0','ONCE')),fls_orig);
c1 = cellfun(@(x) ~isempty(regexp(x,'.c1','ONCE')),fls_orig);
c2 = cellfun(@(x) ~isempty(regexp(x,'.c2','ONCE')),fls_orig);
c3 = cellfun(@(x) ~isempty(regexp(x,'.c3','ONCE')),fls_orig);
c4 = cellfun(@(x) ~isempty(regexp(x,'.c4','ONCE')),fls_orig);
c5 = cellfun(@(x) ~isempty(regexp(x,'.c5','ONCE')),fls_orig);
bas = ~(c0|c1|c2|c3|c4|c5);
snr00 = cellfun(@(x) ~isempty(regexp(x,'.snr00dB','ONCE')),fls_orig);
snr03 = cellfun(@(x) ~isempty(regexp(x,'.snr03dB','ONCE')),fls_orig);
snr06 = cellfun(@(x) ~isempty(regexp(x,'.snr06dB','ONCE')),fls_orig);
snr09 = cellfun(@(x) ~isempty(regexp(x,'.snr09dB','ONCE')),fls_orig);
snr12 = cellfun(@(x) ~isempty(regexp(x,'.snr12dB','ONCE')),fls_orig);


%% FQT Paper Plots

%== Linear regression plots
colm = [1,2;3,4];
for row = 1:2;
    count = 1;
    figure
    for met = {'JADEICA' 'tsc' 'aesn'}
        disp(met{:})
        morphtmp = morphall.(met{:})(bas,:);
        fqt = morphtmp(:,colm(row,:));
        for k = 1:size(fqt,1)
            fqt{k,1}(cellfun(@isempty, fqt{k,1})) = {NaN};
        end
        fqtmed = cellfun(@(x) abs(cell2mat(x)),fqt,'UniformOutput',0);
        fqtmed = cellfun(@(x) nanmedian(x),fqtmed,'UniformOutput',0);
        fqtmed = [cell2mat(fqtmed(:,1)')' cell2mat(fqtmed(:,2)')'];
        fqtmed(any(isnan(fqtmed), 2),:)=[];
%         [h,coe]=ttest(fqtmed(:,2),fqtmed(:,1));
%         p.(met{:}) = coe;
%         if h
%             fprintf('Null hypothesis can be rejected with p= %d \n',p.(met{:}));
%         else
%             fprintf('Null hypothesis CANNOT be rejected');
%         end
        % plot
        subplot(1,3,count)
        x = fqtmed(:,2); y = fqtmed(:,1);
        scatter(x,y,12,'filled')
        % regression
        a = polyfit(x,y,1);
        yfit = polyval(a,x);
        yresid = y - yfit;
        SSresid = sum(yresid.^2);
        SStotal = (length(y)-1) * var(y);
        rsq = 1 - SSresid/SStotal;
        hold on; plot(x,yfit,'r-');
        if row ==1
            text(220,140,sprintf('r^2 = %2.4f',rsq))
            xlim([120,260]),ylim([120,260])
            xlabel('FQT reference (ms)')
            ylabel('FQT test (ms)')
        else
            text(1,0.2,sprintf('r^2 = %2.4f',rsq))
            xlim([0 80]),ylim([0 80])
            xlabel('T/QRS reference (%)')
            ylabel('T/QRS test (%)')
        end
        axis square
        %     title(met{:})
        
        count = count +1;
    end
end

%== Bland-Altman plots
count = 1;
for met = {'tsc' 'tsekf'}%{'JADEICA' 'PCA' 'tsc' 'tspca' 'tsekf' 'alms' 'arls' 'aesn' }
    morphtmp = morphall.(met{:})(bas,:);
    tqrs = morphtmp(:,colm(2,:));
    tmed = cellfun(@(x) abs(cell2mat(x)),tqrs,'UniformOutput',0);
    tmed = cellfun(@(x) nanmedian(x),tmed,'UniformOutput',0);
    tmed = [cell2mat(tmed(:,1)')' cell2mat(tmed(:,2)')'];
    tmed(any(isnan(tmed), 2),:)=[];
    x = tmed(:,2); y = tmed(:,1);
    % Bland-Altman plot to show TSekf vs TSc
    datamean = nanmean([x,y],2);  % Mean of values from each instrument
    diffmean = nanmean(x-y);               % Mean of difference between instruments
    diffstd = nanstd(x-y);                % Std dev of difference between instruments
    subplot(1,2,count)
    scatter(datamean,x-y,12,'filled')   % Bland Altman plot
    hold on,plot(diffmean*ones(1,length(datamean)),'-k')             % Mean difference line
    plot(diffmean+1.96*diffstd*ones(1,length(datamean)),'--k')                   % Mean plus 2*SD line
    plot(diffmean-1.96*diffstd*ones(1,length(datamean)),'--k')                  % Mean minus 2*SD line
    grid on
    xlabel('mean(T/QRS_{ref},T/QRS_{test})')
    ylabel('T/QRS_{ref} - T/QRS_{test}')
    count = count +1;
    xlim([0 60]),ylim([-40 40]);
end

%= Boxplot for CASE 0 and various SNRs
% figure
% count2 = 1;
% colors = rand(35,3);
% for met = {'JADEICA' 'PCA' 'tsc' 'tspca' 'tsekf' 'alms' 'arls' 'aesn' }
%     statscasesnr = NaN(50,35);
%     eval(['stat = stats.' met{:} ';']);
%     count1 = 1;
%     cases = {'c0'};
%     for snr = {'snr00' 'snr03' 'snr06' 'snr09' 'snr12'}
%         statscasesnr(:,count1) = 100*stat(eval(cases{:})&eval(snr{:}),1);
%         count1 = count1 + 1;
%     end
%     labelssnr = repmat(1:5,1,7);
%     labelscase = reshape(repmat({'base','c0','c1','c2','c3','c4','c5'},5,1),1,35);
%     subplot(2,4,count2)
%     boxplot(statscasesnr,{labelscase labelssnr},'factorgap',3,'color',colors,...
%         'medianstyle','target','plotstyle','compact','boxstyle','filled')
%     h=findobj(gca,'tag','Outliers'); % not ploting outliers
%     delete(h)
%     count2 = count2 +1;
% end


%= New plots
statsfqt = zeros(250,8*5); statsftqrs = statsfqt;
fqtnan = zeros(1750,8);ftqrsnan = zeros(1750,8);
count1 = 0;
for met = {'JADEICA' 'PCA' 'tsc' 'tspca' 'tsekf' 'alms' 'arls' 'aesn'}
   tmp = morphall.(met{:});
   % merging multichannel and segments into one measurement
   for i = 1:1750
       tmpnan = tmp;
       % checking for NaNs
       shorted = sum(sum(cellfun(@isempty, tmpnan{i,1}))); % case less components than channels
       tmpnan{i,1}(cellfun(@isempty, tmpnan{i,1})) = {0};   
       totnan = numel(cell2mat(tmpnan{i,1})); % total number of segments
       fqtnan(i,count1+1) = sum(sum(isnan(cell2mat(tmpnan{i,1}))))/(totnan-shorted);
       % saving results
       tmp{i,1}(cellfun(@isempty, tmp{i,1})) = {NaN};
       tmp{i,3}(cellfun(@isempty, tmp{i,3})) = {NaN};
       tmpstat = abs(nanmedian(cell2mat(tmp{i,1}))-nanmedian(cell2mat(tmp{i,2}))); % FQT error calculus
       statqt{i} = reshape(tmpstat,1,numel(tmpstat));
       tmpstat = abs(nanmedian(cell2mat(tmp{i,3}))-nanmedian(cell2mat(tmp{i,4})));
       stattqrs{i} = reshape(tmpstat,1,numel(tmpstat));
   end
   % differently from F1 and MAE, we have 5 values for each recording, due
   % to the number of segments.
   count2 = 1;
   tmpsnr = zeros(1750,1);
     for snr = {'snr00' 'snr03' 'snr06' 'snr09' 'snr12'}
         snrloop = eval(snr{:});
          tmpqt = cell2mat(statqt(c0&snrloop)');
          statsfqt(:,5*count1+count2) = reshape(tmpqt,1,numel(tmpqt));
          tmpftqrs = cell2mat([stattqrs(c0&snrloop)']); % FQTs (columns = cases)
         statsftqrs(:,5*count1+count2) = reshape(tmpftqrs,1,numel(tmpftqrs));
         count2 = count2 + 1; 
         tmpsnr(snrloop) = str2double(snr{:}(4:5));
     end
     count1 = count1 + 1;
end


% = Checking out Spearman correlation coefficient between SNRs and number
% of NANs
for i = 1:8
    p(i,1) = corr(fqtnan(c0,i),tmpsnr(c0));
    r(i,1) = corr(fqtnan(c0,i),tmpsnr(c0),'type','spearman');    
end


clear tmpnan fqtnan ftqrsnan tmpsnr p r shorted totnan

% = Boxplots
colors = rand(40,3);
labelsmet = reshape(repmat({'BSS_{ica}','BSS_{pca}','TS_{c}','TS_{pca}','TS_{ekf}','AM_{lms}','AM_{rls}','AM_{esn}'},5,1),1,40);
labelssnr = reshape(repmat(1:5,8,1)',1,40);
figure
boxplot(statsfqt,{labelsmet labelssnr},'factorgap',3,'color',colors,...
    'medianstyle','target','plotstyle','compact','boxstyle','filled')
h=findobj(gca,'tag','Outliers'); % not ploting outliers
delete(h)
figure
boxplot(statsftqrs,{labelsmet labelssnr},'factorgap',3,'color',colors,...
    'medianstyle','target','plotstyle','compact','boxstyle','filled')
h=findobj(gca,'tag','Outliers'); % not ploting outliers
delete(h)
% = Kruskal-Wallis
for i = 1:8 % go through each case and do a Kruskal-Wallis test
    p1(i)=kruskalwallis(statsfqt(:,(i-1)*5+1:5*i),[],'off');
    p2(i)=kruskalwallis(statsftqrs(:,(i-1)*5+1:5*i),[],'off');
       
end


% At this point we have a 5(SNRs)x7(Cases)x8(Methods) matrix 
% now we can proceed with the significance analysis
statsfqt(:,1,:) = []; statsftqrs(:,1,:) = []; % removing baseline since it does not make sense on significance analysis
count1 = 1;
for var = {'statsfqt' 'statsftqrs'}
    stastuse = eval(var{:});
    figure
    for snr = 1:size(stastuse,1)
        tempstat = reshape(stastuse(snr,:,:),[],8);
        p(snr,1) = friedman(tempstat,1,'off');
        p(snr,2) = friedman(tempstat',1,'off');
        for i = 1:8
            for j = 1:8
                [psig(snr,i,j),hsig(snr,i,j)] = signtest(tempstat(:,i),tempstat(:,j));
            end
        end
        gridp = reshape(psig(snr,:,:),8,8);
        gridp(gridp >= 0.05) = 0;
        gridp(gridp < 0.01&gridp>0) =  2;
        gridp(gridp < 0.05&gridp>0) =  1;
        subplot(1,5,snr)
        pcolor([gridp NaN(8,1);NaN(1,9)])%,[0 2])
        colormap(flipud(gray))
        %xlim([0 8]),ylim([0 8])
        set(gca,'xtick', linspace(0.5,8.5,8), 'ytick', linspace(0.5,8.5,8));
        set(gca,'xticklabel', {[1:8]}, 'yticklabel', {[1:8]});
        axis square
        %     set(gca,'xgrid', 'on', 'ygrid', 'on', 'gridlinestyle', '-', 'xcolor', 'k', 'ycolor', 'k');
        grid on
    end
end

disp(psig) %(first column cases, second methods)






%= Case by case methods against each other
% Generate Table

%% FQT
% for met = {'JADEICA' 'PCA' 'tsc' 'tspca' 'tsekf' 'alms' 'arls' 'aesn' }
stat = cell(1750,1);
% for met = {'JADEICA' 'PCA' 'tsc' 'tspca' 'tsekf' 'alms' 'arls' 'aesn' }
for met = {'JADEICA' 'tsc' 'aesn' }
    tmp = morphall.(met{:});
    for i = 1:1750
        tmp{i,1}(cellfun(@isempty, tmp{i,1})) = {NaN};
        tmpstat = abs(nanmean(cell2mat(tmp{i,1}))-nanmean(cell2mat(tmp{i,2})));
        stat{i} = reshape(tmpstat,1,numel(tmpstat));
    end
    %     statscase = [stat(bas,1) stat(c0,1) stat(c1,1) stat(c2,1) stat(c3,1) stat(c4,1) stat(c5,1)];
    statnoise.(met{:}).qt = [cell2mat(stat(snr12,:)')' cell2mat(stat(snr09,:)')' cell2mat(stat(snr06,:)')' ...
        cell2mat(stat(snr03,:)')' cell2mat(stat(snr00,:)')'];
    
end

%% FTh
% for met = {'JADEICA' 'PCA' 'tsc' 'tspca' 'tsekf' 'alms' 'arls' 'aesn' }
stat = cell(1750,1);
% for met = {'JADEICA' 'PCA' 'tsc' 'tspca' 'tsekf' 'alms' 'arls' 'aesn' }
for met = {'JADEICA' 'tsc' 'aesn' }
    tmp = morphall.(met{:});
    for i = 1:1750
        tmp{i,3}(cellfun(@isempty, tmp{i,3})) = {NaN};
        tmpstat = abs(nanmean(cell2mat(tmp{i,3}))-nanmean(cell2mat(tmp{i,4})));
        stat{i} = reshape(tmpstat,1,numel(tmpstat));
    end
    %     statscase = [stat(bas,1) stat(c0,1) stat(c1,1) stat(c2,1) stat(c3,1) stat(c4,1) stat(c5,1)];
    statnoise.(met{:}).ftqrs = [cell2mat(stat(snr12,:)')' cell2mat(stat(snr09,:)')' cell2mat(stat(snr06,:)')' ...
        cell2mat(stat(snr03,:)')' cell2mat(stat(snr00,:)')'];
    
end

%% SNR Plots
figure
count = 1;
for met = {'JADEICA' 'tsc' 'aesn' }
    subplot(3,2,count)
    boxplot(statnoise.(met{:}).qt,{'snr12dB' 'snr09dB' 'snr06dB' 'snr03dB' 'snr00dB'},'factorgap',10)
    grid on
    ylim([0 120])
    count = count +1;
    subplot(3,2,count)
    boxplot(statnoise.(met{:}).ftqrs,{'snr12dB' 'snr09dB' 'snr06dB' 'snr03dB' 'snr00dB'},'factorgap',10)
    grid on
    ylim([0 120])
    count = count +1;
end