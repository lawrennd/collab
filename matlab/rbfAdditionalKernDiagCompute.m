function k = rbfAdditionalKernDiagCompute(kern, x)

% RBFADDITIONALKERNDIAGCOMPUTE Compute diagonal of RBF kernel.
%
%	Description:
%
%	K = RBFADDITIONALKERNDIAGCOMPUTE(KERN, X) computes the diagonal of the kernel
%	matrix for the radial basis function kernel given a design matrix of
%	inputs.
%	 Returns:
%	  K - a vector containing the diagonal of the kernel matrix computed
%	   at the given points.
%	 Arguments:
%	  KERN - the kernel structure for which the matrix is computed.
%	  X - input data matrix in the form of a design matrix.
%	
%
%	See also
%	RBFADDITIONALKERNPARAMINIT, KERNDIAGCOMPUTE, KERNCREATE, RBFADDITIONALKERNCOMPUTE


%	Copyright (c) 2009 Raquel Urtasun
% 	rbfKernDiagCompute.m version 1.0


k = repmat(kern.variance, size(x, 1), 1);
