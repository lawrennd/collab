function [error_L2,error_NMAE,error_NMAE_round] = computeTestErrorStrong(model,Ytest)
%
% [error_L2,error_NMAE,error_NMAE_round] = computeTestErrorStrong(model,Ytest);
%
% compute the test error for Strong experiments

val_L2 = 0;
tot_L2 = 0;
val_NMAE = 0;
tot_NMAE = 0;
val_NMAE_round = 0;
tot_NMAE_round = 0;

for i = 1:size(Ytest, 2)       
  ind = find(Ytest(:, i));
  elim = find(ind>size(model.X, 1));
  tind = ind;
  tind(elim) = [];
  
  if (length(tind)==0)
      continue;
  end
  % in the case of STRONG experiments, the user is new, so we have to
  % compute the prediction using the test data
  % compute random (LOO --> leave one out)
  indexRand = randperm(length(tind));
  Y_train_user = Ytest(:,i);
  Y_test_user = Y_train_user(tind(indexRand(end)));
  Y_train_user(tind(indexRand(end)),:) = 0;
  [mu, varsig] = collabPosteriorMeanVar(model, Y_train_user, model.X(tind(indexRand(end)), :));
  a = Y_test_user - mu; 
  a = [a; Ytest(elim, i)];
  val_L2 = val_L2 + a'*a;
  tot_L2 = tot_L2 + length(a);
  val_NMAE = val_NMAE + sum(abs(a));
  tot_NMAE = tot_NMAE + length(a);
  val_NMAE_round = val_NMAE_round + sum(abs(round(a)));
  tot_NMAE_round = tot_NMAE_round + length(a);
end
error_L2 = sqrt(val_L2/tot_L2);
error_NMAE = (val_NMAE/tot_NMAE)/1.6;
error_NMAE_round = (val_NMAE_round/tot_NMAE_round)/1.6;
