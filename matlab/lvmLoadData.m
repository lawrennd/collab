function [Y, lbls, Ytest, lblstest] = lvmLoadData(dataset, seedVal)

% LVMOADDATA Load a latent variable model dataset.
%
%	Description:
%
%	[Y, LBLS, YTEST, LBLSTEST] = LVMLOADDATA(DATASET) loads a data set
%	for a latent variable modelling problem.
%	 Returns:
%	  Y - the training data loaded in.
%	  LBLS - a set of labels for the data (if there are no labels it is
%	   empty).
%	  YTEST - the test data loaded in. If no test set is available it is
%	   empty.
%	  LBLSTEST - a set of labels for the test data (if there are no
%	   labels it is empty).
%	 Arguments:
%	  DATASET - the name of the data set to be loaded. Currently the
%	   possible names are 'robotWireless', 'robotWirelessTest',
%	   'robotTwoLoops', 'robotTraces', 'robotTracesTest', 'cmu35gplvm',
%	   'cmu35Taylor', 'cmu35walkJog', 'vowels', 'stick', 'brendan',
%	   'digits', 'twos', 'oil', 'oilTest', 'oilValid', 'oil100',
%	   'swissRoll'.
%	
%
%	See also
%	MAPLOADDATA, DATASETSDIRECTORY


%	Copyright (c) 2004, 2005, 2006, 2008 Neil D. Lawrence
% 	lvmLoadData.m CVS version 1.9
% 	lvmLoadData.m SVN version 173
% 	last update 2009-01-02T17:35:15.000000Z

  if nargin > 1
    randn('seed', seedVal)
    rand('seed', seedVal)
  end

  % get directory

  baseDir = datasetsDirectory;
  dirSep = filesep;
  lbls = [];
  lblstest = [];
  switch dataset
   case 'movielens'
    try 
      load([baseDir 'movielens.mat']);
      
    catch
      [void, errid] = lasterr;
      if strcmp(errid, 'MATLAB:load:couldNotReadFile');

        
        % load the ratings

        fileName = [baseDir dirSep 'movielens' dirSep 'large' dirSep 'ratings.dat'];
        [users, films, ratings, timeStamp] = textread(fileName, '%n::%n::%n::%n');
        ind = randperm(size(users, 1));
        users = users(ind, :);
        films = films(ind, :);
        ratings = ratings(ind, :);
        numUsers = max(users);
        numFilms = max(films);
        
        numRatings = size(users, 1);
        numTrainRatings = ceil(0.8*numRatings);
        Y = spalloc(numFilms, numUsers, numTrainRatings);
        Ytest = spalloc(numFilms, numUsers, numRatings-numTrainRatings);
        indTrain = sub2ind(size(Y), films(1:numTrainRatings), users(1:numTrainRatings));
        indTest = sub2ind(size(Ytest), films(numTrainRatings+1:numRatings), users(numTrainRatings+1:numRatings));
        Y(indTrain) = ratings(1:numTrainRatings);
        Ytest(indTest) = ratings(numTrainRatings+1:numRatings);
        
        % save the additional information
        
        fileName = [baseDir dirSep 'movielens' dirSep 'large' dirSep 'movies.dat'];
        %[id, films, Type] = textread(fileName, '%n::%s::%s');

        % create the structure
        lbls = zeros(size(Y,1),18);

        fid = fopen(fileName);
        readLine = 0;
        counter = 0;
        data = [];
        all_genres = [{'Action'},{'Adventure'},{'Animation'},{'Children''s'}, ...
            {'Comedy'},{'Crime'},{'Documentary'},{'Drama'},{'Fantasy'},{'Film-Noir'}, ...
            {'Horror'},{'Musical'},{'Mystery'},{'Romance'},{'Sci-Fi'},{'Thriller'},{'War'},{'Western'}];
        

        readLine = fgets(fid);
        while readLine ~= -1
          
          parts = stringSplit(readLine,':');
          id = str2num(parts{1});
          title = parts(3);
          genre = parts{5};
          % createMovieLensExtra(genre);
          
          for i=1:length(all_genres)
            if (strfind(genre,all_genres{i}))
                lbls(id,i) = 1;
            end
          end
          
          readLine = fgets(fid);
          
        end

        save([baseDir 'movielens.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
      else
        error(lasterr);
      end
    end
    
  case {'movielens_80_f_1','movielens_80_f_2','movielens_80_f_3','movielens_80_f_4','movielens_80_f_5'}
      perc_train = 0.8;
      try 
      load([baseDir, dataset, '.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));
if_random = 0;
      
[Y,lbls,Ytest,lblstest] = readMovieLens(perc_train, partNo, if_random);

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
      
case {'movielens_50_1','movielens_50_2','movielens_50_3','movielens_50_4','movielens_50_5'}
      perc_train = 0.5;
if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readMovieLens(perc_train, partNo,if_random);

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
case {'movielens_60_1','movielens_60_2','movielens_60_3','movielens_60_4','movielens_60_5'}
      perc_train = 0.6;
if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readMovieLens(perc_train, partNo,if_random);

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
   case {'movielens_70_1','movielens_70_2','movielens_70_3','movielens_70_4','movielens_70_5'}
      perc_train = 0.7;
if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readMovieLens(perc_train, partNo,if_random);

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
      
      case {'movielens_80_1','movielens_80_2','movielens_80_3','movielens_80_4','movielens_80_5'}
      perc_train = 0.8;
if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readMovieLens(perc_train, partNo,if_random);

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
      
      case {'movielens_90_1','movielens_90_2','movielens_90_3','movielens_90_4','movielens_90_5'}
      perc_train = 0.9;
if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readMovieLens(perc_train, partNo,if_random);

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
      
      case {'movielens_30_1','movielens_30_2','movielens_30_3','movielens_30_4','movielens_30_5'}
      perc_train = 0.3;
if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readMovieLens(perc_train, partNo,if_random);

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
      
      %%%

      case {'movielens_strong_1','movielens_strong_2','movielens_strong_3','movielens_strong_4','movielens_strong_5'}
          % this is the database strong
      %perc_train = -1;
%if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readMovieLensStrong(partNo);

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
      
      case {'movielens_weak_1','movielens_weak_2','movielens_weak_3','movielens_weak_4','movielens_weak_5'}
          % this is the database strong
      %perc_train = -1;
%if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readMovieLensWeak(partNo);

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
      
      case {'eachmovie_weak_1','eachmovie_weak_2','eachmovie_weak_3','eachmovie_weak_4','eachmovie_weak_5'}
          % this is the database strong
      %perc_train = -1;
%if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readEachMovieWeak(partNo);

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
      
      case {'eachmovie_marlin_weak_1','eachmovie_marlin_weak_2','eachmovie_marlin_weak_3'}
          % this is the database strong
      %perc_train = -1;
%if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readEachMovieMarlinWeak(partNo); 

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
      
      case {'eachmovie_marlin_strong_1','eachmovie_marlin_strong_2','eachmovie_marlin_strong_3'}
          % this is the database strong
      %perc_train = -1;
%if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readEachMovieMarlinStrong(partNo);

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
      
      case {'movielens_marlin_weak_1','movielens_marlin_weak_2','movielens_marlin_weak_3'}
          % this is the database strong
      %perc_train = -1;
%if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      % get the extra info
      load([baseDir, 'movielens_metadata.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readMovieLensMarlinWeak(partNo);
% get the extra info
      load([baseDir, 'movielens_metadata.mat']);
      

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end
      
      case {'movielens_marlin_strong_1','movielens_marlin_strong_2','movielens_marlin_strong_3'}
          % this is the database strong
      %perc_train = -1;
%if_random = 1;
      try 
      load([baseDir, dataset, '.mat']);
      % get the extra info
      %load([baseDir, 'movielens_metadata.mat']);
      
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readMovieLensMarlinStrong(partNo);
% get the extra info
      kk = load([baseDir, 'movielens_metadata.mat']);
lblstest = kk.lbls;

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end

case {'movielens_10M_1','movielens_10M_2_2','movielens_10M_3','movielens_10M_4','movielens_10M_5'}
      try 
      load([baseDir, dataset, '.mat']);
      
      catch
        [void, errid] = lasterr;
        if strcmp(errid, 'MATLAB:load:couldNotReadFile');
            partNo = str2num(dataset(end));

[Y,lbls,Ytest,lblstest] = readMovieLens10M(partNo);

            save([baseDir, dataset, '.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
         else
        error(lasterr);
        end
      end


      
   case {'movielensSmall1', 'movielensSmall2', 'movielensSmall3', 'movielensSmall4', 'movielensSmall5'}

    partNo = str2num(dataset(end));
    uTrain = load([baseDir dirSep 'movielens' dirSep 'small' dirSep 'u' num2str(partNo) '.base']);
    numUsers = max(uTrain(:, 1));
    numFilms = max(uTrain(:, 2));
    numRatings = size(uTrain, 1);
    Y = spalloc(numFilms, numUsers, numRatings);
    
    for i = 1:size(uTrain, 1);
      Y(uTrain(i, 2), uTrain(i, 1)) = uTrain(i, 3);
    end
    meanY = mean(Y(find(Y)));
    Y(find(Y)) = (Y(find(Y))-meanY);
    uTest = load([baseDir dirSep 'movielens' dirSep 'small' dirSep 'u' num2str(partNo) '.test']);
    numTestRatings = size(uTest, 1);
    Ytest = spalloc(numFilms, numUsers, numTestRatings);
    for i = 1:size(uTest, 1);
      Ytest(uTest(i, 2), uTest(i, 1)) = uTest(i, 3);
    end
    Ytest(find(Ytest)) = (Ytest(find(Ytest))-meanY);
    
    

    
    
   otherwise
    error('Unknown data set requested.')
    
  end
end
