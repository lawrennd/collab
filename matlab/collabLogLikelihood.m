function ll = collabLogLikelihood(model, y)

% COLLABLOGLIKELIHOOD Compute the log likelihood of a COLLAB.
% FORMAT
% DESC computes the log likelihood of a data set given a COLLAB model.
% ARG model : the COLLAB model for which log likelihood is to be
% computed.
% RETURN ll : the log likelihood of the data in the COLLAB model.
%
% SEEALSO : collabCreate, collabLogLikeGradients, modelLogLikelihood
%
% COPYRIGHT : Neil D. Lawrence, 2009

% COLLAB

  ll = 0;
  for i = 1:size(y, 2)
    ind = find(y(:, i));
    K = kernCompute(model.kern, model.X(ind, :));
    if model.heteroNoise
      n = length(ind);
      K = K + spdiags(model.diagvar(ind, :), 0, n, n);
    end
    [invK, U] = pdinv(K);
    logDetK = logdet(K, U);
    yind = y(ind, i);
    ll = ll - 0.5*logDetK - 0.5*yind'*invK*yind;
  end
end