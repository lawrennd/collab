function [Y,lbls,Ytest,lblstest] = readEachMovieMarlinWeak(partNo)
% [Y,lbls,Ytest,lblstest] = readEachMovieWeakpartNo)


lblstest = [];
lbls = [];

baseDir = datasetsDirectory;
dirSep = filesep;

% load the ratings


fileName = [baseDir dirSep 'jason_rennie' dirSep 'project' dirSep 'em-mmmf' dirSep 'data' dirSep 'marlin.mat'];

disp(['Reading ... ',fileName]);

load(fileName);

Y = weaktrain{partNo}';
Ytest = weaktest{partNo}';


% find movies with too big rates
%max_film = max(Y');
%max_film_test = max(Ytest');
%ind = find(max_film>6);
%ind_test = find(max_film_test>6);

%ind = [ind, ind_test];
%ind = unique(ind);


% remove the corrupted data
%Y(ind,:) = [];
%Ytest(ind,:) = [];

%toRemove = [];

% find movies that are not rated
%for i=1:size(Y,1)
% check empy rating movies
%  ind = find(Y(i,:));
%if (length(ind)<1)
%  toRemove = [toRemove, i];
%end
%end
        
%Y(toRemove,:) = [];
%Ytest(toRemove,:) = [];
