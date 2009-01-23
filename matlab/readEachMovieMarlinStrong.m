function [Y,lbls,Ytest,lblstest] = readEachMovieMarlinStrong(partNo)
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
Ytest = strongtest{partNo}';
lbls = strongtrain{partNo}';


        
