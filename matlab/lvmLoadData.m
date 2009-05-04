function [Y, lbls, Ytest, lblstest] = lvmLoadData(dataset)

% LVMLOADDATA Load a latent variable model dataset.
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


%	Copyright (c) 2004, 2005, 2006 Neil D. Lawrence
% 	lvmLoadData.m version 1.8


% get directory
baseDir = datasetsDirectory;
dirSep = filesep;
lbls = [];
switch dataset
 
 case 'robotWireless'
  Y = parseWirelessData([baseDir 'uw-floor.txt']);
  Y = Y(1:215, :);
 
 case 'robotWirelessTest'
  Y = parseWirelessData([baseDir 'uw-floor.txt']);
  Y = Y(216:end, :);

 case 'robotTwoLoops'
  Y = csvread([baseDir 'TwoLoops.slam'], 1, 0);
  Y = Y(1:floor(end/2), 4:end);
  Y(find(Y==-100))=-NaN;
  Y = (Y + 85)/15;
  
 case 'robotTraces'
  Y = csvread([baseDir 'Trace-3rdFloor-01.uwar.slam'], 1, 0); 
  Y = Y(1:floor(end/2), 4:end);
  Y(:, [3 4 38]) = []; % Remove columns of missing data.
  Y(find(Y==-100))=NaN;
  Y = (Y + 85)/15;

 case 'robotTracesTest'
  Y = csvread([baseDir 'Trace-3rdFloor-01.uwar.slam'], 1, 0); 
  Y = Y(ceil(end/2):end, 4:end);
  Y(:, [3 4 38]) = []; % Remove columns of missing data.
  Y(find(Y==-100))=NaN;
  Y = (Y + 85)/15;

 case 'cmu35gplvm'
  [Y, lbls, Ytest, lblstest] = lvmLoadData('cmu35WalkJog');
  skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35.asf']);
  [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35_01.amc'], skel);

  Ytest = Ytest(find(lblstest(:, 2)), :);
  lblstest = lblstest(find(lblstest(:, 2)), 2);

  %left indices
  xyzInd = [2];
  xyzDiffInd = [1 3];
  rotInd = [4 6];
  rotDiffInd = [5];
  generalInd = [7:38 41:47 49:50 53:59 61:62];

  jointAngles  = asin(sin(pi*Y(:, generalInd)/180));
  jointAnglesTest  = asin(sin(pi*Ytest(:, generalInd)/180));
  
  endInd = [];
  for i = 1:size(lbls, 2)
    endInd = [endInd max(find(lbls(:, i)))];
  end
  catJointAngles = [];
  xyzDiff = [];
  catSinCos = [];
  startInd = 1;
  for i = 1:length(endInd)
    ind1 = startInd:endInd(i)-1;
    ind2 = startInd+1:endInd(i);
    catJointAngles = [catJointAngles; ...
                      jointAngles(ind2, :)];
    xyzDiff = [xyzDiff;
               Y(ind1, xyzDiffInd) - Y(ind2, xyzDiffInd) ...
               Y(ind2, xyzInd)];
    catSinCos = [catSinCos; ...
                 sin(pi*Y(ind2, rotInd)/180) ...
                 sin(pi*Y(ind1, rotDiffInd)/180)-sin(pi*Y(ind2, rotDiffInd)/180) ...
                 cos(pi*Y(ind2, rotInd)/180) ...
                 cos(pi*Y(ind1, rotDiffInd)/180)-cos(pi*Y(ind2, rotDiffInd)/180)];
    startInd = endInd(i)+1;
  end
  Y = [catJointAngles xyzDiff catSinCos];
  lbls = [];
  
  endInd = [];
  for i = 1:size(lblstest, 2)
    endInd = [endInd max(find(lblstest(:, i)))];
  end
  catJointAnglesTest = [];
  xyzDiffTest = [];
  catSinCosTest = [];
  startInd = 1;
  for i = 1:length(endInd)
    ind1 = startInd:endInd(i)-1;
    ind2 = startInd+1:endInd(i);
    catJointAnglesTest = [catJointAnglesTest; ...
                      jointAnglesTest(ind2, :)];
    xyzDiffTest = [xyzDiffTest;
                   Ytest(ind1, xyzDiffInd) - Ytest(ind2, xyzDiffInd) ...
                   Ytest(ind2, xyzInd)];
    catSinCosTest = [catSinCosTest; ...
                 sin(pi*Ytest(ind2, rotInd)/180) ...
                 sin(pi*Ytest(ind1, rotDiffInd)/180)-sin(pi*Ytest(ind2, rotDiffInd)/180) ...
                 cos(pi*Ytest(ind2, rotInd)/180) ...
                 cos(pi*Ytest(ind1, rotDiffInd)/180)-cos(pi*Ytest(ind2, rotDiffInd)/180)];
    startInd = endInd(i)+1;
  end                                                
  Ytest = [catJointAnglesTest xyzDiffTest catSinCosTest];
  lblstest = [];

 case 'cmu35Taylor'
  % The CMU 35 data set as Graham Taylor et al. have it in their
  % NIPS 2006 paper.
  [rawY, lbls, rawYtest, lblstest] = lvmLoadData('cmu35WalkJog');
  rawYtest = rawYtest(45:end, :);
  lblstest = lblstest(45:end, 2);
  skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35.asf']);
  [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35_01.amc'], skel);
  posInd = [1 2 3];
  rotInd = [4 5 6];
  generalInd = [7:38 41:47 49:50 53:59 61:62];
  
  rawY = [rawY(:, posInd) sind(rawY(:, rotInd)) cosd(rawY(:, rotInd)) asind(sind(rawY(:, generalInd)))];
  rawYtest = [rawYtest(:, posInd) sind(rawYtest(:, rotInd)) cosd(rawYtest(:, rotInd)) asind(sind(rawYtest(:, generalInd)))];
  
  endInd = [];
  for i = 1:size(lbls, 2)
    endInd = [endInd max(find(lbls(:, i)))];
  end
  Y = [];
  startInd = 1;
  for i = 1:length(endInd)
    ind1 = startInd:endInd(i)-1;
    ind2 = startInd+1:endInd(i);
    Y = [Y; rawY(ind1, :) rawY(ind2, :)];
    startInd = endInd(i)+1;
  end  
  lbls = [];
  
  endInd = [];
  for i = 1:size(lblstest, 2)
    endInd = [endInd max(find(lblstest(:, i)))];
  end
  Ytest = [];
  startInd = 1;
  for i = 1:length(endInd)
    ind1 = startInd:endInd(i)-1;
    ind2 = startInd+1:endInd(i);
    Ytest = [Ytest; rawYtest(ind1, :) rawYtest(ind2, :)];
    startInd = endInd(i)+1;
  end                                                
  lblstest = [];

  
 case 'cmu35WalkJog'
  try 
    load([baseDir 'cmu35WalkJog.mat']);
  catch
    [void, errid] = lasterr;
    if strcmp(errid, 'MATLAB:load:couldNotReadFile');
      skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35.asf']);
      examples = ...
          {'01', '02', '03', '04', '05', '06', '07', '08', '09', '10', ...
           '11', '12', '13', '14', '15', '16', '17', '19', '20', ...
           '21', '22', '23', '24', '25', '26', '28', '30', '31', '32', '33', '34'};
      testExamples = {'18', '29'};
      % Label differently for each sequence
      exlbls = eye(31);
      testexlbls = eye(2);
      totLength = 0;
      totTestLength = 0;
      for i = 1:length(examples)
        [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35_' ...
                            examples{i} '.amc'], skel);
        tY{i} = tmpchan(1:4:end, :);
        tlbls{i} = repmat(exlbls(i, :), size(tY{i}, 1), 1);
        totLength = totLength + size(tY{i}, 1);
      end
      Y = zeros(totLength, size(tY{1}, 2));
      lbls = zeros(totLength, size(tlbls{1}, 2));
      endInd = 0;
      for i = 1:length(tY)
        startInd = endInd + 1;
        endInd = endInd + size(tY{i}, 1);
        Y(startInd:endInd, :) = tY{i};
        lbls(startInd:endInd, :) = tlbls{i};
      end
      for i = 1:length(testExamples)
        [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35_' ...
                            testExamples{i} '.amc'], skel);
        tYtest{i} = tmpchan(1:4:end, :);
        tlblstest{i} = repmat(testexlbls(i, :), size(tYtest{i}, 1), 1);
        totTestLength = totTestLength + size(tYtest{i}, 1);
      end
      Ytest = zeros(totTestLength, size(tYtest{1}, 2));
      lblstest = zeros(totTestLength, size(tlblstest{1}, 2));
      endInd = 0;
      for i = 1:length(tYtest)
        startInd = endInd + 1;
        endInd = endInd + size(tYtest{i}, 1);
        Ytest(startInd:endInd, :) = tYtest{i};
        lblstest(startInd:endInd, :) = tlblstest{i};
      end
      save([baseDir 'cmu35WalkJog.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
    else
      error(lasterr);
    end
  end

 case 'vowels'
  load([baseDir 'jon_vowel_data']);
  Y = [a_raw; ae_raw; ao_raw; ...
       e_raw; i_raw; ibar_raw; ...
       o_raw; schwa_raw; u_raw];
  Y(:, [13 26]) = [];
  lbls = [];
  for i = 1:9
    lbl = zeros(1, 9);
    lbl(i) = 1;
    lbls = [lbls; repmat(lbl, size(a_raw, 1), 1)];
  end
 

 case 'stick'
  Y = mocapLoadTextData([baseDir 'run1']);
  Y = Y(1:4:end, :);
 
 case 'brendan'
  load([baseDir 'frey_rawface.mat']);
  Y = double(ff)';
  
 case 'digits'
  
  % Fix seeds
  randn('seed', 1e5);
  rand('seed', 1e5);

  load([baseDir 'usps_train.mat']);
  % Extract 600 of digits 0 to 4
  [ALL_T, sortIndices] = sort(ALL_T);
  ALL_DATA = ALL_DATA(sortIndices(:), :);
  Y = [];
  lbls = [];
  numEachDigit = 600;
  for digit = 0:4;
    firstDigit = min(find(ALL_T==digit));
    Y = [Y; ALL_DATA(firstDigit:firstDigit+numEachDigit-1, :)];
    lbl = zeros(1, 5);
    lbl(digit+1) = 1;
    lbls = [lbls; repmat(lbl, numEachDigit, 1)];
  end

 case 'twos'  
  % load data
  load([baseDir 'twos']);
  Y = 2*a-1;

 case 'oil'
  load([baseDir '3Class.mat']);
  Y = DataTrn;
  lbls = DataTrnLbls;

 case 'oilTest'
  load([baseDir '3Class.mat']);
  Y = DataTst;
  lbls = DataTstLbls;

 case 'oilValid'
  load([baseDir '3Class.mat']);
  Y = DataVdn;
  lbls = DataVdnLbls;

 case 'oil100'
  randn('seed', 1e5);
  rand('seed', 1e5);
  load([baseDir '3Class.mat']);
  Y = DataTrn;
  lbls = DataTrnLbls;
  indices = randperm(size(Y, 1));
  indices = indices(1:100);
  Y = Y(indices, :);
  lbls = lbls(indices, :);

 case 'swissRoll'
  load([baseDir 'swiss_roll_data']);
  Y = X_data(:, 1:1000)';

case 'runCMU'
    baseDirRun = 'C:\Data\CMU\run\';
  try 
    load([baseDirRun 'runCMU.mat']);
  catch
  skel = acclaimReadSkel([baseDirRun '02.asf']);
  skel_each = ...
      {'02',  '16', '127'}; % '09',
  examples = ...
      {'03',  '35', '06'}; % '01',
  % Label differently for each sequence
  exlbls = eye(3);
  testexlbls = eye(2);
  totLength = 0;
  totTestLength = 0;
  for i = 1:length(examples)
      skel = acclaimReadSkel([baseDirRun skel_each{i} '.asf']);
      disp(['Loading ... ',baseDirRun skel_each{i} '_' examples{i} '.amc']);
    [tmpchan, skel] = acclaimLoadChannels([baseDirRun skel_each{i} '_' ...
                        examples{i} '.amc'], skel);
                    
    tY{i} = tmpchan(1:4:end, :);
    tlbls{i} = repmat(exlbls(i, :), size(tY{i}, 1), 1);
    totLength = totLength + size(tY{i}, 1);
  end
  Y = zeros(totLength, size(tY{1}, 2));
  lbls = zeros(totLength, size(tlbls{1}, 2));
  endInd = 0;
  for i = 1:length(tY)
    startInd = endInd + 1;
    endInd = endInd + size(tY{i}, 1);
    Y(startInd:endInd, :) = tY{i};
    lbls(startInd:endInd, :) = tlbls{i};
  end
  
  save([baseDirRun 'runCMU.mat'], 'Y', 'lbls');
  end
case 'runForJovan'
    resample = 4;
    baseDirRun = 'C:\Data\for_jovan\for-jovan\run\';
  try 
    load([baseDirRun 'runForJovan.mat']);
  catch
  skel_each = ...
      {'run'}; % '09',
  examples = ...
      {'result'}; % '01',
  % Label differently for each sequence
  exlbls = eye(1);
  testexlbls = eye(2);
  totLength = 0;
  totTestLength = 0;
  for i = 1:length(examples)
      skel = acclaimReadSkel([baseDirRun skel_each{i} '.asf']);
      disp(['Loading ... ',baseDirRun skel_each{i} '_' examples{i} '.amc']);
    [tmpchan, skel] = acclaimLoadChannels([baseDirRun skel_each{i} '_' ...
                        examples{i} '.amc'], skel);
                    
    tY{i} = tmpchan(1:resample:end, :);
% tY{i} = tmpchan;
    tlbls{i} = repmat(exlbls(i, :), size(tY{i}, 1), 1);
    totLength = totLength + size(tY{i}, 1);
  end
  Y = zeros(totLength, size(tY{1}, 2));
  lbls = zeros(totLength, size(tlbls{1}, 2));
  endInd = 0;
  for i = 1:length(tY)
    startInd = endInd + 1;
    endInd = endInd + size(tY{i}, 1);
    Y(startInd:endInd, :) = tY{i};
    lbls(startInd:endInd, :) = tlbls{i};
  end
  
  save([baseDirRun 'runForJovan.mat'], 'Y', 'lbls');
  end
    case 'patches_50'
        Y = load('C:\Data\patches_mathieu\all_patches_sparse_50.txt');
        lbls = [];
        
    case 'patches_all'
        Y = load('C:\Data\patches_mathieu\all_seq_sparse.txt');
    case 'patches_all_200'
        Y = load('C:\Data\patches_mathieu\all_seq_sparse_200.txt');
    case 'patches_all_200_7'
        Y = load('C:\Data\patches_mathieu\serviette\all_seq_sym_sparse_200_7.txt');
    case 'omni_train'
        load('C:\Data\OmniCam\christianData.mat');
        lbls = database.lbls;
        Y = database.Y;
    case 'omni_test'
        load('C:\Data\OmniCam\christianData.mat');
        lbls = database.lbls_test;
        Y = database.Ytest;
    case 'carton_symz_full_10'
        Y = load('carton_symz_full_sparse_10.txt');
    case 'carton_full_3'
        load('carton_full_3');
    case 'patches_sym_sparse_12'
        Y = load('patches_sym_filtered_sparse_12_rotz.txt');
    case 'patches_sym_sparse_test'
        Y = load('patches_seq_13_sym_sparse_10_rotz.txt');
    case 'patches_sym_sparse_test_small'
        Y = load('patches_seq_13_sym_sparse_12_rotz.txt');
    case 'coil'
        load('C:\Data\coil100\coil100.mat');
        Y = H;
        min_l = min(L);
        max_l = max(L);
        lbls = zeros(size(Y,1),max_l-min_l+1);
        index = 1;
        for i=min_l:max_l
            lbls(find(L==i),i)=1;
            inde
            x = index+1;
        end
    case 'faces_isomap'
        database = load('/export/rurtasun/Data/dimensionalityReduction/face_data.mat');
        Y = database.images';
        lbls = [database.poses', database.lights'];

 otherwise
  error('Unknown data set requested.')
 
end
