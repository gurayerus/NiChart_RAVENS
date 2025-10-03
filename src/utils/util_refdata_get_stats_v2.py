#!/usr/bin/env python3
import os
import argparse
import numpy as np
import pandas as pd

def calc_stats(list_file, indir, outdir, agediff=0.5, agestep=1,
               icv_corr=False, mean_icv=1450000,
               in_suff='_encoded.npz', in_field='imgvec'
):
    # Load subject table
    df = pd.read_csv(list_file, sep=None, engine="python")  # auto-detect delimiter
    os.makedirs(outdir, exist_ok=True)

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
                fname = os.path.join(indir, f"{row['MRID']}{in_suff}")
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
                "Filename": out_file
            })

    # build DataFrame
    df_out = pd.DataFrame(records)
    df_out.to_csv(os.path.join(outdir, "list_stats.csv"), index=False)

    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate mean/std maps for age-sex bins.")
    parser.add_argument("list_file", help="CSV with MRID, Age, Sex, ICV")
    parser.add_argument("indir", help="Directory with [MRID]_encoded.npz files")
    parser.add_argument("outdir", help="Output directory")
    parser.add_argument("--agediff", type=float, default=0.5, help="Half-width of age bin")
    parser.add_argument("--agestep", type=float, default=1, help="Step size for sliding bins")
    parser.add_argument("--corr_icv", action="store_true", help="Enable ICV correction")
    parser.add_argument("--mean_icv", type=float, default=1450000, help="Mean ICV to use for correction")

    args = parser.parse_args()
    calc_stats(
        args.list_file, args.indir, args.outdir, args.agediff,
        args.agestep, args.corr_icv, args.mean_icv
    )
