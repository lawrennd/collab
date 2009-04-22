function [g, g_param, g_diag] = collabLogLikeGradients(model, y)
  
% COLLABLOGLIKEGRADIENTS Gradient of the latent points.
% FORMAT 
% DESC computes the gradient of the latent points given ratings as a
% sparse matrix.
% ARG model : the model of the data.
% ARG y : the ratings for an individual.
%
% SEEALSO : collabLogLikelihood
%
% COPYRIGHT : Neil D. Lawrence, 2008, 2009
  
% COLLAB

  g_param = zeros(1, model.kern.nParams);
  
  if iscell(y)
    fullInd = y{1, 1};
  else
    fullInd = find(y);
  end

  g = spalloc(size(model.X, 1), size(model.X, 2), length(fullInd)*model.q);
  if model.heteroNoise
    g_diag = spalloc(size(model.X, 1), 1, length(fullInd));
  else
    g_diag = [];
  end
  maxBlock = ceil(length(fullInd)/ceil(length(fullInd)/1000));
  span = 0:maxBlock:length(fullInd);
  if rem(length(fullInd), maxBlock)
    span = [span length(fullInd)];
  end
  
  for block = 2:length(span)
    ind = fullInd(span(block-1)+1:span(block));
    
    if iscell(y)
      yuse = double(y{1, 2}(span(block-1)+1:span(block)));
    else
      yuse = y(ind, 1);
    end
    X = model.X(ind, :);
    N = length(ind);
    if ~isfield(model, 'noise') || isempty(model.noise)
      yprime = (yuse-model.mu(ind))./model.sd(ind);
      K = kernCompute(model.kern, X);
      if model.heteroNoise
        n = length(ind);
        K = K + spdiags(model.diagvar(ind, :), 0, n, n);
      end
      invK = pdinv(K);
      invKy = invK*yprime;
      gK = -invK + invKy*invKy';
      
      %%% Prepare to Compute Gradients with respect to X %%%
      gKX = kernGradX(model.kern, X, X);
      gKX = gKX*2;
      dgKX = kernDiagGradX(model.kern, X);
      for i = 1:length(ind)
        gKX(i, :, i) = dgKX(i, :);
      end
      gX = zeros(N, model.q);
      
      counter = 0;
      for i = 1:N
        counter = counter + 1;
        for j = 1:model.q
          gX(i, j) = gX(i, j) + gKX(:, j, i)'*gK(:, counter);
        end
      end
      g(ind, :) = gX;
      g_param = g_param + kernGradient(model.kern, X, gK);

      if model.heteroNoise
        g_diag(ind, :) = diag(gK);
      end
      
    else
      yuse = yuse-1; % make yuse start from zero.
      % Create an IVM model and update site parameters.
      options = ivmOptions;
      options.kern = model.kern;
      options.noise = model.noise;
      options.selectionCriterion = model.selectionCriterion;
      options.numActive = min(model.numActive, N);
      imodel = ivmCreate(model.q, 1, X, yuse, options);
      imodel = ivmOptimiseIVM(imodel, options.display);
      gX = gplvmApproxLogLikeActiveSetGrad(imodel);
      gX = reshape(gX, length(imodel.I), size(imodel.X, 2));
      g(ind(imodel.I), :) = gX;
      g_param = g_param + ivmApproxLogLikeKernGrad(imodel);
    end
  end
end