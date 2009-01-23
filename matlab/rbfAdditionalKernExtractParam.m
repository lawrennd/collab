function [params, names] = rbfAdditionalKernExtractParam(kern)

% RBFKERNADDITIONALEXTRACTPARAM Extract parameters from the RBF kernel structure.
%
%	Description:
%
%	PARAM = RBFADDITIONALKERNEXTRACTPARAM(KERN) Extract parameters from the radial
%	basis function kernel structure into a vector of parameters for
%	optimisation.
%	 Returns:
%	  PARAM - vector of parameters extracted from the kernel. If the
%	   field 'transforms' is not empty in the kernel matrix, the
%	   parameters will be transformed before optimisation (for example
%	   positive only parameters could be logged before being returned).
%	 Arguments:
%	  KERN - the kernel structure containing the parameters to be
%	   extracted.
%
%	[PARAM, NAMES] = RBFADDITIONALKERNEXTRACTPARAM(KERN) Extract parameters and
%	parameter names from the radial basis function kernel structure.
%	 Returns:
%	  PARAM - vector of parameters extracted from the kernel. If the
%	   field 'transforms' is not empty in the kernel matrix, the
%	   parameters will be transformed before optimisation (for example
%	   positive only parameters could be logged before being returned).
%	  NAMES - cell array of strings giving names to the parameters.
%	 Arguments:
%	  KERN - the kernel structure containing the parameters to be
%	   extracted.
%	
%
%	See also
%	% SEEALSO RBFADDITIONALKERNPARAMINIT, RBFADDITIONALKERNEXPANDPARAM, KERNEXTRACTPARAM, SCG, CONJGRAD


%	Copyright (c) 2009 Raquel Urtasun
% 	rbfAdditionalKernExtractParam.m version 1.0


params = [kern.inverseWidth kern.variance];
if nargout > 1
  names={'inverse width', 'variance'};
end
