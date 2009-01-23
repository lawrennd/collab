function gX = rbfAdditionalKernDiagGradX(kern, X)

% RBFADDITIONALKERNDIAGGRADX Gradient of RBF kernel's diagonal with respect to X.
%
%	Description:
%
%	GX = RBFADDITIONALKERNDIAGGRADX(KERN, X) computes the gradient of the diagonal
%	of the radial basis function kernel matrix with respect to the
%	elements of the design matrix given in X.
%	 Returns:
%	  GX - the gradients of the diagonal with respect to each element of
%	   X. The returned matrix has the same dimensions as X.
%	 Arguments:
%	  KERN - the kernel structure for which gradients are being
%	   computed.
%	  X - the input data in the form of a design matrix.
%	
%
%	See also
%	RBFADDITIONALKERNPARAMINIT, KERNDIAGGRADX, RBFADDITIONALKERNGRADX


%	Copyright (c) 2009 Raquel Urtasun
% 	rbfAdditionalKernDiagGradX.m version 1.0


gX = zeros(size(X));

