% This file allows to read a campaign of the ORION-AE datasets.
%
%
%   [1] Emmanuel Ramasso, Thierry Denoeux, Gael Chevallier, Clustering 
%   acoustic emission data stream with sequentially appearing clusters 
%   using mixture models, Mechanical Systems and Signal Processing, 2021.
%
%   [2] Benoit Verdin, Gaël Chevallier, Emmanuel Ramasso, "ORION-AE: 
%   Multisensor acoustic emission datasets reflecting supervised 
%   untightening of bolts in a jointed structure under vibration", 
%   DOI: https://doi.org/10.7910/DVN/FBRDU0, Harvard Dataverse, 2021.
%
% 
% Emmanuel Ramasso, April 2021
% emmanuel.ramasso@femto-st.fr
%

% 1. First download the datasets: https://doi.org/10.7910/DVN/FBRDU0
% and unzip the files. 

% 2. Look at the doc/DIB paper to understand the dataset.

% 3. Next select the folder below - note the unix notation below
% this folder corresponds to a full campaign (so made of subdirectories)
campaigndirectoryname = uigetdir('/home/emmanuelramasso/OneDrive/Documents/RECHERCHE/3-PROJETS/Coalescence_IRT/manip ORION/mars 2019/session 6/data brute','Select the campaign directory');
%campaigndirectoryname = uigetdir('/home','Select the campaign directory');
campaignName = strsplit(campaigndirectoryname,filesep); 
campaignName = campaignName{end};

% 4. list subdirectories, should be 5cNm, 10cNm, 20cNm... 60cNm, except for
% campaign C where 40 is missing
% be careful the levels are in this order, from 60 to 05 so read it like
% this (the "dir" command will give you the reverse order!)
known_tightening_levels = {'60cNm','50cNm','40cNm','30cNm','20cNm','10cNm','05cNm'};
theoreticalnbOfLevels = length(known_tightening_levels);

% 5. Open and manage files
timestamps_startChunk = 0;        % timestamps start at 0 for the first subdir and next we have to
                                  % update a counter for all files and following subdirs
samplingfrequency = 5e6;          % this is the sampling frequency for all channels
durationOftighteningLevels = [0]; % total duration for each tightening level, vector with 7 or 6 elements
levelRead = true(1,theoreticalnbOfLevels);
sensor = 'C'; % 'A' 'B' 'C' % will extract the data one of the three AE sensors + vibrometer
        
for i=1:theoreticalnbOfLevels
    
    % current dir
    d = [campaigndirectoryname filesep known_tightening_levels{i}]; 
    files = dir([d filesep '*.mat']); % suppose you did not modify anything inside    
    levelRead(i) = length(files)>0; % there is one case where one level is missing
    
    % for campaign C, j start at 0 so it is fine
    for j=1:length(files) % open each file in current subdir - one chunk per file
        
        % you can load everything -> lot of data
        % or you can load just one sensor, for example sensor A = micro80
        % data = load([files(j).folder filesep files(j).name],'A');
        % so that data.A contains sensor data
        % now you can treat those data as you want, for example to extract
        % features. You can similarly extract B or C, for sensor F50A or
        % micro200HF respectively. The latter seems to be the best for this
        % application.
        datamicro200HF = load([files(j).folder filesep files(j).name],sensor);
        % you can also extract the vibrometry data
        datavibro = load([files(j).folder filesep files(j).name],'D');
        % Let superimpose both
        if j==1 %&& i==1 % condition to avoid plot of figures each time 
            timeVector = timestamps_startChunk + (1:length(datamicro200HF.(sensor)))/samplingfrequency;
            
            % we subsample just for the saveas figures
            figure(1),clf,plot(timeVector(1:1:end),datamicro200HF.(sensor)(1:1:end)), 
            ylabel('AE data stream (mv)'),axis tight
            set(gca,'fontsize',22), xlabel('Time (s)'),hold on, yyaxis right,
            plot(timeVector(1:500:end),datavibro.D(1:500:end)), 
            ylabel('Vibrometer data (mv)'),axis tight
            set(gcf,'Position',[133          69        1658         831])
            %print(gcf, ['sample_' campaignName '.pdf'], '-dpdf', '-opengl', '-r150','-bestfit');
            exportgraphics(gcf, ['sample_sensor' sensor '_level_' known_tightening_levels{i} '_' campaignName '.pdf'], 'Resolution', 300);
            %saveas(gcf,['sample_sensor' sensor '_level_' known_tightening_levels{i} '_' campaignName],'fig');
            
            zoomT = find(timeVector-timestamps_startChunk>0.3 & timeVector-timestamps_startChunk<0.35);
            figure(2),clf,plot(timeVector(zoomT),datamicro200HF.(sensor)(zoomT)), ylabel('AE data stream (mV)'),axis tight
            set(gca,'fontsize',22);
            xlabel('Time (s)')
            yyaxis right, plot(timeVector(zoomT(1:500:end)),datavibro.D(zoomT(1:500:end))), ylabel('Vibrometer data (mV)'),axis tight
            set(gcf,'Position',[133          69        1658         831])
            %print(gcf, ['sample_zoom' campaignName '.pdf'], '-dpdf', '-opengl', '-r150','-bestfit');
            exportgraphics(gcf,['sample_zoom_sensor' sensor '_level_' known_tightening_levels{i} '_' campaignName '.pdf'], 'Resolution', 300);
            %saveas(gcf,['sample_zoom_sensor' sensor '_level_' known_tightening_levels{i} '_' campaignName],'fig');
            
        end
                
        % ##############  
        % for all AE signals in the chunk do:
            % Extract an AE signal (made at "random" below) just to illustrate
            onsetAEsignal = randi(length(datamicro200HF.(sensor))-1999);
            endAEsignal = onsetAEsignal + 1999; % 2000 samples length here
            % extract your features, for example amplitude and rms
            AEhit = datamicro200HF.(sensor)(onsetAEsignal:endAEsignal);
            features = [max(abs(AEhit)), rms(AEhit)];
            % this is the timestamps attached to this particular AE hit
            timeStampsAEhit = timestamps_startChunk + onsetAEsignal / samplingfrequency;
        % end for
        % ##############  to be repeated for all signals in the chunks
        
        % for AE signals in next chunks, the timestamps start at
        timestamps_startChunk = timestamps_startChunk + length(datamicro200HF.(sensor)) / samplingfrequency; 

    end
    
    % update the duration of tightening levels
    durationOftighteningLevels = [durationOftighteningLevels, timestamps_startChunk];
    durationOfCurrentLevel = durationOftighteningLevels(end)-durationOftighteningLevels(end-1);
    fprintf('Level %s in campaign %s has a duration of %f\n',known_tightening_levels{i},campaignName,durationOfCurrentLevel);
    
end
% remove 0
durationOftighteningLevels(not(levelRead))=[];
durationOftighteningLevels = diff(durationOftighteningLevels);
assert(sum(double(levelRead))==length(durationOftighteningLevels));
fprintf('Total number of levels: %d\n',length(durationOftighteningLevels));
fprintf('Total duration of this campaign: %f\n', sum(durationOftighteningLevels));


    


