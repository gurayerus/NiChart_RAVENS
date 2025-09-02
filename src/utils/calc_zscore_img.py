import numpy as np
import pandas as pd
import os
import nibabel as nib
import sys

import numpy as np
from scipy.spatial import distance_matrix

import os
import numpy as np
import nibabel as nib

import os
import numpy as np
import nibabel as nib

def read_images_to_matrix(df_images, num_vox=None):
    """
    Reads MRI images listed in a DataFrame into a 2D numpy matrix.

    Parameters
    ----------
    df_images : pandas.DataFrame
        DataFrame with columns ["MRID", "FileName"].
    num_vox : int, optional
        Number of voxels to keep after flattening. If None,
        it will be inferred from the first successfully read image.

    Returns
    -------
    matrix : np.ndarray
        Shape (n_subjects, num_vox). Each row is a vectorized MRI image.
        Rows for failed reads will be all zeros.
    mrids : list
        List of MRIDs corresponding to the rows in the matrix.
    df_images : pandas.DataFrame
        Original DataFrame with an added "ImageRead" column (True/False).
    """

    df_images = df_images.copy()
    df_images["ImageRead"] = False
    n_subjects = len(df_images)

    # If num_vox not provided, find from first readable image
    if num_vox is None:
        for file_path in df_images["FileName"]:
            if os.path.exists(file_path):
                try:
                    img = nib.load(file_path)
                    num_vox = img.get_fdata().size
                    break
                except Exception:
                    continue
        if num_vox is None:
            raise ValueError("Could not determine num_vox (no valid images).")

    # Preallocate matrix
    matrix = np.zeros((n_subjects, num_vox), dtype=np.float32)

    mrids = df_images["mrid"].tolist()

    for idx, row in df_images.iterrows():
        file_path = row["FileName"]

        if not os.path.exists(file_path):
            continue

        try:
            img = nib.load(file_path)
            data = img.get_fdata()
            vector = data.flatten()

            # Trim or pad to match num_vox
            if len(vector) > num_vox:
                vector = vector[:num_vox]
            elif len(vector) < num_vox:
                vector = np.pad(vector, (0, num_vox - len(vector)), mode="constant")

            matrix[idx, :] = vector
            df_images.at[idx, "ImageRead"] = True

        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            continue

    return matrix, mrids, df_images

def calc_zscore_img(in_file, list_ref_files, flag_icvcorr, in_icv = [], ref_icv = []):
    
    MASK_TH = 50
    
    if flag_icvcorr == 1:
        mean_icv = np.mean(ref_icv)

    if os.path.exists(in_file):
        nii = nib.load(in_file)
        in_img = nii.get_fdata()
    else:
        return [[],[]]
    
    img_shape = in_img.shape
    num_vox = np.prod(img_shape)
    
    in_img = in_img.flatten()
    if flag_icvcorr == 1:
         in_img = in_img / in_icv * mean_icv
    
    mean_img = np.mean(ref_img, axis=0)
    std_img = np.std(ref_img, axis=0)
    
    ### Mask small RAVENS values
    mask = mean_img<MASK_TH
    in_img[mask] = 0
    mean_img[mask] = 0
    std_img[mask] = 1
    
    print(mean_img.shape)
    print(std_img.shape)
    
    in_img_z = ((in_img - mean_img) / std_img).reshape(img_shape)
    
    in_img =in_img.reshape(img_shape)
    mean_img =mean_img.reshape(img_shape)
    std_img =std_img.reshape(img_shape)
    

    return [nii, in_img_z, in_img, mean_img, std_img, list_miss, nref]


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
in_icv = dfVolIn[dfVolIn.MRID == inSub].DLICVVol.values[0]

### Create file names
in_file = rPathIn + '/' + inSub + '/' + inSub + rSuff
df['list_ref_files'] = rPathRef + '/' + df.MRID + '/' + df.MRID + rSuff


###################################################
## Combine RAVENS and calculate z scores ICV CORR
[nii, in_img_z, in_img, mean_img, std_img, list_miss, nref] = calc_zscore_img(
    in_file, df.list_ref_files.tolist(), 1, in_icv, df.DLICVVol.tolist()
)

### Write out img

outPref = outDir + '/' + inSub

outF = outPref + '_RAVENS_zICVCorr.nii.gz'
niiOut = nib.Nifti1Image(in_img_z, nii.affine, nii.header)
nib.save(niiOut, outF)

dfOut = pd.DataFrame(data=list_miss, columns=['MissingFiles'])
dfOut.to_csv(outPref + '_missingFiles', index=False)

dfOut = pd.DataFrame(data=[nref], columns=['NumRef'])
dfOut.to_csv(outPref + '_NumRef', index=False)

    
