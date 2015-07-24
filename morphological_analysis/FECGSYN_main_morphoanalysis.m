%% Main script for FECG morphological analysis
%
% This is the mains script for testing the morphological consistency of
% extracting the foetal signal using various methods.
% Used extraction methods:
%  - ICA
%  - PCA
%  - TS ...
%
% Used morphological measures:
% - T/QRS ratio
% - ST segment
% - QT interval
%
%
%
% NI-FECG simulator toolbox, version 1.0, February 2014
% Released under the GNU General Public License
%
% Copyright (C) 2014  Joachim Behar & Fernando Andreotti
% Oxford university, Intelligent Patient Monitoring Group - Oxford 2014
% joachim.behar@eng.ox.ac.uk, fernando.andreotti@mailbox.tu-dresden.de
%
% Last updated : 03-06-2014
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free So                                                           it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

global debug filesproc
filesproc = 1:14000;
debug = false;
%% Input parameters
% importing path
slashchar = char('/'*isunix + '\'*(~isunix));
if isunix
    %     path = '/media/andreotti/FetalEKG/2014.10_fecgsyn_simulations(5.0)/';
    %     path2save = '/media/andreotti/FetalEKG/2014.10_fecgsyn_simulations(5.0)/extracted3Hzer/';
    path = '/media/andreotti/FetalEKG/2014.10_fecgsyn_simulations(5.0)/';
    addpath(genpath('/opt/git/topsecret_morphologicalshit'))
else
    path = 'D:\2014.10_fecgsyn_simulations(5.0)\';
end

% = Change this parameters acording to desired experiment!!
generate_data = 0;   % boolean, data should be generated?
extract = 0;        % extract signals?
exp1 = 0;
exp2 = 0;
exp3 = 1;

fs_new = 250;       % signals will be resample to 250 Hz

%% Data Generation
if generate_data
    mkdir(path) %#ok<UNRCH>
    FECGSYN_generate_data(path)  % generates set of unique simulated data for testing
else
    cd(path)
end

% List generated files
fls = dir('*.mat');     % looking for .mat (creating index)
fls =  arrayfun(@(x)x.name,fls,'UniformOutput',false);

%% Experiment 1
% PCA&ICA and number of channels. Testing how the number of channels
% available is affecting the results of PCA and ICA.
%
% == experiments param

ch = {[11 22],[1 11 22 32],[1 8 11 22 25 32],[1 8 11 14 19 22 25 32], ...
    [1 3 6 8 11 14 19 22 25 27 30 32], ...
    [1 3 6 8 9 11 14 16 17 19 22 24 25  27 30 32],...
    1:32}; %#ok<NASGU> % trying with 4, 6, 8, 12, 16 and 32 channels

if exp1
    % == core function
    NB_REC = length(fls); %#ok<UNRCH>
    NB_RUN = length(ch);
    stats_struct = cell(NB_RUN,1);
    try
        cd([path slashchar 'exp1' slashchar])
    catch
        mkdir([path slashchar 'exp1' slashchar])
        cd([path slashchar 'exp1' slashchar])
    end
    
    % Saving filter coefficients
    HF_CUT = 100; % high cut frequency
    LF_CUT = 3; % low cut frequency
    [b_lp,a_lp] = butter(5,HF_CUT/(fs_new/2),'low');
    [b_bas,a_bas] = butter(3,LF_CUT/(fs_new/2),'high');
    
    for k = 1:NB_RUN
        for i = 1:NB_REC
            disp('>>>>>>>>>>>>>>>>>>>>>')
            fprintf('processing case with %f channels \n',length(ch{k}));
            %  diary(['log' num2str(length(ch{k})) '.txt'])
            %  diary on                                                              
            % = loading data
            load([path fls{i}])
            disp(num2str(i))
            if isempty(out.noise)
                noise = zeros(size(out.mecg));
            else
                noise = sum(cat(3,out.noise{:}),3);
            end
            fs = out.param.fs;
            INTERV = round(0.05*fs);     % BxB acceptance interval
            TH = 0.3;                    % detector threshold
            REFRAC = round(.15*fs)/1000; % detector refractory period
            mixture = double(out.mecg) + sum(cat(3,out.fecg{:}),3) ...
                + noise;                 % re-creating abdominal mixture
            mixture = mixture(ch{k},:)./3000;  % reducing number of channels, applying gain
            
            % = preprocessing channels            
            ppmixture = zeros(size(mixture,1),size(mixture,2)/(fs/fs_new));
            for j=1:length(ch{k})
                ppmixture(j,:) = resample(mixture(j,:),fs_new,fs);    % reducing number of channels
                lpmix = filtfilt(b_lp,a_lp,ppmixture(j,:));
                ppmixture(j,:) = filtfilt(b_bas,a_bas,lpmix);
                fref = round(out.fqrs{1}./(fs/fs_new));
            end
            
            % = run extraction
            for met = {'FASTICA_DEF','FASTICA_SYM','JADEICA','PCA'}
                disp('==============================');
                disp(['Extracting file ' fls{i} '..']);
                disp(['Recording number ' num2str(i)])
                disp(['Number of channels simulation: ' num2str(length(ch{k}))])
                disp(['The ICA method used is ' met{:}]);                                                                                             
                
                % == extraction
                % = using ICA (FASTICA or JADE)
                
                disp('ICA extraction ..')
                loopsec = 60;   % in seconds
                filename = [path2save met{:} '_nbch' num2str(length(ch{k})) '_rec' num2str(i)];
                icasig = FECGSYN_bss_extraction(ppmixture,met{:},fs_new,fref,loopsec,1);     % extract using IC
                % Calculate quality measures
                qrs = qrs_detect(icasig,TH,REFRAC,fs_new);
                if isempty(qrs)
                    F1= 0;
                    RMS = NaN;
                    PPV = 0;
                    SE = 0;
                else
                    [F1,RMS,PPV,SE] = Bxb_compare(fref,qrs,INTERV);
                end
                eval(['stats_' met{:} '(i,:) = [F1,RMS,PPV,SE];'])
            end           
        end
        stats_struct{k}.stats_pca = stats_PCA;
        stats_struct{k}.stats_FASTICA_DEF = stats_FASTICA_DEF;
        stats_struct{k}.stats_FASTICA_SYM = stats_FASTICA_SYM;
        stats_struct{k}.stats_JADEICA = stats_JADEICA;
%         diary off            
%         save(['stats_ch_' num2str(k)],'stats_struct');
    end
    
    
    % == statistics
    mean_FASTICA_SYM = zeros(NB_RUN,1);
    median_FASTICA_SYM = zeros(NB_RUN,1);
    mean_JADEICA = zeros(NB_RUN,1);
    median_JADEICA = zeros(NB_RUN,1);
    mean_FASTICA_DEF = zeros(NB_RUN,1);
    median_FASTICA_DEF = zeros(NB_RUN,1);
    mean_pca = zeros(NB_RUN,1);
    median_pca = zeros(NB_RUN,1);
    for kk=1:NB_RUN
        mean_FASTICA_DEF(kk) = mean(stats_struct{kk}.stats_FASTICA_DEF(1:NB_REC,1));
        median_FASTICA_DEF(kk) = median(stats_struct{kk}.stats_FASTICA_DEF(1:NB_REC,1));
        mean_FASTICA_SYM(kk) = mean(stats_struct{kk}.stats_FASTICA_SYM(1:NB_REC,1));
        median_FASTICA_SYM(kk) = median(stats_struct{kk}.stats_FASTICA_SYM(1:NB_REC,1));
        mean_JADEICA(kk) = mean(stats_struct{kk}.stats_JADEICA(1:NB_REC,1));
        median_JADEICA(kk) = median(stats_struct{kk}.stats_JADEICA(1:NB_REC,1));
        mean_pca(kk) = mean(stats_struct{kk}.stats_pca(1:NB_REC,1));
        median_pca(kk) = median(stats_struct{kk}.stats_pca(1:NB_REC,1));
    end
end
% save(['workspace_exp1_', icamethod]); % save the workspace for history

%% Experiment 2 and 3
% Channels to be used
ch = [1 8 11 14 19 22 25 32]; % using 8 channels (decided considering Exp. 1)
refchs = 33:34;

if extract
    % = Defining preprocessing bands
    if exp2
        HF_CUT = 100; %#ok<UNRCH> % high cut frequency
        LF_CUT = 3; % low cut frequency
        [b_lp,a_lp] = butter(5,HF_CUT/(fs_new/2),'low');
        [b_hp,a_hp] = butter(3,LF_CUT/(fs_new/2),'high');
        clear HF_CUT LF_CUT
        path2save = [path 'exp2/'] ;
    elseif exp3
        % Preprocessing more carefully
        % high-pass filter
        Fstop = 0.5;  % Stopband Frequency
        Fpass = 1;    % Passband Frequency
        Apass = 0.1;  % Passband Ripple (dB)
        Astop = 20;   % Stopband Attenuation (dB)
        h = fdesign.highpass('fst,fp,ast,ap', Fstop, Fpass, Astop, Apass, fs_new);
        Hhp = design(h, 'butter', ...
            'MatchExactly', 'stopband', ...
            'SOSScaleNorm', 'Linf', ...
            'SystemObject', true);
        [b_hp,a_hp] = tf(Hhp);
        % low-pass filter
        Fpass = 100;   % Passband Frequency
        Fstop = 110;  % Stopband Frequency
        Apass = 0.1;    % Passband Ripple (dB)
        Astop = 20;   % Stopband Attenuation (dB)
        h = fdesign.lowpass('fp,fst,ap,ast', Fpass, Fstop, Apass, Astop, fs_new);
        Hlp = design(h, 'butter', ...
            'MatchExactly', 'stopband', ...
            'SOSScaleNorm', 'Linf');
        [b_lp,a_lp] = tf(Hlp);
        clear Fstop Fpass Astop Apass h Hhp Hlp
        path2save = [path 'exp3/'] ;
    end
    
    if exp2 || exp3
        for i = 1:length(fls)
            disp(['Extracting file ' fls{i} '..'])
            filename = [path2save 'rec' num2str(i)];
            % = loading data
            load(fls{i})
            disp(num2str(i))
            if isempty(out.noise)
                noise = zeros(size(out.mecg));
            else
                noise = sum(cat(3,out.noise{:}),3);
            end
            fs = out.param.fs;
            
            mixture = double(out.mecg) + sum(cat(3,out.fecg{:}),3) ...
                + noise;     % re-creating abdominal mixture
            mixture = mixture./3000;    % removing gain given during int conversion
            refs = zeros(length(refchs),length(mixture)/(fs/fs_new));
            for j = 1:length(refchs)
                refs(j,:) = resample(mixture(refchs(j),:),fs_new,fs);   % reference maternal channels
            end
            mixture = mixture(ch,:);
            fref = round(out.fqrs{1}/(fs/fs_new));
            mref = round(out.mqrs/(fs/fs_new));
            
            % = preprocessing channels
            ppmixture = zeros(size(mixture,1),size(mixture,2)/(fs/fs_new));
            fecg = ppmixture;
            for j=1:length(ch)
                ppmixture(j,:) = resample(mixture(j,:),fs_new,fs);    % reducing number of channels
                fecg(j,:) = resample(double(out.fecg{1}(j,:))./3000,fs_new,fs);    % propagated FECG signal (unmixed)
                lpmix = filtfilt(b_lp,a_lp,ppmixture(j,:));
                ppmixture(j,:) = filtfilt(b_hp,a_hp,lpmix);
            end
            mixture = ppmixture;
            
%             % == Extraction
            %-------------------
            %ICA Independent Component Analysis
            %-------------------
            disp('ICA extracthion ..')
            loopsec = 60;   % in seconds
            [residual,~,A] = FECGSYN_bss_extraction(mixture,'JADEICA',fs_new,loopsec,1);     % extract using IC
            if iscell(residual)  % treating BSS output
                pad = max(cellfun(@(x) size(x,1),residual));
                for k = 1:length(residual)
                    residual{k} = [residual{k}; zeros(pad-size(residual{k},1),length(residual{k}))];
                end
                residual = cell2mat(residual);
            end
            [fqrs,maxch] = FECGSYN_QRSmincompare(residual,fref,fs_new);    %#ok<*ASGLU> % detect QRS and channel with highest F1
            %== saving results
            save([filename '_JADEICA'],'maxch','residual','fqrs','fref','A')
            clear fqrs residual maxch
            
            % -------------------
            % PCA Principal Component Analysis
            % -------------------
            disp('PCA extraction ..')
            [residual,~,A] = FECGSYN_bss_extraction(mixture,'PCA',fs_new,loopsec,0);     % extract using IC
            if iscell(residual) % treating BSS output
                pad = max(cellfun(@(x) size(x,1),residual));
                for k = 1:length(residual)
                    residual{k} = [residual{k}; zeros(pad-size(residual{k},1),length(residual{k}))];
                end
                residual = cell2mat(residual);
            end
            [fqrs,maxch] = FECGSYN_QRSmincompare(residual,fref,fs_new);    % detect QRS and channel with highest F1
            % == saving results
            save([filename '_PCA'],'maxch','residual','fqrs','fref','A')
            clear fqrs residual maxch loopsec
%             
%             % -------------------
%             % TS-CERUTTI
%             % -------------------
%             disp('TS-CERUTTI extraction ..')
%             % parameters
%             NbCycles = 20;
%             residual = zeros(size(mixture));
%             for j = 1:length(ch)
%                 residual(j,:) = FECGSYN_ts_extraction(mref,mixture(j,:),'TS-CERUTTI',0,...
%                     NbCycles,'',fs_new);
%             end
%             [fqrs,maxch] = FECGSYN_QRSmincompare(residual,fref,fs_new);    % detect QRS and channel with highest F1
%             % == saving results
%             save([filename '_tsc'],'residual','maxch','fqrs','fref');
%             clear maxch residual fqrs
%             
%             % -------------------
%             % TS-PCA
%             % -------------------
%             disp('TS-PCA extraction ..')
%             % parameters
%             NbPC = 2;
%             residual = zeros(size(mixture));
%             for j = 1:length(ch)
%                 residual(j,:) = FECGSYN_ts_extraction(mref,mixture(j,:),'TS-PCA',0,...
%                     NbCycles,NbPC,fs_new);
%             end
%             [fqrs,maxch] = FECGSYN_QRSmincompare(residual,fref,fs_new);    % detect QRS and channel with highest F1
%             % == saving results
%             save([filename '_tspca'],'residual','maxch','fqrs','fref');
%             
%             clear maxch residual fqrs NbCycles NbPC
%             
%             % ----------------------------
%             % EKF Extended Kalman Filter
%             % ----------------------------
%             disp('EKF extraction ..')
%             NbCycles = 30; % first 30 cycles will be used for template generation
%             residual = zeros(size(mixture));
%             for j = 1:length(ch)
%                 residual(j,:) = FECGSYN_kf_extraction(mref,mixture(j,:),NbCycles,fs_new);
%             end
%             [fqrs,maxch] = FECGSYN_QRSmincompare(residual,fref,fs_new);    % detect QRS and channel with highest F1
%             save([filename '_tsekf'],'residual','maxch','fqrs','fref');
%             % == saving results
%             clear maxch residual fqrs NbCyclesmat
%             % ----------------------
%             % LMS Least Mean Square
%             % ----------------------
%             disp('LMS extraction ..')
%             %parameters
%             refch = 1;      % pick reference channel
%             mirrow = 30*fs_new;    % mirrow 30 seconds of signal to train method
%             % channel loop
%             residual = zeros(size(mixture));
%             for j = 1:length(ch)
%                 res = FECGSYN_adaptfilt_extraction([mixture(j,mirrow:-1:1) mixture(j,:)], ...
%                     [refs(refch,mirrow:-1:1) refs(refch,:)],'LMS',debug,fs_new);
%                 residual(j,:) = res(mirrow+1:end);
%             end
%             [fqrs,maxch] = FECGSYN_QRSmincompare(residual,fref,fs_new);    % detect QRS and channel with highest F1
%             % == saving results
%             save([filename '_alms'],'residual','maxch','fqrs','fref');
%             clear maxch residual fqrs lmsStruct
%             
%             % ----------------------
%             % RLS Recursive Least Square
%             % ----------------------
%             disp('RLS extraction ..')
%             % channel loop
%             residual = zeros(size(mixture));
%             for j = 1:length(ch)
%                 res = FECGSYN_adaptfilt_extraction([mixture(j,mirrow:-1:1) mixture(j,:)],...
%                     [refs(refch,mirrow:-1:1) refs(refch,:)],'RLS',debug,fs_new);
%                 residual(j,:) = res(mirrow+1:end);
%             end
%             [fqrs,maxch] = FECGSYN_QRSmincompare(residual,fref,fs_new);    % detect QRS and channel with highest F1
%             % == saving results
%             save([filename '_arls'],'residual','maxch','fqrs','fref');
%             clear maxch residual fqrs rlsStruct
%             
%             % ----------------------
%             % ESN Echo State Neural Network
%             % ----------------------
%             disp('ESN extraction ..')
%             % channel loop
%             residual = zeros(size(mixture));
%             for j = 1:length(ch)
%                 res = FECGSYN_adaptfilt_extraction([mixture(j,mirrow:-1:1) mixture(j,:)]...
%                     ,[refs(refch,mirrow:-1:1) refs(refch,:)],'ESN',debug,fs_new);
%                 residual(j,:) = res(mirrow+1:end);
%             end
%             [fqrs,maxch] = FECGSYN_QRSmincompare(residual,fref,fs_new);    % detect QRS and channel with highest F1
%             % == saving results
%             save([filename '_aesn'],'residual','maxch','fqrs','fref');
%             clear maxch residual fqrs ESNparam
        end
    end
end

%% Generate Results
FECGSYN_genresults(path,fs_new,ch,exp3)


