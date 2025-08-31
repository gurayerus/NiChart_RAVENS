#! /bin/bash

## HARD CODED ARGS
COLIN_IMG='/cbica/home/erusg/5_Papers/20220217_DLICV/Pipelines/CSF-RAVENS/Templates/colin27_t1_tal_lin/colin27_t1_tal_lin_inv.nii.gz'
CSF_PATH='../Protocols/CSF-RAVENS-CRC'
Z_PATH='../Protocols/CSF-RAVENS-CRC-zScored'

OUT_DIR='../Protocols/ANTSInvert_CSF-RAVENS-CRC-zScored'
PARAM='0.3'

## INPUT ARGS
SUB='ColMRICenter_JC_20241101'

##########################################################
## Make out dir
OUT_SUB=${OUT_DIR}/${SUB}
mkdir -pv $OUT_SUB

##########################################################
## Calculate ants def
T1_INIT=${CSF_PATH}/${SUB}/${SUB}_ICV_inv.nii.gz
OUT_WARP=${OUT_SUB}/${SUB}_toColin.nii.gz
if [ ! -e ${OUT_WARP%.nii.gz}Warp.nii.gz ]; then
    ANTS 3 -m PR[${COLIN_IMG},${T1_INIT},1,2] -i 10x50x50x10 -o ${OUT_WARP} -t SyN[${PARAM}] -r Gauss[2,0]
    
#     read -p ee
fi

##########################################################
## Upsample zMap
Z_INIT=${Z_PATH}/${SUB}/${SUB}_RAVENS_zICVCorr.nii.gz
R_INIT=${CSF_PATH}/${SUB}/${SUB}_ICV_seg_ants-0.3_RAVENS_1.nii.gz
Z_UP=${OUT_SUB}/${SUB}_RAVENS_zICVCorr_UP.nii.gz

if [ ! -e ${Z_UP} ]; then
    3dresample -master $R_INIT -rmode Cu -prefix $Z_UP -inset $Z_INIT
fi


##########################################################
## Warp upsampled map to init subj space
W1=${OUT_SUB}/${SUB}_toColinAffine.txt
W2=${OUT_SUB}/${SUB}_toColinInverseWarp.nii.gz

Z_UP_SUB=${OUT_SUB}/${SUB}_RAVENS_zICVCorr_UP_SUB.nii.gz

if [ ! -e $Z_UP_SUB ]; then
    antsApplyTransforms -d 3 -i $Z_UP -o $Z_UP_SUB -r $T1_INIT -t [$W1,1] -t $W2
fi

# 
# antsApplyTransforms -d 3 -i   1015148_2_0_ICV_inv.nii.gz  -o  1015148_2_0_ICV_inv_COLIN.nii.gz   -r  1015148_2_0_ICV_seg_ants-0.3_RAVENS_1.nii.gz  -t  1015148_2_0_toColinAffine.txt    -t   1015148_2_0_toColinWarp.nii.gz




