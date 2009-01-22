
import pdb
import os
import sys
import time
import posix
sys.path.append(os.path.join(posix.environ['HOME'], 'mlprojects', 'collab', 'python'))
sys.path.append(os.path.join(posix.environ['HOME'], 'mlprojects', 'swig', 'src'))
import pyflix.datasets
import numpy as np
import ndlml as nl
import math
import netlab

def dataDir():
    return os.path.join('/local', 'data', 'pyflix')

def resultsDir():
    return os.path.join('/local', 'data', 'results', 'netflix')



class iterInfo:
    """A class containing information for the current iteration."""
    def __init__(self, tic, tic0, count, numSparse, userOrder, iterNum):
        self.tic = tic
        self.tic0 = tic0
        self.count = count
        self.numSparse = numSparse
        self.userOrder = userOrder
        self.iterNum = iterNum

class dataSet:
    """A class containing information about the data set."""
    def __init__(self, data, numMovies, movieMean, movieStd, movieCount, learnRateAdjust):
        self.data = data
        self.numMovies = numMovies
        self.movieMean = movieMean
        self.movieStd = movieStd
        self.movieCount = movieCount
        self.learnRateAdjust = learnRateAdjust
  

class params:
    """A class containing all the model parameters."""
    def __init__(self, X, X_u, param, lnsigma2, lnbeta, fullKern=None, sparseKern=None, noise=None):
        self.X = X
        self.X_u = X_u
        self.param = param
        self.lnsigma2 = lnsigma2
        self.lnbeta = lnbeta
        self.fullKern = fullKern
        self.sparseKern = sparseKern
        self.noise = noise
        

class options:
    """Class containing the options for the collaborative filtering."""
    # For learning rate anealling.
    lambdaVal = 0.01
    maxLearnRate = 1
    t0 = 400000
    momentum = 0.9

    # Initial white noise variance.
    startVariance = 5
    baseKern = 'rbf'
    
    # Active set size and maximum size for FTC.
    numActive = 100
    maxFTC = 500
    sparseApprox = nl.gp.DTCVAR

    seed = 10000

    # How often to print status
    showEvery = 5000

    # How often to save status 
    saveEvery= 20000
    numIters = 10
    resultsBaseDir = resultsDir()
    
        
def loadData(dataSetName):
    """Load the given dataset."""
    if dataSetName=="netflix":
        isNetflix = True
        # load in data netflix.
        baseDir = dataDir()
        print "Loading netflix data ..."
        data = pyflix.datasets.RatedDataset(os.path.join(baseDir, 'training_set'))
        movieIDs = data.movieIDs()
        numMovies = data.movieIDs().shape[0]
        userIDs = data.userIDs()
        numUsers = data.userIDs().shape[0]
        d = dataSet(data = data,
                    numMovies = numMovies,
                    movieMean = np.zeros((numMovies, 1)),
                    movieStd = np.zeros((numMovies, 1)),
                    movieCount = np.zeros((numMovies, 1)),
                    learnRateAdjust = np.ones((numMovies, 1)))
        print "... done"

        # Compute movie means and standard deviations.
        print "Computing movie means ..."
        for movie in movieIDs:
            ratings = d.data.movie(movie).ratings()
            d.movieMean[movie-1] = ratings.mean()
            d.movieStd[movie-1] = ratings.std()
            d.movieCount[movie-1] = ratings.shape[0]
            d.learnRateAdjust[movie-1] = float(numUsers)/float(d.movieCount[movie-1])
        print "done"

    if dataSetName=='movielens':
        print dataSetName
    elif dataSetName=='movielensSmall':
        print dataSetName
    return d

def extractKernType(latentDim, lnsigma2, options):
    """Extract the kernel types from the options and return as a tuple"""
    o = options

    fullKern = nl.cmpndKern(latentDim) 
    sparseKern = nl.cmpndKern(latentDim) 
    
    kt = type(o.baseKern)
    if kt==str:
        if o.baseKern == 'rbf':
            kern1 = nl.rbfKern(latentDim)
        elif o.baseKern == 'mlp':
            kern1 = nl.mlpKern(latentDim)
        elif o.baseKern == 'ratquad':
            kern1 = nl.ratquadKern(latentDim)
        elif o.baseKern == 'matern32':
            kern1 = nl.matern32Kern(latentDim)
        elif o.baseKern == 'matern52':
            kern1 = nl.matern52Kern(latentDim)
        elif o.baseKern == 'lin':
            kern1 = nl.linKern(latentDim)

    elif kt==nl.rbfkern \
            or kt==nl.mlpKern \
            or kt==nl.ratquadKern \
            or kt==nl.matern32Kern \
            or kt==nl.matern52Kern \
            or kt==nl.linKern \
            or kt==nl.polyKern \
            or kt==nl.cmpndKern:
        # Kernel has been provided as a class already.
        kern1 = o.baseKern
    
    kern2 = nl.biasKern(latentDim)
    kern3 = nl.whiteKern(latentDim)
    kern4 = nl.whitefixedKern(latentDim)

    kern2.setVariance(0.11)
    kern3.setVariance(math.exp(lnsigma2))
    kern4.setVariance(1e-2)

    fullKern.addKern(kern1)
    fullKern.addKern(kern2)
    fullKern.addKern(kern3)

    sparseKern.addKern(kern1)
    sparseKern.addKern(kern2)
    sparseKern.addKern(kern4)

    return fullKern, sparseKern


def loadResults(loadDir, latentDim, options):

    X = np.fromfile(os.path.join(loadDir, "X")).reshape(-1, latentDim)
    Xchange = np.fromfile(os.path.join(loadDir, "Xchange")).reshape(-1, latentDim)
    X_u = np.fromfile(os.path.join(loadDir, "X_u")).reshape(-1, latentDim)
    inducingChange = np.fromfile(os.path.join(loadDir, "inducingChange")).reshape(-1, latentDim)

    betaSigma = np.fromfile(os.path.join(loadDir, "betaSigma")).reshape(1, 4)
    lnsigma2 = betaSigma[0,1]
    lnbeta = betaSigma[0,0]
    lnsigma2Change = betaSigma[0,3]
    lnbetaChange = betaSigma[0,2]

    (fullKern, sparseKern) = extractKernType(latentDim, lnsigma2, options)
    
    numParams = fullKern.getNumParams()
    param = np.fromfile(os.path.join(loadDir, "param")).reshape(1, numParams)
    paramChange = np.fromfile(os.path.join(loadDir, "paramChange")).reshape(1, numParams)


    # Set log sigma2 (variance for FTC) and log beta (precision for sparse)
    # using this dummy y forces mean of Gaussian noise to be zero.
    dummyy = nl.matrix(10, 1)
    dummyy.zeros()

    # paramIter.fromarray(param)
    paramIter = nl.matrix(param.shape[0], param.shape[1])
    param[0, -1] = lnsigma2
#    paramIter.fromarray(param)
    for i in range(param.shape[1]):
        paramIter.setVal(param[0, i], i)
    fullKern.setTransParams(paramIter)

    paramIter = nl.matrix(param.shape[0], param.shape[1]-1)
    param2 = param[0, 0:-1]
#    paramIter.fromarray(param2)
    for i in range(param.shape[1]-1):
         paramIter.setVal(param[0, i], i)
    sparseKern.setTransParams(paramIter)

    # Set up parameters
    p = params(X = X, 
               X_u = X_u, 
               param = param, 
               fullKern = fullKern,
               sparseKern = sparseKern,
               lnsigma2 = lnsigma2, 
               lnbeta = lnbeta, 
               noise =  nl.gaussianNoise(dummyy))



    # Set up vectors for storing old changes.
    pc = params(X=Xchange, 
                X_u=inducingChange,
                param=paramChange, 
                lnsigma2=lnsigma2Change, 
                lnbeta=lnbetaChange)
    return p, pc

def restart(loadIter, startCount, loadUser, latentDim, dataSetName, experimentNo, options):
    """Restart a collaborative filtering model from a crashed run."""

    o = options
    np.random.seed(seed=o.seed)

    isNetflix = False
    if dataSetName=="netflix":
        isNetflix = True
    
    d = loadData(dataSetName)
    
    resultsDir = os.path.join(o.resultsBaseDir, dataSetName + str(experimentNo))
    if not os.path.exists(resultsDir):
        os.mkdir(resultsDir)
    loadDir1 = "iter" + str(loadIter)
    userOrder = np.fromfile(file=os.path.join(resultsDir, 
                                              loadDir1, 
                                              "userOrder"),
                            dtype=int)
    
    
    loadDir2 = "count" + str(startCount) + "_user" + str(loadUser)
    
    loadDir = os.path.join(resultsDir, loadDir1, loadDir2)
    
    p, pc = loadResults(loadDir, latentDim, o)


    numSparse = 0
    print "Restarting from iteration ", loadIter, " count ", startCount, " ... "
    tic = time.time()
    tic0 = tic

    for iter in range(loadIter, o.numIters):
        
        saveDir = "iter" + str(iter)
        iterDir = os.path.join(resultsDir, saveDir)
        if iter>loadIter:
            # Ensure repeatability
            state = np.random.get_state()
            # Order users randomly
            userOrder = np.random.permutation(d.data.userIDs())

            if not os.path.exists(iterDir):
                os.mkdir(iterDir)

            userOrder.tofile(os.path.join(iterDir, "userOrder" ))
            p.param.tofile(os.path.join(iterDir, "param" ))
            p.X.tofile(os.path.join(iterDir, "X" ))
            p.X_u.tofile(os.path.join(iterDir, "X_u" ))
            pc.X.tofile(os.path.join(iterDir, "Xchange" ))
            pc.param.tofile(os.path.join(iterDir, "paramChange" ))
            pc.X_u.tofile(os.path.join(iterDir, "inducingChange" ))

        info = iterInfo(tic = tic, 
                        tic0 = tic0, 
                        count = startCount, 
                        numSparse = numSparse, 
                        userOrder = userOrder,
                        iterNum = iter)
        runIter(dataSet = d, 
                params = p, 
                paramChange = pc, 
                options = o,
                iterInfo = info,
                iterDir = iterDir)

        startCount = info.count
    # Save state for repeatability
    saveDir = "final"
    iterDir = os.path.join(resultsDir, saveDir)
    if not os.path.exists(iterDir):
        os.mkdir(iterDir)
    betaSigma = np.array([p.lnbeta, p.lnsigma2, pc.lnbeta, pc.lnsigma2])
    betaSigma.tofile(os.path.join(iterDir, "betaSigma"))
    p.param.tofile(os.path.join(iterDir, "param" ))
    p.X.tofile(os.path.join(iterDir, "X" ))
    p.X_u.tofile(os.path.join(iterDir, "X_u" ))
    pc.X.tofile(os.path.join(iterDir, "Xchange" ))
    pc.param.tofile(os.path.join(iterDir, "paramChange" ))
    pc.X_u.tofile(os.path.join(iterDir, "inducingChange" ))

    

def run(latentDim, dataSetName, experimentNo, options):
    """Initialize and run a collaborative filtering model."""

    o = options
    np.random.seed(seed=o.seed)

    isNetflix = False
    if dataSetName=="netflix":
        isNetflix = True
    
    d = loadData(dataSetName)

    resultsDir = os.path.join(o.resultsBaseDir, dataSetName + str(experimentNo))
    if not os.path.exists(o.resultsBaseDir):
        os.mkdir(o.resultsBaseDir)
    if not os.path.exists(resultsDir):
        os.mkdir(resultsDir)


    # Set log sigma2 (variance for FTC) and log beta (precision for sparse)
    # using this dummy y forces mean of Gaussian noise to be zero.
    dummyy = nl.matrix(10, 1)
    dummyy.zeros()

    (fullKern, sparseKern) = extractKernType(latentDim, math.log(o.startVariance), o)
    # Set up parameters
    p = params(X = np.random.normal(0.0, 1e-6, (d.numMovies, latentDim)), 
               X_u = np.random.normal(0.0, 1e-6, (o.numActive, latentDim)), 
               param = None, 
               fullKern = fullKern,
               sparseKern = sparseKern,
               lnsigma2 = math.log(o.startVariance), 
               lnbeta = -math.log(o.startVariance), 
               noise =  nl.gaussianNoise(dummyy))


    # Set up parameter vectors
    paramNd = nl.matrix(1, p.fullKern.getNumParams())
    p.fullKern.getTransParams(paramNd)
    p.param = paramNd.toarray()

    # Set up vectors for storing old changes.
    pc = params(X=np.zeros((d.numMovies, latentDim)), 
                X_u=np.zeros((o.numActive, latentDim)), 
                param=np.zeros((1, p.fullKern.getNumParams())), 
                lnsigma2=0, 
                lnbeta=0)


    numSparse = 0
    print "Starting ..."
    count = 0

    for iter in range(o.numIters):
        tic = time.time()
        tic0 = tic
        # Ensure repeatability
        state = np.random.get_state()
        # Order users randomly
        userOrder = np.random.permutation(d.data.userIDs())

        # Save state for repeatability
        saveDir = "iter" + str(iter)
        iterDir = os.path.join(resultsDir, saveDir)
        if not os.path.exists(iterDir):
            os.mkdir(iterDir)

        userOrder.tofile(os.path.join(iterDir, "userOrder" ))
        p.param.tofile(os.path.join(iterDir, "param" ))
        p.X.tofile(os.path.join(iterDir, "X" ))
        p.X_u.tofile(os.path.join(iterDir, "X_u" ))
        pc.X.tofile(os.path.join(iterDir, "Xchange" ))
        pc.param.tofile(os.path.join(iterDir, "paramChange" ))
        pc.X_u.tofile(os.path.join(iterDir, "inducingChange" ))

        info = iterInfo(tic = tic, 
                        tic0 = tic0, 
                        count = count, 
                        numSparse = numSparse, 
                        userOrder = userOrder,
                        iterNum = iter)
        runIter(dataSet = d, 
                params = p, 
                paramChange = pc, 
                options = o,
                iterInfo = info,
                iterDir = iterDir)

        count = info.count

    # Save state for repeatability
    saveDir = "final"
    iterDir = os.path.join(resultsDir, saveDir)
    if not os.path.exists(iterDir):
        os.mkdir(iterDir)
    betaSigma = np.array([p.lnbeta, p.lnsigma2, pc.lnbeta, pc.lnsigma2])
    betaSigma.tofile(os.path.join(iterDir, "betaSigma"))
    p.param.tofile(os.path.join(iterDir, "param" ))
    p.X.tofile(os.path.join(iterDir, "X" ))
    p.X_u.tofile(os.path.join(iterDir, "X_u" ))
    pc.X.tofile(os.path.join(iterDir, "Xchange" ))
    pc.param.tofile(os.path.join(iterDir, "paramChange" ))
    pc.X_u.tofile(os.path.join(iterDir, "inducingChange" ))


def runIter(dataSet, params, paramChange, options, iterInfo, iterDir):
    o = options
    d = dataSet
    p = params
    pc = paramChange
    it = iterInfo
    numUsers = len(it.userOrder)
    latentDim = p.X.shape[1]
    countShouldBe = iterInfo.iterNum*numUsers
    startCount = countShouldBe
    for user in it.userOrder:
        if it.count>countShouldBe:
            # for when we are restarting --- get count/user up to right value.
            countShouldBe = countShouldBe + 1
            startCount = countShouldBe
            continue

        countShouldBe = countShouldBe +1

        learnRate = 1.0/(o.lambdaVal*(it.count + o.t0))
        u = d.data.user(user)
        filmRatings = u.ratings()
        filmIndices = u.values()-1

        # Check whether we need to do sparse approximation.
        sparseApprox = False
        sparseFTC = False
        if len(filmRatings)>o.maxFTC:
            if o.sparseApprox==nl.gp.FTC:
                sparseFTC = True # just do FTC multiple times.
            else:
                sparseApprox = True  # do a real sparse approximation.
        
        if sparseFTC:

            parts = int(round(float(len(filmRatings))/750 + 0.5))
            splitPoint = len(filmRatings)/parts
            startPoint = 0
            for i in range(parts-1):
                if i == parts-1:
                    endPoint = -1
                else:
                    endPoint = startPoint+splitPoint
                Xiter, yiter = \
                convertNlMatrix(filmRatings = \
                                filmRatings[startPoint:endPoint].flatten(),
                                filmIndices = \
                                filmIndices[startPoint:endPoint].flatten(),
                                dataSet = d,
                                parameters = p)

                model = nl.gp(latentDim, 1, Xiter, yiter, p.fullKern, p.noise, nl.gp.FTC, 0, 3)
                paramIter = nl.matrix(p.param.shape[0], p.param.shape[1])
                for i in range(p.param.shape[1]):
                    paramIter.setVal(p.param[0, i], 0, i)
                model.setOptParams(paramIter)
                model.setOptimiseX(True)    

                # Do additional parameter changes
                p, pc = updateParam(filmIndices[startPoint:endPoint].flatten(),
                                    model, p, pc, sparseApprox, 
                                    learnRate, options)

                startPoint = endPoint
                
                
                
            endPoint = -1 
            filmRatings = filmRatings[startPoint:endPoint].flatten()
            filmIndices = filmIndices[startPoint:endPoint].flatten()
            Xiter, yiter = \
            convertNlMatrix(filmRatings = \
                            filmRatings,
                            filmIndices = \
                            filmIndices,
                            dataSet = d,
                            parameters = p)
            sparseApprox = False
        else:
            # Remove movie means and divide by movie standard deviations.
            Xiter, yiter = convertNlMatrix(filmRatings = filmRatings,
                                           filmIndices = filmIndices,
                                           dataSet = d,
                                           parameters = p)
                

        paramIter = nl.matrix()



        if sparseApprox:
            p.param[0, -1] = p.lnbeta
            pc.param[0, -1] = pc.lnbeta 

                

            # Set up GPLVM with sparse approximation.
            model = nl.gp(latentDim, 1, Xiter, yiter, p.sparseKern, p.noise, o.sparseApprox, o.numActive, 3)
            paramIter.resize(1, o.numActive*latentDim+p.fullKern.getNumParams())

            # Set the inducing point locations.
            counter2 = 0
            for j in range(latentDim):
                for i in range(o.numActive):
                    paramIter.setVal(p.X_u[i, j], counter2)
                    counter2 += 1

            # Set the parameters.
            for i in range(p.param.shape[1]):
                paramIter.setVal(p.param[0, i], counter2)
                counter2 += 1


            model.setOptParams(paramIter)
            model.setOptimiseX(True)

        else:
            # Set up full GPLVM.
            pc.param[0, -1] = pc.lnsigma2 
            p.param[0, -1] = p.lnsigma2 

            model = nl.gp(latentDim, 1, Xiter, yiter, p.fullKern, p.noise, nl.gp.FTC, 0, 3)
            paramIter = nl.matrix(p.param.shape[0], p.param.shape[1])
            for i in range(p.param.shape[1]):
                paramIter.setVal(p.param[0, i], 0, i)
            model.setOptParams(paramIter)
            model.setOptimiseX(True)    
        

        p, pc = updateParam(filmIndices, model, p, pc, sparseApprox, learnRate, options)

        # extract beta/sigma2 from the model.
        if sparseApprox:
            p.lnbeta = p.param[0, -1]
            pc.lnbeta = pc.param[0, -1]
        else:
            p.lnsigma2 = p.param[0, -1]
            pc.lnsigma2 = pc.param[0, -1]

        # Finished one iteration
        it.count = it.count + 1
        # Check if it's time to display
        if not np.remainder(it.count, o.showEvery):
            print "Count " + str(it.count)
            toc = time.time()
            eTime = toc - it.tic;
            totTime = toc - it.tic0;
            usersPerSecond = (it.count-startCount)/totTime
            remainUserIters = numUsers*o.numIters - it.count
            remainTime = remainUserIters/usersPerSecond
            it.tic = toc
            print("Remain time (hrs): " + str(remainTime/3600))
            sys.stdout.flush()

        # Check if it's time to save
        if not np.remainder(it.count, o.saveEvery):
            print("Saving file ...")
            toc = time.time()
            eTime = toc - it.tic;
            totTime = toc - it.tic0;
            usersPerSecond = it.count/totTime
            remainUserIters = numUsers*o.numIters - it.count
            remainTime = remainUserIters/usersPerSecond
            it.tic = toc
            print("Remain time (hrs): " + str(remainTime/3600))
            dirName = "count" + str(it.count) + "_user" + str(user)
            saveDir = os.path.join(iterDir, dirName)
            if not os.path.exists(saveDir):
                os.mkdir(saveDir)
            betaSigma = np.array([p.lnbeta, p.lnsigma2, pc.lnbeta, pc.lnsigma2])
            betaSigma.tofile(os.path.join(saveDir, "betaSigma"))
            p.param.tofile(os.path.join(saveDir, "param" ))
            model.toFile(os.path.join(saveDir, "gp" ))
            p.X.tofile(os.path.join(saveDir, "X" ))
            p.X_u.tofile(os.path.join(saveDir, "X_u" ))
            pc.X.tofile(os.path.join(saveDir, "Xchange" ))
            pc.param.tofile(os.path.join(saveDir, "paramChange" ))
            pc.X_u.tofile(os.path.join(saveDir, "inducingChange" ))
            sys.stdout.flush()


def updateParam(filmIndices, model, p, pc, sparseApprox, learnRate, o):

    latentDim = p.X.shape[1]
    giter = nl.matrix(1, model.getOptNumParams())
    model.computeObjectiveGradParams(giter)
    g = np.zeros((giter.getRows(), giter.getCols()))
    g = giter.toarray()

    ####### Get X Gradients and update #######################
    endPoint = model.getNumData()*latentDim
    # Add "weight decay" term to gradient.
    gX = g[0, 0:endPoint].reshape((latentDim, model.getNumData())).transpose() 

    # find the last changes associated with these indices.
    XTempChange = pc.X[filmIndices, :]

    # momentum times the last change plus gradient times learning
    # rate is new change.
    #adjustRates = d.learnRateAdjust[filmIndices]*learnRate
    ##adjustRates[np.nonzero(adjustRates>o.maxLearnRate)] = o.maxLearnRate
    adjustRates = learnRate*10.0
    XTempChange = XTempChange*o.momentum + gX*adjustRates
    # store new change
    pc.X[filmIndices, :] = XTempChange
    # update X
    p.X[filmIndices, :] = p.X[filmIndices, :] - XTempChange
    # Apply "weight decay" globally to X --- v. sparse stray data
    # points back towards the centre.
    #p.X = p.X - p.X*learnRate 

    if sparseApprox:
    ####### Get inducing variable gradients and update #######
        startPoint = endPoint 
        endPoint = startPoint + o.numActive*latentDim
        gX_u = g[0, startPoint:endPoint].reshape((model.getInputDim(), o.numActive)).transpose()
        
        # update inducingChange
        pc.X_u = pc.X_u*o.momentum + gX_u*learnRate
        
        # update X_u
        p.X_u = p.X_u - pc.X_u

    ####### Get parameter gradients and update ###################
    startPoint = endPoint
    endPoint = startPoint + p.fullKern.getNumParams()

    # update paramChange
    pc.param = pc.param*o.momentum + g[0, startPoint:endPoint]*learnRate
    # update parameters
    p.param = p.param - pc.param
    return p, pc


def predVal(user, testFilmId, parameters, dataSet):
    """Make a prediction for the given user and the given film ID."""

    latentDim = parameters.X.shape[1]
    useForPred = 500
    u = dataSet.data.user(user)
    filmRatings = u.ratings()
    filmIndices = u.values()-1
    d2 = netlab.dist2(parameters.X[filmIndices, :], parameters.X[testFilmId, :].reshape((1, latentDim)))
    if useForPred < len(filmIndices):
        perm = np.argsort(d2, axis=0)
        filmRatings = filmRatings[perm[0:useForPred]].flatten()
        filmIndices = filmIndices[perm[0:useForPred]].flatten()

    xstar = nl.matrix(1, latentDim)
    for i in range(latentDim):
        xstar.setVal(parameters.X[testFilmId, i], i)
    
    X, y = convertNlMatrix(filmRatings=filmRatings, \
                               filmIndices=filmIndices, \
                               dataSet=dataSet, \
                               parameters=parameters)
    K = nl.matrix(X.getRows(), X.getRows())
    kstar = nl.matrix(X.getRows(), 1)
    pred = nl.matrix(X.getRows(), 1)

    parameters.fullKern.compute(K, X);
    parameters.fullKern.compute(kstar, X, xstar);
    K.pdinv() # now invK
    pred.gemv(K, kstar, 1.0, 0.0, "n") # K
    mean = pred.dotColCol(0, y, 0)
    diag = parameters.fullKern.diagComputeElement(xstar, 0)
    var = diag - pred.dotColCol(0, kstar, 0)
    return mean, var


def preprocessRatings(filmRatings, filmIndices, dataSet):
    """Run the preprocessing of the film ratings using the mean for
    the movie and its standard deviation"""

    y = np.reshape((filmRatings.flatten()-dataSet.movieMean[filmIndices].flatten()) \
                       /dataSet.movieStd[filmIndices].flatten(), \
                       (len(filmIndices), 1))

    return y

def convertNlMatrix(filmRatings, filmIndices, dataSet, parameters):
    """Take in the filmRatings vector and the film indices data along with the data set and the parameters. Return ndlml.matrix for X and y"""
    
    latentDim = parameters.X.shape[1]
    y = preprocessRatings(filmRatings=filmRatings, \
                              filmIndices=filmIndices, \
                              dataSet=dataSet)
    
    # Xiter, yiter, paramIter are the things to be passed to the
    # nl.gp model for finding the gradient. They must be in the
    # form of nl.matrix().
    Xiter = nl.matrix(len(filmIndices), latentDim)
    yiter = nl.matrix(len(filmIndices), 1)
    count3 = 0
    for i in filmIndices:
        yiter.setVal(y[count3, 0], count3, 0)
        for j in range(latentDim):
            Xiter.setVal(parameters.X[i, j], count3, j)
        count3=count3 + 1
    return Xiter, yiter


def predictProbe(latentDim, dataSetName, experimentNo, loadIter, loadUser, loadCount, options):

    resultsDir = os.path.join(options.resultsBaseDir, "netflix" + str(experimentNo))

    loadDir1 = "iter" + str(loadIter)
    loadDir2 = "count" + str(loadCount) + "_user" + str(loadUser)

    loadDir = os.path.join(resultsDir, loadDir1, loadDir2)

    p, pc = loadResults(loadDir, latentDim, options)

    d = loadData(dataSetName)

    print "Loading netflix probe data ..."
    probe = pyflix.datasets.RatedDataset(os.path.join(dataDir(),'probe_set'))

    total = 0
    totalSe = 0.0
    userIds = probe.userIDs()
    for user in np.sort(userIds):
        up = probe.user(user)

        filmRatings = up.ratings()
        filmIndices = up.values()-1
        
        u = d.data.user(user)
        testLen = len(u.ratings())
        count =0
        for film in filmIndices:
            total += 1
            if count>9:
                pdb.set_trace()
            (pred, var) = predVal(user, film, p, d)
            pred = pred*d.movieStd[film] + d.movieMean[film]
            newSe = (pred - filmRatings[count])**2
            totalSe += newSe
            rmse = math.sqrt(totalSe/float(total))
            if not np.remainder(total, 500):
                print "Total Count: ", total, " rmse: ", rmse #, "pred ", pred, "True: ", filmRatings[count], "var: ", var
            count += 1
            
