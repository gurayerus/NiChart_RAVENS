#!/usr/bin/env python3
import os
import numpy as np
import pandas as pd
import argparse

def util_zscore_ravens(inmap, age, sex, ref_dir, out_file):
    """
    Compute z-scores for an encoded map using reference mean/std maps.
    """
    # load input
    in_data = np.load(inmap)
    if "imgvec" not in in_data:
        raise KeyError(f"{inmap} must contain key 'imgvec'")
    x = in_data["imgvec"]

    # read stats list
    stats_file = os.path.join(ref_dir, "list_stats.csv")
    stats_df = pd.read_csv(stats_file)

    # filter by sex
    df_sex = stats_df[stats_df["Sex"] == sex]
    if df_sex.empty:
        raise ValueError(f"No reference found for sex={sex}")

    # find closest age bin
    df_sex = df_sex.copy()  # avoid SettingWithCopyWarning
    df_sex["AgeDiff"] = (df_sex["Age"] - age).abs()
    ref_row = df_sex.loc[df_sex["AgeDiff"].idxmin()]

    ref_file = ref_row["Filename"]
    if not os.path.isabs(ref_file):
        ref_file = os.path.join(ref_dir, ref_file)

    # load reference maps
    ref_data = np.load(ref_file)
    mean_map = ref_data["mean"]
    std_map = ref_data["std"]

    # compute z-scores
    zmap = (x - mean_map) / (std_map + 1e-8)

    # save
    np.savez_compressed(
        out_file,
        zmap=zmap,
        ref_file=ref_file,
        age=age,
        sex=sex,
        mrid=os.path.basename(inmap).split("_")[0]
    )
    print(f"Saved z-score map to {out_file}")

def main():
    parser = argparse.ArgumentParser(description="Compute z-scores for encoded RAVENS maps.")
    parser.add_argument("--inmap", required=True, help="Input encoded .npz file")
    parser.add_argument("--age", type=float, required=True, help="Subject age")
    parser.add_argument("--sex", required=True, choices=["M", "F"], help="Subject sex")
    parser.add_argument("--ref_dir", required=True, help="Reference directory containing list_stats.csv")
    parser.add_argument("--out_file", required=True, help="Output .npz z-score file")

    args = parser.parse_args()
    util_zscore_ravens(args.inmap, args.age, args.sex, args.ref_dir, args.out_file)

if __name__ == "__main__":
    main()
