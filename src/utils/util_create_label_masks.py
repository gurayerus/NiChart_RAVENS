#!/usr/bin/env python3
import nibabel as nib
import numpy as np
import sys
import pandas as pd

def read_derived_rois(fname):
    df = pd.read_csv(fname, header=None, dtype=str)
    roi_dict = {}
    for _, row in df.iterrows():
        key = row[0]
        # Drop NaN, convert to int
        values = row[1:].dropna().astype(int).tolist()
        roi_dict[key] = values
        
    return roi_dict

def util_create_label_masks(label_file, out_prefix, label_list=None):
    """
    Create a binary mask for each label
    
    Args:
        label_file (str): Path to segmentation image
        out_prefix (str): Output prefix
        label_list (list of int, optional): Labels to process; if None, process all labels except 0
    """
    # Load images
    seg_nii = nib.load(label_file)

    seg_data = seg_nii.get_fdata()

    # Determine roi labels
    if label_list == 'auto':              # Read all non-zero labels in image
        labels = np.unique(seg_data).astype(int)
        labels = labels[labels != 0]
        roi_dict = {str(x): x for x in labels}

    else:
        try:
            roi_dict = read_derived_rois(label_list)    # Read labels from a dictionary
        except:
            roi_dict = {x.strip(): int(x) for x in label_list.split(",")} # Read from comma-separated list
        
    if len(roi_dict) == 0:
        print("No specified labels found in segmentation.")
        return

    for roi, values in roi_dict.items():
        out_data = np.zeros_like(seg_data, dtype=np.uint8)
        out_data[np.isin(seg_data, values)] = 1
    
        out_nii = nib.Nifti1Image(out_data, affine=seg_nii.affine, header=seg_nii.header)
        out_fname = f"{out_prefix}{roi}.nii.gz"
        nib.save(out_nii, out_fname)
        print(f"Saved label {roi} to {out_fname}")
        
    # Save list of labels to file
    out_list = f'{out_prefix}List.csv'
    with open(out_list, "w") as f:
        for key in roi_dict.keys():
            f.write(f"{key}\n")    
    #np.savetxt(out_list, roi_dict.keys())
    print(f"Saved list of labels to {out_list}")

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Create binary masks for labels")
    parser.add_argument("label_file", help="Segmentation image (NIfTI)")
    parser.add_argument("out_prefix", help="Output prefix")
    parser.add_argument("--labels", default="auto", help="List of labels to process (default: all except 0)")

    args = parser.parse_args()

    util_create_label_masks(args.label_file, args.out_prefix, args.labels)
