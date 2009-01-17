
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


class iterInfo:
    """A class containing information for the current iteration."""
    def __init__(self, tic, tic0, count, numSparse, userOrder):
        self.tic = tic
        self.tic0 = tic0
        self.count = count
        self.numSparse = numSparse
        self.userOrder = userOrder

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
    resultsBaseDir = "."
    
        
def loadData(dataSetName):
    """Load the given dataset."""
    if dataSetName=="netflix":
        isNetflix = True
        # load in data netflix.
        baseDir = os.path.join('/local', 'data', 'pyflix')
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
    
    print fullKern
    print sparseKern

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

#def restart(latentDim, dataSetName, experimentNo, options):
    

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
    print fullKern
    print sparseKern
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
    tic = time.time()
    tic0 = tic
    count = 0

    for iter in range(o.numIters):
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
                        userOrder = userOrder)
        runIter(dataSet = d, 
                params = p, 
                paramChange = pc, 
                options = o,
                iterInfo = info)

    # Save state for repeatability
    saveDir = "final"
    iterDir = os.path.join(resultsDir, saveDir)
    if not os.path.exists(iterDir):
        os.mkdir(iterDir)
    betaSigma.tofile(os.path.join(iterDir, "betaSigma"))
    p.param.tofile(os.path.join(iterDir, "param" ))
    p.X.tofile(os.path.join(iterDir, "X" ))
    p.X_u.tofile(os.path.join(iterDir, "X_u" ))
    pc.X.tofile(os.path.join(iterDir, "Xchange" ))
    pc.param.tofile(os.path.join(iterDir, "paramChange" ))
    pc.X_u.tofile(os.path.join(iterDir, "inducingChange" ))


def runIter(dataSet, params, paramChange, options, iterInfo):
    o = options
    d = dataSet
    p = params
    pc = paramChange
    it = iterInfo
    numUsers = len(it.userOrder)
    latentDim = p.X.shape[1]
    
    for user in it.userOrder:
        learnRate = 1.0/(o.lambdaVal*(it.count + o.t0))
        u = d.data.user(user)
        filmRatings = u.ratings()
        filmIndices = u.values()-1

        if len(filmRatings)>o.maxFTC:
            it.numSparse += 1
            if o.sparseApprox==nl.gp.FTC:
                # Assume that we are ignoring large data.
                print "Warning, skipping data point with ", len(filmRatings), " ratings."
                continue
            sparseApprox = True
        else:
            sparseApprox = False

        # Remove movie means and divide by movie standard deviations.
        y = np.reshape((filmRatings-d.movieMean[filmIndices].flatten())/d.movieStd[filmIndices].flatten(), (len(filmIndices), 1))

        # Xiter, yiter, paramIter are the things to be passed to the
        # nl.gp model for finding the gradient. They must be in the
        # form of nl.matrix().
        Xiter = nl.matrix()
        Xiter.fromarray(p.X[filmIndices, :])

        yiter = nl.matrix()
        yiter.fromarray(y)

        paramIter = nl.matrix()


        if sparseApprox:
            # Set up GPLVM with sparse approximation.
            p.param[0, -1] = p.lnbeta
            pc.param[0, -1] = pc.lnbeta 
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
            paramIter.fromarray(p.param)
            model.setOptParams(paramIter)
            model.setOptimiseX(True)    

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
        adjustRates = d.learnRateAdjust[filmIndices]*learnRate
        adjustRates[np.nonzero(adjustRates>o.maxLearnRate)] = o.maxLearnRate
        XTempChange = XTempChange*o.momentum + gX*adjustRates
        # store new change
        pc.X[filmIndices, :] = XTempChange
        # update X
        p.X[filmIndices, :] = p.X[filmIndices, :] - XTempChange
        # Apply "weight decay" globally to X --- v. sparse stray data
        # points back towards the centre.
        p.X = p.X - p.X*learnRate 

        if sparseApprox:
        ####### Get inducing variagle gradients and update #######
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
            usersPerSecond = it.count/totTime
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



