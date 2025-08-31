#!/bin/sh

scr='Step4_zScoreRAVENS.py'

## Input args
mDir=''
rPathIn='../Protocols/CSF-RAVENS-CRC'
rPathRef='../Protocols/CSF-RAVENS-UKBB'
rSuff='_T1_LPS_dlicv_seg_ants-0.3_RAVENS_1_DS222_s8.nii.gz'
csvVolIn='../Data/CRC_DLICVVol.csv'
csvVolRef='../Data/UKBB_DLICVVol.csv'
outDir='../Protocols/CSF-RAVENS-CRC-zScored'

subList='../Protocols/MatchingLists/list_ref.csv'

for ll in `sed 1d ../Lists/list_id.csv`; do
    echo "Running for subject: $ll"

    if [ ! -e ${outDir}/${ll}_RAVENS_zICVCorr.nii.gz ]; then
        python ${scr} $ll
        read -p ee
    fi

done
    
