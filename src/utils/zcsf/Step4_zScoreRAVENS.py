import numpy as np
import pandas as pd
import os
import nibabel as nib
import sys

import numpy as np
from scipy.spatial import distance_matrix

def calcZ(inFile, refFileList, corrICV, icvSub = [], refICV = []):
    
    MASK_TH = 50
    
    if corrICV == 1:
        meanICV = np.mean(refICV)
    
    if os.path.exists(inFile):
        nii = nib.load(inFile)
        inImg = nii.get_fdata()
    else:
        print(inFile)
        return [[],[]]
    
    imgShape = inImg.shape
    numVox = np.prod(imgShape)
    
    inImg = inImg.flatten()
    if corrICV == 1:
         inImg = inImg / icvSub * meanICV
    
    refImg = np.zeros([len(refFileList), numVox])
    
    nref = 0    
    listMiss = []
    for i, tmpImg in enumerate(refFileList):
    #for i, tmpImg in enumerate(refFileList[0:20]):
        if os.path.exists(tmpImg):
            print('Read img : ' + str(i))
            
            tmpImg = nib.load(tmpImg).get_fdata().flatten()
            if corrICV == 1:
                tmpImg = tmpImg / refICV[i] * meanICV
            
            refImg[nref, :] = tmpImg
            
            nref = nref + 1
        else:
            listMiss.append(tmpImg)
    refImg = refImg[0:nref,:]
    
    meanImg = np.mean(refImg, axis=0)
    stdImg = np.std(refImg, axis=0)
    
    ### Mask small RAVENS values
    mask = meanImg<MASK_TH
    inImg[mask] = 0
    meanImg[mask] = 0
    stdImg[mask] = 1
    
    print(meanImg.shape)
    print(stdImg.shape)
    
    inImgZ = ((inImg - meanImg) / stdImg).reshape(imgShape)
    
    inImg =inImg.reshape(imgShape)
    meanImg =meanImg.reshape(imgShape)
    stdImg =stdImg.reshape(imgShape)
    

    return [nii, inImgZ, inImg, meanImg, stdImg, listMiss, nref]


########################################
### Input args
inSub = sys.argv[1]
########################################


#inSub = 'ColMRICenter_JC_20241101'
csvMatch = '../Protocols/MatchingLists/list_ref.csv'
rPathIn = '../Protocols/CSF-RAVENS-CRC'
rPathRef = '../Protocols/CSF-RAVENS-UKBB'
rSuff = '_T1_LPS_dlicv_seg_ants-0.3_RAVENS_1_DS222_s8.nii.gz'
csvVolIn = '../Data/CRC_DLICVVol.csv'
csvVolRef = '../Data/UKBB_DLICVVol.csv'
outDir = '../Protocols/CSF-RAVENS-CRC-zScored'


if not os.path.exists(outDir):
    os.makedirs(outDir)

### Read data
df = pd.read_csv(csvMatch)[['MRID']]
dfVolIn = pd.read_csv(csvVolIn)
dfVolRef = pd.read_csv(csvVolRef)

### Add ICV
df = df.merge(dfVolRef, how='left', on = 'MRID')
df = df.dropna()

### Get ICV for subject
icvSub = dfVolIn[dfVolIn.MRID == inSub].DLICVVol.values[0]

### Create file names
inFile = rPathIn + '/' + inSub + '/' + inSub + rSuff
df['refFileList'] = rPathRef + '/' + df.MRID + '/' + df.MRID + rSuff


###################################################
## Combine RAVENS and calculate z scores ICV CORR
[nii, inImgZ, inImg, meanImg, stdImg, listMiss, nref] = calcZ(inFile, df.refFileList.tolist(), 1, icvSub, df.DLICVVol.tolist())

### Write out img

outPref = outDir + '/' + inSub

outF = outPref + '_RAVENS_zICVCorr.nii.gz'
niiOut = nib.Nifti1Image(inImgZ, nii.affine, nii.header)
nib.save(niiOut, outF)

#outF = outPref + '_RAVENS_ICVCorr.nii.gz'
#niiOut = nib.Nifti1Image(inImg, nii.affine, nii.header)
#nib.save(niiOut, outF)

#outF = outPref + '_meanRAVENS_ICVCorr.nii.gz'
#niiOut = nib.Nifti1Image(meanImg, nii.affine, nii.header)
#nib.save(niiOut, outF)

#outF = outPref + '_stdRAVENS_ICVCorr.nii.gz'
#niiOut = nib.Nifti1Image(stdImg, nii.affine, nii.header)
#nib.save(niiOut, outF)

dfOut = pd.DataFrame(data=listMiss, columns=['MissingFiles'])
dfOut.to_csv(outPref + '_missingFiles', index=False)

dfOut = pd.DataFrame(data=[nref], columns=['NumRef'])
dfOut.to_csv(outPref + '_NumRef', index=False)



####################################################
### Combine RAVENS and calculate z scores NO ICV CORR
#[nii, inImgZ, inImg, meanImg, stdImg, listMiss, nref] = calcZ(inFile, df.refFileList.tolist(), 0)

#### Write out img
#outF = outPref + '_RAVENS_z.nii.gz'
#niiOut = nib.Nifti1Image(inImgZ, nii.affine, nii.header)
#nib.save(niiOut, outF)

#outF = outPref + '_meanRAVENS.nii.gz'
#niiOut = nib.Nifti1Image(meanImg, nii.affine, nii.header)
#nib.save(niiOut, outF)

#outF = outPref + '_stdRAVENS.nii.gz'
#niiOut = nib.Nifti1Image(stdImg, nii.affine, nii.header)
#nib.save(niiOut, outF)

    
