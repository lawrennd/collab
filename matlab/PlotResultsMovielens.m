function [L2_error_T,NMAE_error_T,NMAE_round_error_T] = PlotResultsMovielens(perc_train_v,substract_mean,partNo_v,latentDim_v)
%
% [L2_error_T,NMAE_error,NMAE_round_error] = PlotResultsMovielens(perc_train,substract_mean,partNo_v,latentDim_v)
%
% perc_train_v -> percentage of training
% substract_mean --> bool if substract the mean
% partNo_v --> vector with the partitions to compute results
% latentDim_v --> vector with the latent dimensionalities to compute results

  for i_perc=1:length(perc_train_v)
    perc_train = perc_train_v(i_perc);
for i_latent=1:length(latentDim_v)
    q = latentDim_v(i_latent);
    for i_part=1:length(partNo_v)
        partNo = partNo_v(i_part);

        dataSetName = ['movielens_',num2str(perc_train),'_',num2str(partNo)];
        


        % Save the results.
        capName = dataSetName;
        capName(1) = upper(capName(1));
        
        loadResults = [capName,'_norm_',num2str(substract_mean),'_',num2str(q),'_',num2str(partNo),'.mat'];
        disp(['Loading ... ',loadResults]);
        load(loadResults);
L2_error_T(i_perc,i_latent,i_part) = L2_error;
NMAE_error_T(i_perc,i_latent,i_part) = NMAE_error;
NMAE_round_error_T(i_perc,i_latent,i_part) = NMAE_round_error;
    end
end
end


% plot the results

mean_L2 = mean(L2_error_T,3);
mean_NMAE = mean(NMAE_error_T,3);
mean_NMAE_round = mean(NMAE_round_error_T,3);
%keyboard;
for i=1:size(mean_L2,1)
  for j=1:size(mean_L2,2)
    std_L2(i,j) = std(permute(L2_error_T(i,j,:),[3 1 2]));
std_NMAE(i,j) = std(permute(NMAE_error_T(i,j,:),[3 1 2]));
std_NMAE_round(i,j) = std(permute(NMAE_round_error_T(i,j,:),[3 1 2]));
end
end

figure(1)
  clf;
hold on;
for i=1:length(latentDim_v)
  % plot(perc_train_v/100,mean_NMAE_round(:,i),[getColor(i),'x']);
errorbar(perc_train_v/100,mean_NMAE_round(:,i),std_NMAE_round(:,i),[getColor(i),'x']);
toLeg{i} = ['Dimension ',num2str(latentDim_v(i))];
end
xlabel('percentage database');
ylabel('NMAE round error');
legend(toLeg);
end


function [value] = getColor(index)
switch index
  case 1
value = 'r-';
case 2
value = 'b-';
case 3
value = 'g--'
  case 4
value = 'm--';
case 5
value = 'k-'
end
end
