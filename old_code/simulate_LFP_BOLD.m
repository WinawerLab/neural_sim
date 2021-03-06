%% ECOG BOLD simulation

% Purpose: Simulate neural data - time varying membrane potentials - and
% then ask whether the simulated BOLD signal and various metrics of the
% simulated field potentials are correlated.

% Set default parameters.
NS = neural_sim_defaults; 
% Change these to change the simulation. 

NS = ns_set(NS, 'save_inputs', 1);
NS = ns_set(NS, 'num_neurons', 200); 
NS = ns_set(NS, 'poisson_baseline', .5); 
NS = ns_set(NS, 'poisson_bb_rg', [0 .8]); % .5 for low bb correlation, .8/1 for high
NS = ns_set(NS, 'poisson_g_val', .5);
NS = ns_set(NS, 'poisson_a_rg', [0 .5]); 
NS = ns_set(NS, 'gamma_coh_rg', [0 .3]); 
NS = ns_set(NS, 'num_conditions',8);

whichInput = 1;
switch whichInput
    case 1
        % *** INPUT 1
        NS = ns_set(NS, 'save_inputs', 0);
        NS = ns_set(NS, 'num_neurons', 1);
        NS = ns_set(NS, 'poisson_baseline', .5);
        NS = ns_set(NS, 'poisson_bb_rg', [0 .8]); % .5 for low bb correlation, .8/1 for high
        NS = ns_set(NS, 'poisson_g_val', 0);
        NS = ns_set(NS, 'poisson_a_rg', [0 0]);
        NS = ns_set(NS, 'gamma_coh_rg', [0 0]);
        NS = ns_set(NS, 'num_conditions',2);
        NS = ns_set(NS, 'num_averages', 10);
    case 2
        %% *** INPUT 2
        NS = ns_set(NS, 'save_inputs', 0);
        NS = ns_set(NS, 'num_neurons', 200);
        NS = ns_set(NS, 'poisson_baseline', .5);
        NS = ns_set(NS, 'poisson_bb_rg', [0 0]); % .5 for low bb correlation, .8/1 for high
        NS = ns_set(NS, 'poisson_g_val', 0.5);
        NS = ns_set(NS, 'poisson_a_rg', [0 0]);
        NS = ns_set(NS, 'gamma_coh_rg', [0 0.3]);
        NS = ns_set(NS, 'num_conditions',2);
        NS = ns_set(NS, 'num_averages', 10);

    case 3
        % *** INPUT 3
        NS = ns_set(NS, 'save_inputs', 0);
        NS = ns_set(NS, 'poisson_bb_rg', [0 0]); % .5 for low bb correlation, .8/1 for high
        NS = ns_set(NS, 'num_neurons', 1);
        NS = ns_set(NS, 'poisson_a_rg', [0 .5]); % .5 for low bb correlation, .8/1 for high
        NS = ns_set(NS, 'gamma_coh_rg', [0 0]);
        NS = ns_set(NS, 'num_conditions',2);
        NS = ns_set(NS, 'poisson_g_val', 0);
        NS = ns_set(NS, 'num_averages', 10);
end
%%
disp(NS.params);

% Assign expected values of broadband and gamma levels for each stimulus class and each trial
NS = ns_make_trial_struct(NS); disp(NS.trial)

% if save_inputs choose trials to save, data can get big if saving a lot
NS = ns_set(NS, 'trials_save_inputs',[1 length(NS.trial.poisson_rate_bb)]);


%%
% Simulate. This will produce a time series for each neuron in each trial
NS = ns_simulate_data(NS); 

% Convert the neural time series into instrument measures
NS = ns_neural2instruments(NS); disp(NS.data)

% Compute the correlations between different instrument measures 
NS = ns_summary_statistics(NS); disp(NS.stats)

%%%% comment here: ns_summary statistics is different from
%%%% ns_mean_by_stimulus for alpha and gamma because the broadband is not
%%%% subtracted in ns_mean_by_stimulus

%% PLOT
bb_avg    = ns_mean_by_stimulus(NS, ns_get(NS, 'bb'));
bold_avg  = ns_mean_by_stimulus(NS, ns_get(NS, 'bold'));
lfp_avg   = ns_mean_by_stimulus(NS, ns_get(NS, 'lfp'));
gamma_avg = ns_mean_by_stimulus(NS, ns_get(NS, 'gamma'));
alpha_avg = ns_mean_by_stimulus(NS, ns_get(NS, 'alpha'));
num_conditions = ns_get(NS, 'num_conditions');
freq_bb = ns_get(NS, 'freq_bb');

fH=figure; clf; set(fH, 'Color', 'w')
fs = [18 12]; % fontsize

% ---- Plot Spectra for different stimuli -----
subplot(1,3,1), set(gca, 'FontSize', fs(1));
plot_colors = [0 0 0; jet(num_conditions)];
set(gca, 'ColorOrder', plot_colors); hold all
% plot(ns_get(NS, 'f'), ns_mean_by_stimulus(NS, ns_get(NS, 'power')), '-', ...
%     freq_bb, exp(ns_get(NS, 'power_law')), 'k-', 'LineWidth', 2);

plot(ns_get(NS, 'f'), ns_mean_by_stimulus(NS, ns_get(NS, 'power')) * ...
    ns_get(NS, 'num_neurons'), '-',  'LineWidth', 2);



set(gca, 'XScale', 'log', 'YScale', 'log')
xlabel ('Frequency')
ylabel('Power')
% xlim([min(freq_bb) max(freq_bb)]);
xlim([1 max(freq_bb)]);

% ---- Plot BOLD v ECoG measures ----------------
num_subplots = 4; % broadband; total LFP; gamma; alpha
x_data = {bb_avg, lfp_avg, gamma_avg, alpha_avg};
xl     = {'broadband', 'Total LFP power', 'Gamma', 'Alpha'};
for ii = 1:num_subplots
    this_subplot = 3*(ii-1)+2;
    subplot(num_subplots,3,this_subplot), set(gca, 'FontSize', fs(2)); hold on
    p = polyfit(x_data{ii}, bold_avg,1);
    scatter(x_data{ii}, bold_avg), axis tight square
    hold on; plot(x_data{ii}, polyval(p, x_data{ii}), 'k-', 'LineWidth', 1)
    xlabel(xl{ii}), ylabel('BOLD')
    title(sprintf('r = %4.2f', corr(x_data{ii}, bold_avg)));
end

% ---- Plot BOLD and ECoG measures as function of simulation inputs -----
num_subplots = 3; % broadband; total LFP; gamma; alpha
x_data_name = {'poisson_bb', 'coherence_g', 'poisson_a'};
xl     = {'Broadband', 'Gamma', 'Alpha'};

for ii = 1:num_subplots
    this_subplot = 3 * (ii-1)+3;
    subplot(num_subplots,3,this_subplot), set(gca, 'FontSize', fs(2));
    x_data = ns_get(NS, x_data_name{ii});
    
    [~, inds] = sort(x_data);
    plot(...
        x_data(inds), zscore(bold_avg(inds)), 'o-',...
        x_data(inds), zscore(bb_avg(inds)),  'd-',...
        x_data(inds), zscore(lfp_avg(inds)),  's-',...
        x_data(inds), zscore(gamma_avg(inds)), 'x-',...
        x_data(inds), zscore(alpha_avg(inds)), '*-',...
        'LineWidth', 3)
    xlabel(sprintf('%s (inputs)', xl{ii})), ylabel('response (z-scores)')
    if ii == 1
        legend({'BOLD', 'Broadband',  'LFP power',  'Gamma', 'Alpha'},...
            'Location', 'Best', 'Box', 'off')
    end
end

% set(gcf,'PaperPositionMode','auto')
% print('-dpng','-r300',['../neural_sim_output/figures/NEW01_bb0_3'])
% print('-depsc','-r300',['../neural_sim_output/figures/NEW01_bb0_3'])

%% check alpha and mean signal and bb
alpha_avg = ns_mean_by_stimulus(NS, ns_get(NS, 'alpha'));
bb_avg  = ns_mean_by_stimulus(NS, ns_get(NS, 'bb'));
gamma_avg  = ns_mean_by_stimulus(NS, ns_get(NS, 'gamma'));
bold_avg  = ns_mean_by_stimulus(NS, ns_get(NS, 'bold'));

all_alpha_input = NS.trial.poisson_rate_a;
all_mean_data = squeeze(mean(sum(NS.data.ts(:,:,:),2),1));
all_alpha_data = NS.data.alpha;
all_gamma_data = NS.data.gamma;
all_bb_data = NS.data.bb;

mean_avg = zeros(max(NS.trial.condition_num),1);
for k=1:max(NS.trial.condition_num)+1
    mean_avg(k) = mean(all_mean_data(NS.trial.condition_num==k-1));
end

figure('Position',[0 0 800 300]),
subplot(2,5,1)
plot(all_alpha_input,all_alpha_data,'k.')
xlabel('alpha input'),ylabel('alpha response')

subplot(2,5,2)
plot(all_alpha_input,all_mean_data,'k.')
xlabel('alpha input'),ylabel('mean response')

subplot(2,5,3)
plot(all_alpha_data,all_mean_data,'k.')
xlabel('alpha response'),ylabel('mean response')

subplot(2,5,4)
plot(all_mean_data,all_bb_data,'k.')
xlabel('mean response'),ylabel('bb response')

subplot(2,5,6)
plot(NS.params.poisson_a,alpha_avg,'k.')
xlabel('alpha input'),ylabel('alpha response')

subplot(2,5,7)
plot(NS.params.poisson_a,mean_avg,'k.')
xlabel('alpha input'),ylabel('mean response')

subplot(2,5,8)
plot(alpha_avg,mean_avg,'k.')
xlabel('alpha response'),ylabel('mean response')

subplot(2,5,9),hold on
plot(mean_avg,bb_avg,'k.')
r1 = corr(mean_avg,bb_avg);
title(['r^2 = ' int2str(r1.^2*100)])
xlabel('mean response'),ylabel('bb response')

subplot(2,5,10),hold on
plot(NS.params.poisson_a',NS.params.poisson_bb','r.')
r2 = corr(NS.params.poisson_a',NS.params.poisson_bb');
title(['r^2 = ' int2str(r2.^2*100)])
xlabel('alpha inputs'),ylabel('bb inputs')

% set(gcf,'PaperPositionMode','auto')
% print('-dpng','-r300',['../figures/alpha_mean_bb_corr4'])
% print('-depsc','-r300',['../figures/alpha_mean_bb_corr4'])

%% correlate over all frequencies 

bold_avg  = ns_mean_by_stimulus(NS, ns_get(NS, 'bold'));

ts_for_fft = squeeze(mean(ns_get(NS, 'ts'),2));

% fft settings just like in the other correlation
fft_w  = hanning(250); % window width
fft_ov = .5*length(fft_w); % overlap
srate  = 1/ns_get(NS,'dt');
% initialize 
[~,f] = pwelch(ts_for_fft(:,1),fft_w,fft_ov,srate,srate);

pxx_all = zeros(size(ts_for_fft,2),length(f));
% loop over trials
for m = 1:size(ts_for_fft,2)
    pxx_all(m,:) = pwelch(ts_for_fft(:,m),fft_w,fft_ov,srate,srate);    
end

%
% f = (0:length(t)-1)/max(t);
% pxx_all = abs(fft(ts_for_fft))';

% mean power by stimulus
pxx_avg = zeros(NS.params.num_conditions,length(f));
for m=1:NS.params.num_conditions
    pxx_avg(m,:) = mean(pxx_all(NS.trial.condition_num==m-1,:));
end

% power change
pxx_change = bsxfun(@minus, log(pxx_avg), log(pxx_avg(1,:)));
r = zeros(size(pxx_change,2),1);

for m=1:length(f)
    r(m) = corr(bold_avg,pxx_change(:,m));
    %r(m) = corr(bold_avg,pxx_avg(:,m));
end

figure('Position',[0 0 200 150]),hold on
plot(f,zeros(size(f)),'Color',[.5 .5 .5])
plot(f,r,'k','LineWidth',2)
xlabel('Frequency'),ylabel('correlation with BOLD (r)')
xlim([0 200])
ylim([-1 1])

% set(gcf,'PaperPositionMode','auto')
% print('-dpng','-r300',['../neural_sim_output/figures/NEW01_bb0_3_allfreq'])
% print('-depsc','-r300',['../neural_sim_output/figures/NEW01_bb0_3_allfreq'])

%% show some signals

figure
subplot(2,1,1)
plot(squeeze(sum(NS.data.ts(:,:,1),2)))
title('sum of ts in trial with high alpha')
a = find(NS.trial.coherence_rate_a==0,1);
subplot(2,1,2)
plot(squeeze(sum(NS.data.ts(:,:,a),2)))
title('sum of ts in trial with 0 alpha')

%%
figure
subplot(2,1,1)
plot(squeeze(NS.data.ts(:,1,1)))
title('sum of ts in trial with high alpha')
a = find(NS.trial.poisson_rate_a==0,1);
subplot(2,1,2)
plot(squeeze(NS.data.ts(:,1,a)))
title('sum of ts in trial with 0 alpha')
