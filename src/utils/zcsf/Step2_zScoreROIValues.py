#############################################################################
### Script for zscoring values using matched samples as reference
###
###  Specifics:
###   - Hard-coded here for: 
###        - UKBB data
###        - CSFROIs
###        - Values are corrected for (normalized by) ICV
###        - Ref subjects are previously calculated and saved with a single list per subject
###        - Count of matches is previously calculated and saved in a list file to select subjects 
###        - We exclude here subjects with < 50 matches 

import numpy as np
import pandas as pd
import os
import nibabel as nib
import sys

import numpy as np
from scipy.spatial import distance_matrix

def calcZ(selMRID, dfInROI, dfRefROI):
    
    refVals = dfRefROI.drop(columns=['MRID']).dropna()
    subVals = dfInROI[dfInROI.MRID == selMRID].drop(columns=['MRID']).dropna()

    zVals = ((subVals - refVals.mean()) / refVals.std())
    zVals.index = [selMRID]
    zVals = zVals.add_prefix('zROI_')
    zVals = zVals.reset_index()
    zVals = zVals.rename(columns={'index':'MRID'})
    
    return zVals


########################################
### Input args

outDir = '../Protocols/CSFROI_zScored'

listPath = '../Protocols/MatchingLists'
csvMatch = listPath + '/list_ref.csv'

fInICV= '../Data/CRC_DLICVVol.csv'
fRefICV= '../Data/UKBB_DLICVVol.csv'

fInROI= '../Data/CRC_CSF-ROIs-Dil3.csv'
fRefROI= '../Data/UKBB_CSF-ROIs-Dil3.csv'
outCsv = outDir + '/CSFROI_ICVCorr_zScore_AgeSexMatched.csv'

#fInROI= '../Data/CRC_CSF-DerivedROIs-Dil3.csv'
#fRefROI= '../Data/UKBB_CSF-DerivedROIs-Dil3.csv'
#outCsv = outDir + '/CSFDerivedROI_ICVCorr_zScore_AgeSexMatched.csv'

FLAG_ICVCorr = 1
ICVCol = 'DLICVVol'

########################################

if not os.path.exists(outDir):
    os.makedirs(outDir)

## Read data files
dfInROI = pd.read_csv(fInROI)
dfInICV = pd.read_csv(fInICV)

dfMatch = pd.read_csv(csvMatch)[['MRID']]
dfRefROI = pd.read_csv(fRefROI)
dfRefICV = pd.read_csv(fRefICV)

## Merge data files
dfInROI = dfInICV.merge(dfInROI, how='inner', left_on='MRID', right_on='MRID')
dfRefROI = dfRefICV.merge(dfRefROI, how='inner', left_on='MRID', right_on='MRID')

## Filter ref vals
dfRefROI = dfMatch.merge(dfRefROI, on='MRID')

## Correct ICV
if FLAG_ICVCorr == 1:
    roiCol = dfInROI.columns[2:]
    meanICV = dfRefROI[ICVCol].mean()
    dfInROI.loc[:,roiCol] = dfInROI[roiCol].div(dfInROI[ICVCol], axis=0) * meanICV
    dfRefROI.loc[:,roiCol] = dfRefROI[roiCol].div(dfRefROI[ICVCol], axis=0) * meanICV

listZROI = []

## Calculate zscored values
numScan = dfInROI.shape[0]
for i, selMRID in enumerate(dfInROI.MRID.tolist()):

    ## Calculate z scores
    print('Subj : ' + str(i) + '  /  ' + str(numScan))
    zVals = calcZ(selMRID, dfInROI, dfRefROI)
    listZROI.append(zVals)

## Write out df
dfOut = pd.concat(listZROI)
dfOut.to_csv(outCsv, index=False)

