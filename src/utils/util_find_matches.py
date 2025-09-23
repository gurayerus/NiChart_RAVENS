import pandas as pd
import os
import argparse

def find_matches(
    query_csv, query_mrid, ref_csv, out_file, age_tolerance=0.5, match_sex=True
):
    """
    Find matching subjects between query and target datasets.

    Parameters
    ----------
    query_csv : str
        Path to query CSV (must contain MRID, age, sex).
    ref_csv : str
        Path to reference CSV (must contain MRID, age, sex).
    query_mrid : str
        MRID in query file to use as the reference subject.
    age_tolerance : float
        Allowed absolute difference in age for a match.
    match_sex : bool
        Whether to require the same sex.

    Returns
    -------
    pandas.DataFrame
        Matching rows from target dataset
    """
    # Load both datasets
    df_query = pd.read_csv(query_csv)
    df_ref = pd.read_csv(ref_csv)

    # Get the reference row
    sel_row = df_query[df_query["MRID"] == query_mrid]
    if sel_row.empty:
        print(df_query)
        raise ValueError(f"MRID {query_mrid} not found in query file.")

    sel_row = sel_row.iloc[0]  # get as Series
    sel_age = sel_row["Age"]
    sel_sex = sel_row["Sex"]

    # Apply matching rules
    matches = df_ref[abs(df_ref["Age"] - sel_age) <= age_tolerance]

    if match_sex:
        matches = matches[matches["Sex"] == sel_sex]

    # Create parent directories if needed
    os.makedirs(os.path.dirname(out_file) or ".", exist_ok=True)

    # Save matches to CSV
    matches.to_csv(out_file, index=False)

    return out_file


    # Save CSV
    matches.to_csv(out_file, index=False)
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Find matches between query and reference datasets.")
    parser.add_argument("--query", required=True, help="Path to query CSV file")
    parser.add_argument("--mrid", required=True, help="Selected MRID in query file")
    parser.add_argument("--ref", required=True, help="Path to reference CSV file")
    parser.add_argument("--out", required=True, help="Output CSV file path")
    parser.add_argument("--age_tol", type=float, default=0.5, help="Age tolerance for matching (default: 0.5)")
    parser.add_argument("--match_sex", action="store_true", help="Require same sex for matching")

    args = parser.parse_args()

    out_file = find_matches(
        args.query,
        args.mrid,
        args.ref,
        age_tolerance=args.age_tol,
        match_sex=args.match_sex,
        out_file=args.out,
    )

    print(f"✅ Matching results saved to: {out_file}")
