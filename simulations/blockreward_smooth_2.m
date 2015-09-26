% --------------------------------------------------------------------------------------------------
% m-script for FreeMat v4.0 (Matlab clone with GPLv2 license)
% Download for all operating systems: http://freemat.sourceforge.net/download.html
%
% --------------------------------------------------------------------------------------------------
% This script calculates block reward and money supply for a modified, more continuously decreasing,
% Bitcoin emission schedule.
%
% In comparison, original Bitcoin schedule.
%
%
% The new Block Reward (BR) schedule:
%
% d = 0.92307693620387;
%
% BR = 50.00000000 BTC for 210,000 blocks (blocks         1..  210,000) --> divide by 2 -->
% BR = 25.00000000 BTC for 210,000 blocks (blocks   210,001..  420,000) --> divide by 2 -->
% BR = 12.50000000 BTC for 210,000 blocks (blocks   420,001..  630,000) --> divide by 2 -->
% BR =  6.25000000 BTC for 105,000 blocks (blocks   630,000..  735,000) --> times d, round down: -->
% BR =  5.76923085 BTC for  26,250 blocks (blocks   735,001..  761,250) --> times d, round down: -->
% BR =  5.32544393 BTC for  26,250 blocks (blocks   761,250..  787,500) --> times d, round down: -->
% BR =  4,91579446 BTC for  26,250 blocks (blocks   787,501..  813,750) --> times d, round down: -->
% ...
% BR =  0.00000004 BTC for  26,250 blocks (blocks 6,615,001..6,641,250) --> times d, round down: -->
% BR =  0.00000003 BTC for  26,250 blocks (blocks 6,641,251..6,667,500) --> times d, round down: -->
% BR =  0.00000002 BTC for  26,250 blocks (blocks 6,667,501..6,693,750) --> times d, round down: -->
% BR =  0.00000001 BTC for  26,250 blocks (blocks 6,693,751..6,720,000)
%
%...and the remaining 78,750 satoshis are distributed over the next 78,750 blocks:
% BR =  0.00000001 BTC for  78,750 blocks (blocks 6,720,001..6,798,750)
%
% ...and finally (after ca. 129.25 years):
% BR =  0.00000000 BTC for blocks >= 6,798,751.
%
%
% For comparison: With original schedule, the last block reward of 1 satoshi is payed in at block
% height 6,930,000 after ca. 131.75 years.
%
% --------------------------------------------------------------------------------------------------
clear all; close all;

delta_t = 210000;%[210000] time between block halvings
block_time_min = 10;%[10]

keep_constant_reward_till_this_block = 3.5*delta_t;%[=0 or =1] (is the same) - for "bip" method only

reward     = 50;% initial reward
reward_bip = 50;% initial reward
reward_bip_2nd = 6.25;% 6.25 BTC initial reward when continuous decay start
decrease_every=26250;  % block reward gets reduced by multiplication with "d" every 26250 blocks

d = 0.92307693620387;% factor of continuous reduction
d = (2^38-21144450772)/2^38;

% Adaptation, to have exactly 20,999,999.9769 BTC at the end:
mine_min = 1;% satoshis to mine minimum
mine_zero_from = 6798751;%block height


Nsim = 34;%[33] nb of "delta_t blocks" intervals to simulate

% --------------------------------------------------------------------------------------------------
% lookup tables for faster modulo calculation:
lut_mod=[2:1:decrease_every, 1];% e.g. [2, 3, 4, 1]

accu     = 0;
accu_bip = 0;

rew_org = nan*ones(1,Nsim*delta_t);
rew_bip = nan*ones(1,Nsim*delta_t);
sum_org = nan*ones(1,Nsim*delta_t);
sum_bip = nan*ones(1,Nsim*delta_t);
cnt_dec=1;
cnt_cycl = 1;
for k = 1:Nsim,
    tmpstr1 = num2str(reward,'%011.8f'); tmpstr2 = num2str(reward_bip,'%011.8f');
    pause(0.1);% to avoid artifacts of printing out 0.00000000 or 1.00000000 instead of the proper values
    disp(['BlockReward step ',num2str(k,'%02d'), ': reward_org=', tmpstr1, ', reward_bip=', tmpstr2]);
    pause(0.1);% to avoid artifacts of printing out 0.00000000 or 1.00000000 instead of the proper values
    for block = 1:delta_t,
        accu     = round(1e8*(accu     + reward    ))/1e8;% last satoshi block reward in block 6930000
        accu_bip = round(1e8*(accu_bip + reward_bip))/1e8;
        blockHeight = (k-1)*delta_t+block;
        rew_org(blockHeight) =reward;
        rew_bip(blockHeight) =reward_bip;
        sum_org(blockHeight) = accu;
        sum_bip(blockHeight) = accu_bip;
        % Calculate BlockReward (BR) for next block:
        if blockHeight >= keep_constant_reward_till_this_block,
            if cnt_dec==1,
                reward_bip = floor(reward_bip * d * 1e8)/1e8;
                % ---------- <SPECIAL> ----------
                reward_bip = max(reward_bip, mine_min*1e-8);% minimum mine_min satoshis
                if blockHeight+1 >= mine_zero_from,
                    reward_bip=0;% final money supply will be same as orig. BTC schedule
                end
                % ---------- </SPECIAL> ----------
            end
            cnt_dec = lut_mod(cnt_dec);
        end
    end
    reward = floor(reward*1e8 / 2)/1e8;
    if blockHeight < keep_constant_reward_till_this_block,
        reward_bip = floor(reward_bip*1e8 / 2)/1e8;
    end
end
accu      % 20,999,999.9769000 BTC
accu_bip
(accu_bip-accu)
%find(rew_bip==0,1) - find(rew_org==0,1)


% ----------Plot: ----------
figure;
hold on;
plot([1:length(rew_org(1:1440/block_time_min:end))]/365.25,rew_org(1:1440/block_time_min:end), ...
    'b');% plot 1 dot per day
plot([1:length(rew_bip(1:1440/block_time_min:end))]/365.25,rew_bip(1:1440/block_time_min:end), ...
    'r');% plot 1 dot per day
grid on;
title('Block Reward vs. Time')
xlabel('Years')
ylabel('Coins')
legend('Bitcoin Original','Bitcoin Continuous')
sizefig(600,500);

figure;
hold on;
plot([1:length(rew_org(1:1440/block_time_min:end))]/365.25,rew_org(1:1440/block_time_min:end), ...
    'b-.');% plot 1 dot per day
plot([1:length(rew_bip(1:1440/block_time_min:end))]/365.25,rew_bip(1:1440/block_time_min:end), ...
    'r-.');% plot 1 dot per day
grid on;
title('Block Reward vs. Time - Zoomed')
xlabel('Years')
ylabel('Coins')
legend('Bitcoin Original','Bitcoin Continuous')
sizefig(600,500);
%axis([50 140 0 1e-3]) % view ooption 1
axis([90 135 0 1e-5]) % view ooption 2
%axis([120 140 0 1e-7]) % view ooption 3

figure;
hold on;
plot([1:length(sum_org(1:1440/block_time_min:end))]/365.25,sum_org(1:1440/block_time_min:end)/1e6, ...
    'b');% plot 1 dot per day
plot([1:length(sum_bip(1:1440/block_time_min:end))]/365.25,sum_bip(1:1440/block_time_min:end)/1e6, ...
    'r');% plot 1 dot per day
grid on;
title('Money Supply vs. Time')
xlabel('Years')
ylabel('Million Coins')
legend('Bitcoin Original','Bitcoin Continuous','location','southeast')
sizefig(600,500);

figure;
hold on;
plot([1:length(sum_org(1:1440/block_time_min:end))]/365.25,sum_org(1:1440/block_time_min:end)/1e6, ...
    'b');% plot 1 dot per day
plot([1:length(sum_bip(1:1440/block_time_min:end))]/365.25,sum_bip(1:1440/block_time_min:end)/1e6, ...
    'r');% plot 1 dot per day
grid on;
title('Money Supply vs. Time - Zoomed Center')
xlabel('Years')
ylabel('Million Coins')
legend('Bitcoin Original','Bitcoin Continuous','location','southeast')
sizefig(600,500);
axis([14 50 19 21.1])

figure;
hold on;
plot([1:length(sum_org(1:1440/block_time_min:end))]/365.25,sum_org(1:1440/block_time_min:end)/1e6, ...
    'b');% plot 1 dot per day
plot([1:length(sum_bip(1:1440/block_time_min:end))]/365.25,sum_bip(1:1440/block_time_min:end)/1e6, ...
    'r');% plot 1 dot per day
grid on;
title('Money Supply vs. Time - Zoomed End')
xlabel('Years')
ylabel('Million Coins')
legend('Bitcoin Original','Bitcoin Continuous','location','southeast')
sizefig(600,500);
axis([50 150. 20.999 21.0002])
