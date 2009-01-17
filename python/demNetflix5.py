#!/usr/bin/env python



# Try collaborative filtering on the netflix data.
import collab
import ndlml as nl
opt = collab.defaultOptions()
opt['resultsBaseDir'] = "/local/data/results/netflix/"

collab.run(latentDim=5,
           dataSetName='netflix',
           experimentNo=5,
           options=opt)
