function NS = ns_summary_statistics(NS)

% models to eval:
labels_beta={{'bb','',''},{'','g',''},{'bb','g',''},{'','','a'},...
    {'bb','','a'},{'','g','a'},{'bb','g','a'}};

reg_out = struct('stats', [], 'beta', []); 
% reg_out.stats: training r2, training adjust r2, cross-validated r2
% reg_out.beta: training beta, first one is intercept

    
for bs=1:size(NS.data.bold_bs,2) % number of bootstraps
    % get TRAINING data
    % average EVEN trials across repeats of the even stimuli
    bold_even    = NS.data.bold_bs_even(:,bs);
    bb_even      = NS.data.bb_even(:,bs);
    gamma_even   = NS.data.gamma_even(:,bs);
    alpha_even   = NS.data.alpha_even(:,bs);

    % vector length normalize:
    data_to_norm = {'bold','bb','gamma','alpha'};
    trials_to_norm = {'even'};
    for k = 1:length(data_to_norm)
        for ii = 1:length(trials_to_norm)
            to_norm = [data_to_norm{k} '_' trials_to_norm{ii}];
            eval([to_norm '=' to_norm '/sqrt(sum(' to_norm '.^2));']);
        end
    end

    % training data
    lfp_in{1}.data=[bb_even];
    lfp_in{2}.data=[gamma_even];
    lfp_in{3}.data=[bb_even gamma_even];
    lfp_in{4}.data=[alpha_even];
    lfp_in{5}.data=[bb_even alpha_even];
    lfp_in{6}.data=[gamma_even alpha_even];
    lfp_in{7}.data=[bb_even gamma_even alpha_even];
    % model training
    for m=1:length(lfp_in)
        stats1 = regstats(bold_even,lfp_in{m}.data); % stats.beta, first one is intercept
        reg_out(m).stats(bs,1)=stats1.rsquare;
        reg_out(m).stats(bs,2)=stats1.adjrsquare;
        reg_out(m).beta(bs,:)=stats1.beta; % 1 is the intercept                       

        % shuffle the data for training floor
        stats1 = regstats(bold_even(randperm(length(bold_even))),lfp_in{m}.data);
        reg_out(m).stats_shuffled(bs,1)=stats1.rsquare;
        reg_out(m).stats_shuffled(bs,2)=stats1.adjrsquare;
        reg_out(m).beta_shuffled(bs,:)=stats1.beta; % 1 is the intercept
            

    end
    
    
    clear lfp_in
end

for bs=1:size(NS.data.bold_bs,2) % number of bootstraps
   % get TESTING data
    % average ODD trials across repeats of the even stimuli
    bold_odd    = NS.data.bold_bs_odd(:,bs);
    bb_odd      = NS.data.bb_odd(:,bs);
    gamma_odd   = NS.data.gamma_odd(:,bs);
    alpha_odd   = NS.data.alpha_odd(:,bs);

    % vector length normalize:
    data_to_norm = {'bold','bb','gamma','alpha'};
    trials_to_norm = {'odd'};
    for k = 1:length(data_to_norm)
        for ii = 1:length(trials_to_norm)
            to_norm = [data_to_norm{k} '_' trials_to_norm{ii}];
            eval([to_norm '=' to_norm '/sqrt(sum(' to_norm '.^2));']);
        end
    end

    % testing data
    lfp_in{1}.data=[bb_odd];
    lfp_in{2}.data=[gamma_odd];
    lfp_in{3}.data=[bb_odd gamma_odd];
    lfp_in{4}.data=[alpha_odd];
    lfp_in{5}.data=[bb_odd alpha_odd];
    lfp_in{6}.data=[gamma_odd alpha_odd];
    lfp_in{7}.data=[bb_odd gamma_odd alpha_odd];
    % model testing
    for m=1:length(lfp_in)
        reg_parms=squeeze(median(reg_out(m).beta,1)); % median beta from training set
        pred_bold=reg_parms(1) + lfp_in{m}.data*reg_parms(2:end)';
        %reg_out(m).stats(bs,3)=corr(pred_bold,bold_odd).^2;
        reg_out(m).stats(bs,3)=ns_cod(pred_bold,bold_odd, false);
        
        reg_parms=reg_out(m).beta_shuffled(bs,:); 
        pred_bold=reg_parms(1) + lfp_in{m}.data*reg_parms(2:end)';
        reg_out(m).stats_shuffled(bs,3)=ns_cod(pred_bold,bold_odd, false);
        
    end
    clear lfp_in
end
    
for m = 1:length(reg_out)
    reg_out(m).inputs = labels_beta{m};
end

NS = ns_set(NS,'stats',reg_out);
