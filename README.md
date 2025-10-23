# Ravens Maps Calculation

**Ravens Maps Calculation** is a package designed to calculate RAVENS maps from T1w MRI scans

## Features
- Calculate RAVENS maps for different tissue types (segmentation labels)
- Calculate RAVENS maps using different methods (ANTs, SynthMorph)
- Post-processing steps to calculate statistical maps from RAVENS, and to warp outputs to initial subject space

## Installation

- You can install the package using:

```bash
pip install nichart-ravens [FIXME: dependencies ANTs 2.3.1 and Python (nibabel))
```

- Or use the docker container: 
    
    cbica/nichart_ravens:initialdemo (https://hub.docker.com/r/cbica/nichart_ravens)
  
## Application

- See the test scripts to apply a fast CSF abnormality map calculation on the test image:
 
```bash
cd ./test/scripts
```

```bash
./run_test_installed.sh
```

or

```bash
./run_test_docker.sh
```
  
  


