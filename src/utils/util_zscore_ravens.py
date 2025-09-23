import argparse
import pandas as pd
import numpy as np
import nibabel as nib
import os

def calc_zmap(in_list, flag_corr_icv, out_file, thresh_mask=50):
    """
    Compute a voxelwise z-score map for a target image against reference images.

    Parameters
    ----------
    in_list : str
        Path to CSV file with columns [MRID, FileName, ICV].
        First row = target, remaining rows = references.
    flag_corr_icv : bool
        If True, correct images for ICV by scaling with mean reference ICV.
    out_file : str
        Path to output z-map NIfTI file.
    thresh_mask : float, optional
        Values below this threshold will be set to zero (default: 50).
    """
    # Load CSV
    df = pd.read_csv(in_list)
    if df.shape[0] < 2:
        raise ValueError("CSV must contain at least one target and one reference image.")

    # Separate target and references
    target_row = df.iloc[0]
    ref_rows = df.iloc[1:]

    # Load images
    D1='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS/tmp/out/test'
    S1='_Label_1_RAVENS.nii.gz'
    
    D2='/cbica/home/erusg/GitHub/gurayerus/NiChart_RAVENS/tmp/ref/CSF-RAVENS'
    S2='_T1_LPS_dlicv_seg_ants-0.3_RAVENS_1.nii.gz'
    
    target_img = nib.load(D1 + '/' + target_row["MRID"] + '/' + target_row["MRID"] + S1)
    target_data = target_img.get_fdata()

    ref_imgs = [nib.load(D2 + '/' + f + '/' + f + S2) for f in ref_rows["MRID"]]
    ref_data = np.stack([img.get_fdata() for img in ref_imgs], axis=-1)

    #target_img = nib.load(target_row["FileName"])
    #target_data = target_img.get_fdata()

    #ref_imgs = [nib.load(f) for f in ref_rows["FileName"]]
    #ref_data = np.stack([img.get_fdata() for img in ref_imgs], axis=-1)

    # Apply ICV correction if requested
    if flag_corr_icv:
        mean_ref_icv = ref_rows["ICV"].mean()
        # Correct target
        target_data = (target_data / target_row["ICV"]) * mean_ref_icv
        # Correct references
        ref_data = np.stack(
            [(ref_data[..., i] / ref_rows.iloc[i]["ICV"]) * mean_ref_icv
             for i in range(ref_data.shape[-1])],
            axis=-1
        )

    # Compute mean and std from references
    ref_mean = np.mean(ref_data, axis=-1)
    ref_std = np.std(ref_data, axis=-1, ddof=1)

    # Avoid division by zero
    ref_std[ref_std == 0] = np.nan

    # Compute z-map
    z_map = (target_data - ref_mean) / ref_std

    # Apply mask threshold
    z_map[target_data < thresh_mask] = 0

    # Ensure parent directory exists
    os.makedirs(os.path.dirname(out_file), exist_ok=True)    

    # Save output
    z_img = nib.Nifti1Image(z_map, affine=target_img.affine, header=target_img.header)
    nib.save(z_img, out_file)

    print(f"✅ Z-map saved to {out_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compute voxelwise z-score maps from MRI images")
    parser.add_argument("--in_csv", required=True, help="CSV file with columns [MRID, FileName, ICV] (first row = target)")
    parser.add_argument("--out_file", required=True, help="Output NIfTI file path for z-map")
    parser.add_argument("--icv_corr", action="store_true", help="Enable ICV correction")
    parser.add_argument("--thresh_mask", type=float, default=50, help="Threshold mask (default: 50)")
    args = parser.parse_args()

    calc_zmap(args.in_csv, args.icv_corr, args.out_file, args.thresh_mask)
    
    
