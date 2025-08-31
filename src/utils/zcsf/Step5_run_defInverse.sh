#! /bin/bash

odir=/cbica/home/erusg/5_Papers/20220217_DLICV/Pipelines/CSF-RAVENS/Protocols/ANTS_INVERT/UKBB
scr=/cbica/home/erusg/5_Papers/20220217_DLICV/Pipelines/CSF-RAVENS/Scripts/TBI-WarpInverse-Pipeline.sh

mkdir -pv ${odir}/sge

# for ll in 1046247 1024260 1028520 1015148 1036188 1059108 1012798 1031913 ; do
#     sub=${ll}_2_0
#     echo "Subject : $sub"
#     qsub -j y -o ${odir}/sge/\$JOB_NAME-\$JOB_ID.log $scr $sub
#     
# #     echo $scr $sub
# #     $scr $sub   
# #     read -p ee
#     
# done



for ll in 1031913 ; do
    sub=${ll}_2_0
    echo "Subject : $sub"
    
    echo $scr $sub
#     $scr $sub   
    read -p ee
    
done
