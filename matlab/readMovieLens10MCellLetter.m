function [Y,lbls,Ytest,lblstest] = readMovieLens10MCellLetter(partLetter)
% [Y,lbls,Ytest,lblstest] = readMovieLens10M(partNo)
% read the 10M movielens in a cell array. It is too big to do the regular way

  lbls = [];
lblstest = [];

        baseDir = datasetsDirectory;
        dirSep = filesep;

        % load the ratings

        fileName = [baseDir dirSep 'movielens' dirSep '10M' dirSep 'r',num2str(partLetter),'.train'];
        [users, films, ratings, timeStamp] = textread(fileName, '%n::%n::%n::%n');


[Y] = loadSparse10M(users,films,ratings);


        fileName = [baseDir dirSep 'movielens' dirSep '10M' dirSep 'r',num2str(partLetter),'.test'];
        [users_test, films_test, ratings_test, timeStamp] = textread(fileName, '%n::%n::%n::%n');


[Ytest] = loadSparse10M(users_test,films_test,ratings_test);


