function [Y,lbls,Ytest,lblstest] = readEachMovieWeak(partNo)
% [Y,lbls,Ytest,lblstest] = readEachMovieWeakpartNo)


lblstest = [];
lbl = [];

baseDir = datasetsDirectory;
dirSep = filesep;

% load the ratings

try
    fileName = [baseDir dirSep 'eachmovie' dirSep 'Vote_more_20.mat'];
    load(fileName);
catch

    fileName = [baseDir dirSep 'eachmovie' dirSep 'Vote.txt'];

    disp(['Reading ... ',fileName]);

    [users, films, ratings, weights, dates, hours, minutes, seconds] = textread(fileName, '%n\t%n\t%n\t%n\t%s %n:%n:%n');
    ind = randperm(size(users, 1));
    users = users(ind, :);
    films = films(ind, :);
    ratings = ratings(ind, :);
    numUsers = max(users);
    numFilms = max(films);

    activeUsers = [1:numUsers];
    % erase the users with less than 20 films
    disp('Removing users with less than 20 ratings');
    mapUsers = -ones(numUsers,1);
    numActiveUsers = 0;
    indTotal = [];
    for i=1:numUsers
        ind = find(users==i);
        if (length(ind)<20)
            % remove the user
            [indTotal] = [indTotal; ind];
        else
            numActiveUsers = numActiveUsers+1;
            mapUsers(i) = numActiveUsers;
        end
    end
    users(indTotal) = [];
    films(indTotal) = [];
    ratings(indTotal) = [];
    weights(indTotal) = [];
    dates(indTotal) = [];
    hours(indTotal) = [];
    minutes(indTotal) = [];
    second(indTotal) = [];
    users = mapUsers(users);
    fileName = [baseDir dirSep 'eachmovie' dirSep 'Vote_more_20.mat'];
    save(fileName,'users','films','ratings','weights','dates','hours','minutes','seconds');
end

numUsers = max(users);
numFilms = max(films);

numRatings = size(users, 1);
numUsersTrain = 30000;
numUsers = max(users);
for i=1:partNo
    % partition the users at random
    randIndexUsers = randperm(numUsers);

end
% get the films for those users
numTrainRatings = 0;
indexTrain = [];
indexTest = [];
for i=1:numUsersTrain
    indexUsers = find(users==randIndexUsers(i));
    
    indexTest = [indexTest; indexUsers(end)];

    % use one for testing and one for training
    indexUsers(end) = [];

    numTrainRatings = numTrainRatings + length(indexUsers);
    indexTrain = [indexTrain; indexUsers]; % ?? this takes too much time
end
numTestRatings = numUsersTrain;
Y = spalloc(numFilms, numUsers, numTrainRatings);
Ytest = spalloc(numFilms, numUsers, numTestRatings);
numRatings = numTrainRatings + numTestRatings;

%indexTest = 1:length(users);
%indexTest(indexTrain) = [];

indTrain = sub2ind(size(Y), films(indexTrain), users(indexTrain));
indTest = sub2ind(size(Ytest), films(indexTest), users(indexTest));

Y(indTrain) = ratings(indexTrain);
Ytest(indTest) = ratings(indexTest);


% % save the additional information
% 
% fileName = [baseDir dirSep 'movielens' dirSep 'large' dirSep 'movies.dat'];
% %[id, films, Type] = textread(fileName, '%n::%s::%s');
% 
% % create the structure
% lbls = zeros(size(Y,1),18);
% 
% fid = fopen(fileName);
% readLine = 0;
% counter = 0;
% data = [];
% all_genres = [{'Action'},{'Adventure'},{'Animation'},{'Children''s'}, ...
%     {'Comedy'},{'Crime'},{'Documentary'},{'Drama'},{'Fantasy'},{'Film-Noir'}, ...
%     {'Horror'},{'Musical'},{'Mystery'},{'Romance'},{'Sci-Fi'},{'Thriller'},{'War'},{'Western'}];
% 
% 
% readLine = fgets(fid);
% while readLine ~= -1
% 
%   parts = stringSplit(readLine,':');
%   id = str2num(parts{1});
%   title = parts(3);
%   genre = parts{5};
%   % createMovieLensExtra(genre);
% 
%   for i=1:length(all_genres)
%     if (strfind(genre,all_genres{i}))
%         lbls(id,i) = 1;
%     end
%   end
% 
%   readLine = fgets(fid);
% 
% end


        
