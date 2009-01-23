function [Y,lbls,Ytest,lblstest] = readMovieLensMarlinWeak(partNo)
% [Y,lbls,Ytest,lblstest] = readEachMovieWeakpartNo)


lblstest = [];
lbls = [];

baseDir = datasetsDirectory;
dirSep = filesep;

% load the ratings


fileName = [baseDir dirSep 'jason_rennie' dirSep 'project' dirSep '1mml-mmmf' dirSep 'data' dirSep 'marlin.mat'];

disp(['Reading ... ',fileName]);

load(fileName);

Y = weaktrain{partNo}';
Ytest = weaktest{partNo}';

keyboard;


        
