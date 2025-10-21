#!/usr/bin/env python3
import os
import argparse
import numpy as np
import pandas as pd
import nibabel as nib
from pathlib import Path

def calc_stats_npz(roilabel, df, outdir, agediff=0.5, agestep=1, in_field='imgvec'):

    # Age range
    min_age, max_age = df["Age"].min(), df["Age"].max()
    offset = (max_age - min_age) % agestep / 2
    bin_centers = np.arange(min_age + offset, max_age, agestep).round(1)

    records = []  # metadata for output df
    for bin_center in bin_centers:
        bin_start = bin_center - agediff
        bin_end = bin_center + agediff
        for sex in df["Sex"].unique():
            sub_df = df[(df["Age"] >= bin_start) & (df["Age"] < bin_end) & (df["Sex"] == sex)]
            if sub_df.empty:
                continue

            maps = []
            for _, row in sub_df.iterrows():
                fname = row['FileName']
                if os.path.exists(fname):
                    data = np.load(fname)[in_field]
                    maps.append(data)

            if not maps:
                continue

            maps = np.array(maps)
            mean_map = maps.mean(axis=0).round().astype('uint16')
            std_map = maps.std(axis=0).round().astype('uint16')

            # Label
            label = f"Label{roilabel}_Age{bin_center}_Sex{sex}"

            # Save outputs
            out_file = os.path.join(outdir, f"stats_{label}.npz")

            ids=sub_df.MRID.to_list()
            np.savez_compressed(
                out_file,
                mean=mean_map,
                std=std_map,
                ids=ids
            )
            print(f"Saved stats for Age={bin_center}, Sex={sex}, N={len(ids)}")
    
            # add record
            records.append({
                "Age": bin_center,
                "Sex": sex,
                "npz": out_file
            })

    # build DataFrame
    df_out = pd.DataFrame(records)
    df_out.to_csv(os.path.join(outdir, f"list_{roilabel}.csv"), index=False)

def calc_stats_nifti(roilabel, df, outdir, agediff=0.5, agestep=1, in_field='imgvec'):

    # Age range
    min_age, max_age = df["Age"].min(), df["Age"].max()
    offset = (max_age - min_age) % agestep / 2
    bin_centers = np.arange(min_age + offset, max_age, agestep).round(1)

    records = []  # metadata for output df
    for bin_center in bin_centers:
        bin_start = bin_center - agediff
        bin_end = bin_center + agediff
        for sex in df["Sex"].unique():

            # Check out files
            label = f"Label{roilabel}_Age{bin_center}_Sex{sex}"
            out_file_mean = os.path.join(outdir, f"mean_{label}.nii.gz")    
            out_file_std = os.path.join(outdir, f"std_{label}.nii.gz")    

            if os.path.exists(out_file_mean) and os.path.exists(out_file_std):
                print(f'Out file exists, skip for: {bin_center} {sex}')
                continue
            
            sub_df = df[(df["Age"] >= bin_start) & (df["Age"] < bin_end) & (df["Sex"] == sex)]
            if sub_df.empty:
                continue

            maps = []
            for _, row in sub_df.iterrows():
                fname = row['FileName']
                if os.path.exists(fname):
                    nii = nib.load(fname)
                    data = nii.get_fdata()
                    dshape = data.shape
                    data = data.flatten()
                    maps.append(data)

            if not maps:
                continue

            maps = np.array(maps)
            mean_map = maps.mean(axis=0)
            std_map = maps.std(axis=0)

            mean_map = mean_map.reshape(dshape)
            std_map = std_map.reshape(dshape)


            # Save outputs
            ids=sub_df.MRID.to_list()

            m_img = nib.Nifti1Image(mean_map, affine=nii.affine, header=nii.header)
            nib.save(m_img, out_file_mean)

            s_img = nib.Nifti1Image(std_map, affine=nii.affine, header=nii.header)
            nib.save(s_img, out_file_std)

            print(f"Saved stats for Age={bin_center}, Sex={sex}, N={len(ids)}")
    
            # add record
            records.append({
                "Age": bin_center,
                "Sex": sex,
                "mean": out_file_mean,
                "std": out_file_std
            })

    # build DataFrame
    df_out = pd.DataFrame(records)
    df_out.to_csv(os.path.join(outdir, f"list_{roilabel}.csv"), index=False)

    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate mean/std maps for age-sex bins.")
    parser.add_argument("label", help="Label for input images")
    parser.add_argument("list_demog", help="CSV with MRID, Age, Sex")
    parser.add_argument("list_files", help="List with input file names")
    parser.add_argument("outdir", help="Output directory")
    parser.add_argument("--agediff", type=float, default=0.5, help="Half-width of age bin")
    parser.add_argument("--agestep", type=float, default=1, help="Step size for sliding bins")

    args = parser.parse_args()

    list_demog = Path(args.list_demog)
    list_files = Path(args.list_files)
    outdir = Path(args.outdir)

    os.makedirs(outdir, exist_ok=True)

    # Load data
    df_demog = pd.read_csv(list_demog)
    df_files = pd.read_csv(list_files)

    df = df_demog.merge(df_files, on='MRID')
    
    ftmp = df.FileName.tolist()[0]
    
    if ftmp.endswith('.npz'):
        calc_stats_npz(args.label, df, args.outdir, args.agediff, args.agestep)
        
    elif ftmp.endswith('.nii.gz'):
        calc_stats_nifti(args.label, df, args.outdir, args.agediff, args.agestep)
        
