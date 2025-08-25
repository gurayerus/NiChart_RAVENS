# Ravens Maps Calculation

**Ravens Maps Calculation** is a package designed to calculate RAVENS maps from T1w MRI scans

## Features
- Calculate RAVENS maps for different tissue types (segmentation labels)
- Calculate RAVENS maps using different methods (ANTs, SynthMorph)
- Post-processing steps to calculate statistical maps from RAVENS, and to warp outputs to initial subject space

## Installation
You can install the package using:

```bash
pip install nichart-ravens [FIXME: dependencies ANTs 2.3.1 and Python (nibabel))
```

## Quick Test
- See:
    test/scripts/testrun_ravens_ants.sh
  to apply a fast RAVENS calculation on two scans


