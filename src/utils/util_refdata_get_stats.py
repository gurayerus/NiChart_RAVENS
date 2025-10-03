#!/usr/bin/env python3
import os
import argparse
import numpy as np
import pandas as pd
import nibabel as nib

def calc_stats_npz(df, outdir, agediff=0.5, agestep=1, icv_corr=False, mean_icv=1450000, in_field='imgvec'):

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
                fname = row['fname']
                if os.path.exists(fname):
                    data = np.load(fname)[in_field]
                    if icv_corr:
                        data = data * (mean_icv / row['ICV'])
                    maps.append(data)

            if not maps:
                continue

            maps = np.array(maps)
            mean_map = maps.mean(axis=0).round().astype('uint16')
            std_map = maps.std(axis=0).round().astype('uint16')

            # Label
            label = f"Age{bin_center}_Sex{sex}"
            if icv_corr:
                label += "_ICV"

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
    df_out.to_csv(os.path.join(outdir, "list_stats.csv"), index=False)

def calc_stats_nifti(df, outdir, agediff=0.5, agestep=1, icv_corr=False, mean_icv=1450000, in_field='imgvec'):

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
                fname = row['fname']
                if os.path.exists(fname):
                    nii = nib.load(fname)
                    data = nii.get_fdata()
                    dshape = data.shape
                    data = data.flatten(0
                    if icv_corr:
                        data = data * (mean_icv / row['ICV'])
                    maps.append(data)

            if not maps:
                continue

            maps = np.array(maps)
            mean_map = maps.mean(axis=0)
            std_map = maps.std(axis=0)

            mean_map = mean_map.reshape(dshape)
            std_map = std_map.reshape(dshape)

            # Label
            label = f"Age{bin_center}_Sex{sex}"
            if icv_corr:
                label += "_ICV"

            # Save outputs
            out_file_mean = os.path.join(outdir, f"mean_{label}.npz")    
            m_img = nib.Nifti1Image(mean_map, affine=nii.affine, header=nii.header)
            nib.save(m_img, out_file_mean)

            out_file_std = os.path.join(outdir, f"std_{label}.npz")    
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
    df_out.to_csv(os.path.join(outdir, "list_stats.csv"), index=False)

    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate mean/std maps for age-sex bins.")
    parser.add_argument("list_demog", help="CSV with MRID, Age, Sex, ICV")
    parser.add_argument("list_files", help="List with input file names")
    parser.add_argument("outdir", help="Output directory")
    parser.add_argument("--agediff", type=float, default=0.5, help="Half-width of age bin")
    parser.add_argument("--agestep", type=float, default=1, help="Step size for sliding bins")
    parser.add_argument("--corr_icv", action="store_true", help="Enable ICV correction")
    parser.add_argument("--mean_icv", type=float, default=1450000, help="Mean ICV to use for correction")

    args = parser.parse_args()

    os.makedirs(outdir, exist_ok=True)

    # Load data
    df_demog = pd.read_csv(list_demog)
    df_files = pd.read_csv(list_files)

    df = df_demog.merge(df_files, on='MRID')
    ftmp = df.fnames.tolist()[0]
    
    if ftmp.ends_with('.npz'):
        calc_stats_npz(df, args.outdir, args.agediff, args.agestep, args.corr_icv, args.mean_icv)
        
    elif ftmp.ends_with('.nii.gz'):
        calc_stats_nifti(df, args.outdir, args.agediff, args.agestep, args.corr_icv, args.mean_icv)
        
