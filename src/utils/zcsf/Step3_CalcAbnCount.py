#############################################################################
### Script for calculating count of abnormal z-scores
###
###  Specifics:
###   - Hard-coded here for: 
###        - UKBB data
###        - zScored CSFROIs (separately for single and derived rois)
###        - Applied for multiple z threshold values

import numpy as np
import pandas as pd
import os
import nibabel as nib
import sys
import numpy as np


########################################
### Input args
oDir = '../Protocols/CSFROI_AbnCounts'

#zList = '../Protocols/CSFROI_zScored/CSFROI_ICVCorr_zScore_AgeSexMatched.csv'
#oCsv = oDir + '/AbnCount_zCSFROI.csv'

zList = '../Protocols/CSFROI_zScored/CSFDerivedROI_ICVCorr_zScore_AgeSexMatched.csv'
oCsv = oDir + '/AbnCount_zCSFDerivedROI.csv'

ZTH = [2, 2.5, 3, 3.5, 4]
ZTHTXT = ['ZTH_' + str(x) for x in ZTH]

########################################

if not os.path.exists(oDir):
    os.makedirs(oDir)

### Read data
df = pd.read_csv(zList)

dfOut = df[['MRID']]
dfOut = dfOut.reindex(dfOut.columns.tolist() + ZTHTXT, axis=1)

## Calc counts for z scores
for i, thTmp in enumerate(ZTH):
    dfOut.loc[:, ZTHTXT[i]] = (df[df.columns[1:]] > thTmp).astype(int).sum(axis=1)

df = df.dropna()
if not os.path.exists(oCsv):
    dfOut.to_csv(oCsv, index=False)
