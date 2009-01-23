function [L2_error,NMAE_error,NMAE_round_error] = computeTestErrorWeak(model,Y,Ytest)
%
% [error_L2,error_NMAE,error_NMAE_round] = computeTestErrorWeak(model,Y,Ytest)
 
val_L2 = 0;
tot_L2 = 0;
val_NMAE = 0;
tot_NMAE = 0;
val_round_NMAE = 0;
tot_round_NMAE = 0;
accum = [];

for i = 1:size(Y, 2)       
    ind = find(Ytest(:, i));
    elim = find(ind>size(model.X, 1));
    tind = ind;
    tind(elim) = [];
    [mu, varsig] = collabPosteriorMeanVar(model, Y(:, i), model.X(tind, :));
    % normalize the values

    %if (length(mu)>0)
    %    mu = mu.*model.sd(tind);
    %    mu = mu+model.mu(tind);
    %end
    a = Ytest(tind, i) - mu; 
    a = [a; Ytest(elim, i)];
    val_L2 = val_L2 + a'*a;
    tot_L2 = tot_L2 + length(a);
    val_NMAE = val_NMAE + sum(abs(a));
    tot_NMAE = tot_NMAE + length(a);
    val_round_NMAE = val_round_NMAE + sum(abs(round(a)));
    tot_round_NMAE = tot_round_NMAE + length(a);
    accum = [accum; abs(a)];
end
L2_error = sqrt(val_L2/tot_L2);
NMAE_error = (val_NMAE/tot_NMAE)/1.6;
NMAE_round_error = (val_round_NMAE/tot_round_NMAE)/1.6;
