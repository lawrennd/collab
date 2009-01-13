function[] = demMovielens6script(substract_mean, partNo_v, latentDim_v,iters)
% DEMMOVIELENS3Script Try collaborative filtering on the large movielens data.
%
  % demMovielens6script(perc_train, substract_mean, partNo_v, latentDim_v)
%
% substract_mean --> bool if substract the mean
% partNo_v --> vector with the partitions to compute results
% latentDim_v --> vector with the latent dimensionalities to compute results
% iters --> number of iterations

randn('seed', 1e5);
rand('seed', 1e5);

experimentNo = 3;


%partNo_v = [1:5];
%latentDim_v = [5, 2:4, 6];


for i_latent=1:length(latentDim_v)
    q = latentDim_v(i_latent);
    for i_part=1:length(partNo_v)
        partNo = partNo_v(i_part);

        dataSetName = ['movielens_strong_',num2str(partNo)];
        
        disp(['Reading ... ',dataSetName]);
        
        [Y, void, Ytest] = lvmLoadData(dataSetName);
        
        if (substract_mean)
            % create the total vector
            s = nonzeros(Ytest);
            ratings = [nonzeros(Y); nonzeros(Ytest)];
            meanY = mean(ratings);
            stdY = std(ratings);
            %keyboard;
            index = find(Y);
            Y(index) = Y(index) - meanY;
            Y(index) = Y(index) / stdY;
            %keyboard;
        end;

        options = collabOptions;
        model = collabCreate(q, size(Y, 2), size(Y, 1), options);
        % keyboard;
        if (substract_mean)
	    model.mu = repmat(meanY,size(model.mu,1),1);
            model.sd = repmat(stdY,size(model.sd,1),1);
        end
        model.kern.comp{2}.variance = 0.11;
        model.kern.comp{3}.variance =  5; 
        options = collabOptimiseOptions;
        

        % set parameters
        options.momentum = 0.9;
        options.learnRate = 0.0001;
        options.paramMomentum = 0.9;
        options.paramLearnRate = 0.0001;
        options.numIters = iters;
        options.showLikelihood = false;

        capName = dataSetName;
        capName(1) = upper(capName(1));
options.saveName = ['dem' capName num2str(experimentNo) '_'];

        model = collabOptimise(model, Y, options)

	% compute the test error
	  disp('Computing test error');


[error_L2,error_NMAE,error_NMAE_round] = computeTestErrorStrong(model,Ytest)


        % Save the results.
        capName = dataSetName;
        capName(1) = upper(capName(1));
        
        saveResults = [capName,'_norm_',num2str(substract_mean),'_',num2str(q),'_',num2str(partNo),'_iters_',num2str(iters),'.mat'];
        disp(['Saving ... ',saveResults]);
        save(saveResults, 'model', 'L2_error','options','NMAE_error','NMAE_round_error');
    end
end

