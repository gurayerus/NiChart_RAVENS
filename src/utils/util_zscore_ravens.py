#!/usr/bin/env python3
import os
import numpy as np
import pandas as pd
import argparse
import nibabel as nib

def util_zscore_ravens_npz(inmap, age, sex, ref_dir, out_file):
    """
    Compute z-scores for an encoded map using reference mean/std maps.
    """
    # Load encoded input from npz file
    in_data = np.load(inmap)
    if "imgvec" not in in_data:
        raise KeyError(f"{inmap} must contain key 'imgvec'")
    x = in_data["imgvec"].astype(float)
        
    # Read stats list
    stats_file = os.path.join(ref_dir, "list_stats.csv")
    stats_df = pd.read_csv(stats_file)

    # filter by sex
    df_sex = stats_df[stats_df["Sex"] == sex]
    if df_sex.empty:
        raise ValueError(f"No reference found for sex={sex}")

    # Find closest age bin
    df_sex = df_sex.copy()  # avoid SettingWithCopyWarning
    df_sex["AgeDiff"] = (df_sex["Age"] - age).abs()
    ref_row = df_sex.loc[df_sex["AgeDiff"].idxmin()]

    ref_file = ref_row["npz"]
    if not os.path.isabs(ref_file):
        ref_file = os.path.join(ref_dir, ref_file)
    ref_data = np.load(ref_file)
    mean_map = ref_data["mean"].astype(float)
    std_map = ref_data["std"].astype(float)

    # Compute z-scores
    zmap = (x - mean_map) / (std_map + 1e-8)
    zmap[x==0] = 0
    zmap[mean_map==0] = 0
    zmap[std_map==0] = 0

    # Save
    np.savez_compressed(
        out_file,
        x=x,
        mean_map=mean_map,
        std_map=std_map,
        zmap=zmap,
        ref_file=ref_file,
        age=age,
        sex=sex,
        mrid=os.path.basename(inmap).split("_")[0],
    )
    print(f"Saved z-score map to {out_file}")

def util_zscore_ravens_nifti(inmap, age, sex, ref_dir, out_file):
    """
    Compute z-scores for a nifti image using reference mean/std maps.
    """
    # Load input from nii.gz file
    in_nii = nib.load(inmap)
    in_data = in_nii.get_fdata()
    in_shape = in_data.shape
    x = in_data.flatten()

    # Read stats list
    stats_file = os.path.join(ref_dir, "list_stats.csv")
    stats_df = pd.read_csv(stats_file)

    # filter by sex
    df_sex = stats_df[stats_df["Sex"] == sex]
    if df_sex.empty:
        raise ValueError(f"No reference found for sex={sex}")

    # Find closest age bin
    df_sex = df_sex.copy()  # avoid SettingWithCopyWarning
    df_sex["AgeDiff"] = (df_sex["Age"] - age).abs()
    ref_row = df_sex.loc[df_sex["AgeDiff"].idxmin()]

    mean_file = ref_row["mean"]
    if not os.path.isabs(mean_file):
        mean_file = os.path.join(ref_dir, mean_file)
    mean_nii = nib.load(mean_file)
    mean_map = mean_nii.get_fdata().flatten()
        
    std_file = ref_row["std"]
    if not os.path.isabs(std_file):
        std_file = os.path.join(ref_dir, std_file)
    std_nii = nib.load(std_file)
    std_map = std_nii.get_fdata().flatten()
            
    # Compute z-scores
    zmap = (x - mean_map) / (std_map + 1e-8)
    zmap[x==0] = 0
    zmap[mean_map==0] = 0
    zmap[std_map==0] = 0

    # Save
    z_img = nib.Nifti1Image(zmap, affine=in_nii.affine, header=in_nii.header)
    nib.save(z_img, out_file)
    print(f"Saved z-score map to {out_file}")

def main():
    parser = argparse.ArgumentParser(description="Compute z-scores for encoded RAVENS maps.")
    parser.add_argument("--inmap", required=True, help="Input encoded .npz file")
    parser.add_argument("--age", type=float, required=True, help="Subject age")
    parser.add_argument("--sex", required=True, choices=["M", "F"], help="Subject sex")
    parser.add_argument("--ref_dir", required=True, help="Reference directory containing list_stats.csv")
    parser.add_argument("--out_file", required=True, help="Output .npz z-score file")

    args = parser.parse_args()
    
    if args.inmap.ends_with('.npz'):
        util_zscore_ravens_npz(args.inmap, args.age, args.sex, args.ref_dir, args.out_file)
    elif args.inmap.ends_with('.nii.gz'):
        util_zscore_ravens_nifti(args.inmap, args.age, args.sex, args.ref_dir, args.out_file)


if __name__ == "__main__":
    main()
