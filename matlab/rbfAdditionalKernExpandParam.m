function kern = rbfAdditionalKernExpandParam(kern, params)

% RBFADDITIONALKERNEXPANDPARAM Create kernel structure from RBF kernel's parameters.
%
%	Description:
%
%	KERN = RBFADDITIONALKERNEXPANDPARAM(KERN, PARAM) returns a radial basis
%	function kernel structure filled with the parameters in the given
%	vector. This is used as a helper function to enable parameters to be
%	optimised in, for example, the NETLAB optimisation functions.
%	 Returns:
%	  KERN - kernel structure with the given parameters in the relevant
%	   locations.
%	 Arguments:
%	  KERN - the kernel structure in which the parameters are to be
%	   placed.
%	  PARAM - vector of parameters which are to be placed in the kernel
%	   structure.
%	
%
%	See also
%	RBFADDITIONALKERNPARAMINIT, RBFADDITIONALKERNEXTRACTPARAM, KERNEXPANDPARAM


%	Copyright (c) 2009 Raquel
% 	rbfAdditionalKernExpandParam.m version 1.0


kern.inverseWidth = params(1);
kern.variance = params(2);
