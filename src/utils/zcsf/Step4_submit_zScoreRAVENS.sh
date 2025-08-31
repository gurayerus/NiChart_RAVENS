#! /bin/bash -x

pwd=`pwd`

bdir='/cbica/home/erusg/2_STUDIES/ChristosRubenCases/Pipelines/20241114_zCSF'

exe=${bdir}/Scripts/Step4_submitarray_zScoreRAVENS.sh

#########################################
### Paths for data

reflist=${bdir}/Protocols/MatchingLists/list_ref.csv

rPathIn=${bdir}/Protocols/CSF-RAVENS-CRC
rPathRef=${bdir}/Protocols/CSF-RAVENS-UKBB

rSuff='_T1_LPS_dlicv_seg_ants-0.3_RAVENS_1_DS222_s8.nii.gz'


csvICVIn=${bdir}/Data/CRC_DLICVVol.csv
csvICVRef=${bdir}/Data/UKBB_DLICVVol.csv

outDir=${bdir}/Protocols/CSF-RAVENS-CRC-zScored

#########################################

mList=${csvMatchDir}/ListMatchCount.csv
FROM=1
TO=`cat $mList | wc -l`

mkdir -pv ${pwd}/logs

# qsub -l h_rt=00:10:00 -l h_vmem=24G -t ${FROM}-${TO} -j y -o ${pwd}/logs/\$JOB_NAME-\$JOB_ID.log $exe $matchDir $rPathIn $rPathRef $rSuff $csvICVIn $csvICVRef $outDir
$exe $csvMatchDir $rPathIn $rPathRef $rSuff $csvICVIn $csvICVRef $outDir

    
