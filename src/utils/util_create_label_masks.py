#!/usr/bin/env python3
import nibabel as nib
import numpy as np
import sys

def util_create_label_masks(seg_file, out_prefix, label_list=None):
    """
    Create a binary mask for each label
    
    Args:
        seg_file (str): Path to segmentation image
        out_prefix (str): Output prefix
        label_list (list of int, optional): Labels to process; if None, process all labels except 0
    """
    # Load images
    seg_nii = nib.load(seg_file)

    seg_data = seg_nii.get_fdata()

    # Determine labels to process
    if label_list is None:
        labels = np.unique(seg_data)
        labels = labels[labels != 0]
    else:
        labels = [lbl for lbl in label_list if lbl in np.unique(seg_data)]
        if len(labels) == 0:
            print("No specified labels found in segmentation.")
            return

    for label in labels:
        out_data = (seg_data == label).astype(int)

        out_nii = nib.Nifti1Image(out_data, affine=seg_nii.affine, header=seg_nii.header)
        out_fname = f"{out_prefix}{int(label)}.nii.gz"
        nib.save(out_nii, out_fname)
        print(f"Saved label {int(label)} to {out_fname}")
        
    # Save a list of labels to file
    out_list = f'{out_prefix}List.csv'
    np.savetxt(out_list, labels, fmt="%d")
    print(f"Saved list of labels to {out_list}")

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Create binary masks for labels")
    parser.add_argument("seg_file", help="Segmentation image (NIfTI)")
    parser.add_argument("out_prefix", help="Output prefix")
    parser.add_argument("--labels", nargs="+", type=int, help="List of labels to process (default: all except 0)")

    args = parser.parse_args()

    util_create_label_masks(args.seg_file, args.out_prefix, args.labels)
