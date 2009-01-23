function gX = rbfAdditionalKernGradX(kern, X, X2)

% RBFADDITIONALKERNGRADX Gradient of RBF kernel with respect to input locations.
%
%	Description:
%
%	G = RBFADDITIONALKERNGRADX(KERN, X1, X2) computes the gradident of the radial
%	basis function kernel with respect to the input positions where both
%	the row positions and column positions are provided separately.
%	 Returns:
%	  G - the returned gradients. The gradients are returned in a matrix
%	   which is numData2 x numInputs x numData1. Where numData1 is the
%	   number of data points in X1, numData2 is the number of data points
%	   in X2 and numInputs is the number of input dimensions in X.
%	 Arguments:
%	  KERN - kernel structure for which gradients are being computed.
%	  X1 - row locations against which gradients are being computed.
%	  X2 - column locations against which gradients are being computed.
%	
%
%	See also
%	RBFADDITIONALKERNPARAMINIT, KERNGRADX, RBFADDITIONALKERNDIAGGRADX


%	Copyright (c) 2009 Raquel Urtasun
% 	rbfAdditionalKernGradX.m version 1.0


gX = zeros(size(X2, 1), size(X2, 2), size(X, 1));
