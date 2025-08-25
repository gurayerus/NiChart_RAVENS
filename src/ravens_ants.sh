#!/usr/bin/bash
#
# ==========================================================
# Script: ravens_ants.sh
# Purpose: Compute tissue density maps (RAVENS maps) using ANTs
# Author: Guray Erus
# Date: 2025-08-25
# ==========================================================
#
# Description:
#   This script calculates RAVENS maps by warping a source image 
#   into target space using ANTs and applying the corresponding 
#   transformations to segmentation masks. The tissue density maps 
#   reflect local volumetric changes across subjects.
#
# Requirements:
#   - ANTs (>=2.0)
#   - bash
#
# Usage:
#   See usage
#
# ==========================================================

# Default values for optional arguments
p_reg="minimal"
f_val=1000

# Usage message
usage() {
  echo "Usage: $0 -s <source_file> -l <label_file> -t <target_file> -d <output_dir> -r <output_prefix> [-p <string>] [-i <string>] [-f <int>]"
  echo
  echo "Required:"
  echo "  -s   Source image file (absolute path)"
  echo "  -l   Label image file (absolute path)"
  echo "  -t   Target image file (absolute path)"
  echo "  -d   Output folder (absolute path)"
  echo "  -r   Output prefix"
  echo
  echo "Optional:"
  echo "  -p   Registration mode (default: old_v0)"
  echo "  -i   Labels used for output RAVENS (default: All label values other than 0)"
  echo "  -f   Scaling factor (default: 1000)"

  echo "Example:"
  echo "ravens_ants.sh -s subj01_T1.nii.gz -l subj01_labels.nii.gz\\"
  echo " -t template.nii.gz -d ravens_out -r subj01_"

  echo "Notes:"
  echo " - All input files should be in NIfTI format (.nii or .nii.gz)."
  echo " - The script creates a temporary working directory in the output folder."
  exit 1
}

# Set number of threads for speed
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=8

##############################################
## Core function (to run different versions of ANTs)
ants_reg() {
  local profile="$1"
  local fixed="$2"
  local moving="$3"
  local outprefix="$4"

  # Choose options based on profile
  case "$profile" in
    auto)
      cmd=(antsRegistrationSyN.sh
        -d 3
        -f "$fixed"
        -m "$moving"
        -o "$outprefix"
      )
      ;;
    minimal)
      cmd=(antsRegistration
        --dimensionality 3 --float 1
        --output ["${outprefix}",${outprefix}Warped.nii.gz]
        --interpolation Linear
        --use-histogram-matching 0
        --initial-moving-transform ["$fixed","$moving",1]
        --verbose 1        
        --transform Rigid[0.1]
          --metric MI["$fixed","$moving",1,32,Regular,0.25]
          --convergence [40x20x0,1e-6,10]
          --shrink-factors 4x2x1
          --smoothing-sigmas 2x1x0vox
        --transform Affine[0.1]
          --metric MI["$fixed","$moving",1,32,Regular,0.25]
          --convergence [40x20x0,1e-6,10]
          --shrink-factors 4x2x1
          --smoothing-sigmas 2x1x0vox          
        --transform SyN[0.25,3,0]
          --metric CC["$fixed","$moving",1,4]
          --convergence [70x40x20,1e-6,10]
          --shrink-factors 4x2x1
          --smoothing-sigmas 2x1x0vox
      )
      ;;
    balancedv2)
      cmd=(antsRegistration
        --dimensionality 3 --float 1
        --output ["${outprefix}",${outprefix}Warped.nii.gz]
        --interpolation Linear
        --use-histogram-matching 0
        --initial-moving-transform ["$fixed","$moving",1]
        --transform Rigid[0.1]
          --metric MI["$fixed","$moving",1,32,Regular,0.25]
          --convergence [100x50x25,1e-6,10]
          --shrink-factors 6x3x1
          --smoothing-sigmas 3x2x1vox
        --transform SyN[0.25,3,0]
          --metric CC["$fixed","$moving",1,4]
          --convergence [70x40x20,1e-6,10]
          --shrink-factors 4x2x1
          --smoothing-sigmas 2x1x0vox
          --verbose 1
      )
      ;;
    balanced)
      cmd=(antsRegistration
        --verbose 1
        --dimensionality 3 
        --float 0
        --collapse-output-transforms 1
        --output ["${outprefix}",${outprefix}Warped.nii.gz,${outprefix}InwerseWarped.nii.gz]
        --interpolation Linear
        --use-histogram-matching 0
        --winsorize-image-intensities [0.005,0.995] 
        --initial-moving-transform ["$fixed","$moving",1]
        --transform Rigid[0.1]
          --metric MI["$fixed","$moving",1,32,Regular,0.25]
          --convergence [5x5x1,1e-6,10]
          --shrink-factors 4x2x1
          --smoothing-sigmas 2x1x0vox
        --transform Affine[0.1]
          --metric MI["$fixed","$moving",1,32,Regular,0.25]
          --convergence [5x5x1,1e-6,10]
          --shrink-factors 4x2x1
          --smoothing-sigmas 2x1x0vox          
        --transform SyN[0.1,3,0]
          --metric CC["$fixed","$moving",1,4]
          --convergence [5x3x1,1e-6,10]
          --shrink-factors 4x2x1
          --smoothing-sigmas 2x1x0vox
      )
      ;;
    high)
      cmd=(antsRegistration
        --verbose 1
        --dimensionality 3 
        --float 0
        --collapse-output-transforms 1
        --output ["${outprefix}",${outprefix}Warped.nii.gz,${outprefix}InwerseWarped.nii.gz]
        --interpolation Linear
        --use-histogram-matching 0
        --winsorize-image-intensities [0.005,0.995] 
        --initial-moving-transform ["$fixed","$moving",1]
        --transform Rigid[0.1]
          --metric MI["$fixed","$moving",1,32,Regular,0.25]
          --convergence [1000x500x250x100,1e-6,10]
          --shrink-factors 8x4x2x1
          --smoothing-sigmas 3x2x1x0vox
        --transform Affine[0.1]
          --metric MI["$fixed","$moving",1,32,Regular,0.25]
          --convergence [1000x500x250x100,1e-6,10]
          --shrink-factors 8x4x2x1
          --smoothing-sigmas 3x2x1x0vox          
        --transform SyN[0.1,3,0]
          --metric CC["$fixed","$moving",1,4]
          --convergence [100x70x50x20,1e-6,10]
          --shrink-factors 8x4x2x1
          --smoothing-sigmas 3x2x1x0vox
      )
      ;;
    old_v0)
      # Example old ANTS 3 style (ANTS 3.0 command)
      cmd=(ANTS 3
        -m PR["$fixed","$moving",1,2]  # old CC metric
        -i 10x50x50x10                     # iteration schedule
        -r Gauss[2,0]                    # smoothing for old ANTS
        -t SyN[0.3]                     # transform type
        -o "${outprefix}"                 # output prefix
      )
      ;;      
    old_v1)
      # Fast, minimal
      cmd=(ANTS 3
        -m PR["$fixed","$moving",1,2]  # old CC metric
        -i 5x5x0                     # iteration schedule
        -r Gauss[2,0]                    # smoothing for old ANTS
        -t SyN[0.1]                     # transform type
        -o "${outprefix}"                 # output prefix
      )
      ;;      
    old_v2)
      # Using CC instead of PR
      cmd=(ANTS 3
        -m CC["$fixed","$moving",1,4]  # old CC metric
        -i 100x100x50                     # iteration schedule
        -t SyN[0.3]                     # transform type
        -o "${outprefix}"                 # output prefix
      )
      ;;      
    *)
      echo "Usage: ants_reg {minimal|balanced|high|old_v0|old_v1} fixed.nii.gz moving.nii.gz outprefix pval"
      return 1
      ;;
  esac

  # Print nicely
  echo; echo ">>> Command to run:"
  printf '%s ' "${cmd[@]}"
  echo -e "\n"

  # Run
  "${cmd[@]}"
}

ants_apply() {
    local s_file="$1"
    local in_def="$2"
    local t_file="$3"
    local interp="$4"
    local out_warped="$5"
    
    if [ "$interp" == 'NearestNeighbor' ]; then
        cmd=(WarpImageMultiTransform 3
            ${s_file}
            ${out_warped}
            -R ${t_file}
            --use-NN
            ${in_def}
        )
    else
        cmd=(WarpImageMultiTransform 3
            ${s_file}
            ${out_warped}
            -R ${t_file}
            ${in_def}
        )
    fi

    # Print nicely
    echo; echo ">>> Command to run:"
    printf '%s ' "${cmd[@]}"
    echo -e "\n"

    # Run
    "${cmd[@]}"
}
      
ants_calc_jacdet() {
    local in_def="$1"
    local out_jac="$2"

    cmd=(CreateJacobianDeterminantImage 3 ${in_def} ${out_jac})

    # Print nicely
    echo; echo ">>> Command to run:"
    printf '%s ' "${cmd[@]}"
    echo -e "\n"

    # Run
    "${cmd[@]}"
}
  
ants_compose() {
    local in_warp="$1"
    local in_affine="$2"
    local t_file="$3"
    local out_def="$4"

    cmd=(ComposeMultiTransform 3 
         ${out_def}
         -R ${t_file}
         ${in_warp}
         ${in_affine}
    )

    # Print nicely
    echo; echo ">>> Command to run:"
    printf '%s ' "${cmd[@]}"
    echo -e "\n"

    # Run
    "${cmd[@]}"
}

##############################################
# Parse options
while getopts ":s:l:t:d:r:p:i:f:" opt; do
  case ${opt} in
    s ) s_file=$OPTARG ;;
    l ) l_file=$OPTARG ;;
    t ) t_file=$OPTARG ;;
    d ) out_dir=$OPTARG ;;
    r ) out_pref=$OPTARG ;;
    p ) p_reg=$OPTARG ;;
    i ) i_val=$OPTARG ;;
    f ) f_val=$OPTARG ;;
    \? ) echo "Invalid option: -$OPTARG" >&2; usage ;;
    : ) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

# Check for required arguments
if [ -z "$s_file" ] || [ -z "$l_file" ] || [ -z "$t_file" ] || [ -z "$out_dir" ] || [ -z "$out_pref" ]; then
  echo "Error: Missing required arguments." >&2
  usage
fi

# Create output directory if missing
mkdir -p "$out_dir"

# Create a temporary folder inside output dir
tmp_dir=$(mktemp -d "${out_dir}/tmp_XXXXXX")
mkdir -p "$tmp_dir"

# Print parsed arguments (for testing/debugging)
echo "Source image:        $s_file"
echo "Target image:        $t_file"
echo "Output directory:    $out_dir"
echo "Output prefix:       $out_pref"
echo "Label image:         $l_file"
echo "Registration mode (-p): $p_reg"
echo "Intensities (-i):    $i_val"
echo "Scaling factor (-f): $f_val"

# Check that input files exist
for f in "$s_file" "$t_file" "$l_file"; do
  if [ ! -f "$f" ]; then
    echo "Error: Input file does not exist: $f" >&2
    exit 1
  fi
done

# Calculate deformation
tmp_pref=${tmp_dir}/${out_pref}
out_pref=${out_dir}/${out_pref}
final_def=${out_pref}Def.nii.gz
if [ -e ${final_def} ]; then
    echo; echo "Deformation exists, skip ANTs registration!"
else
    # Calculate ANTS registration
    ants_reg ${p_reg} ${t_file} ${s_file} ${tmp_pref}

    # Compose def fields
    #     tmp_warp=${tmp_pref}Warp.nii.gz (suffixes for old ants command)
    #     tmp_affine=${tmp_pref}Affine.txt (suffixes for old ants command)
    tmp_warp=${tmp_pref}1Warp.nii.gz
    tmp_affine=${tmp_pref}0GenericAffine.mat
    ants_compose ${tmp_warp} ${tmp_affine} ${t_file} ${final_def}
fi

# Create jacobian
final_jac=${out_pref}Jacobian.nii.gz
if [ -e ${final_jac} ]; then
    echo; echo "Jacobian exists, skip calculation!"
else
    ants_calc_jacdet ${final_def} ${final_jac}
fi

# Warp image
interp='Linear'
final_warped=${out_pref}Warped.nii.gz
if [ -e ${final_warped} ]; then
    echo; echo "Warped image exists, skip calculation!"
else
    ants_apply ${s_file} ${final_def} ${t_file} ${interp} ${final_warped}
fi

# Create a mask image for each label
out_mask_pref=${tmp_pref}Label_
if [ -e ${out_mask_pref}List.csv ]; then
    echo; echo "Label masks exists, skip calculation!"
else
    cmd="python3 utils/util_create_label_masks.py ${l_file} ${out_mask_pref}"
    echo; echo "Running: $cmd"
    $cmd
fi

# Warp label masks
# interp='NearestNeighbor'
interp='Linear'
for label in $(cat ${out_mask_pref}List.csv); do
    label_in=${out_mask_pref}${label}.nii.gz
    label_out=${out_mask_pref}${label}_warped.nii.gz
    if [ -e ${label_out} ]; then
        echo; echo "Warped label exists, skip calculation!"
    else
        ants_apply ${label_in} ${final_def} ${t_file} ${interp} ${label_out}
    fi
done

# Calculate RAVENS
interp='Linear'
for label in $(cat ${out_mask_pref}List.csv); do
    label_in=${out_mask_pref}${label}_warped.nii.gz
    label_out=${out_pref}Label_${label}_RAVENS.nii.gz
    if [ -e ${label_out} ]; then
        echo; echo "Warped label exists, skip calculation!"
    else
        python3 utils/util_multiply_images.py ${label_in} ${final_jac} ${label_out}
    fi
done

