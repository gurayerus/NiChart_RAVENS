###########################################################################
# Script for creating a list of matching subjects based on age, sex and DX
#
# Select younf subjects in UKBB_TBI_2022_FromLiz
import numpy as np
import pandas as pd
import os
import sys

MAX_AGE = 50
SEX = 'M'

# Input args
refCsv = '../Data/UKBB_TBI_2022_FromLiz.csv'
outCsv = '../Protocols/MatchingLists/list_ref.csv'

# Read ref data
dfRef = pd.read_csv(refCsv)

# Filter data
dfRef = dfRef[dfRef.TBI_2022 == 0]
dfRef = dfRef[dfRef.AGE <= MAX_AGE]
dfRef = dfRef[dfRef.Sex == SEX]

# Write list
dfRef.to_csv(outCsv, index=False)
