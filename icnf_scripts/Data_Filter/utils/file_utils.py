import pandas as pd
from pathlib import Path
from typing import List

def get_data_files(directory: str,
                   pattern: str = "*",
                   recursive: bool = False) -> List[Path]:
    """
    Return a sorted list of Path objects for files in `directory`.
    - pattern: glob pattern (e.g., '*.csv' or '*')
    - recursive: if True, uses rglob to search subfolders
    """
    data_dir = Path(directory)
    if not data_dir.exists() or not data_dir.is_dir():
        return []  # or raise FileNotFoundError(f"{directory} not found")

    if recursive:
        files = list(data_dir.rglob(pattern))
    else:
        files = list(data_dir.glob(pattern))

    files = [p for p in files if p.is_file()]
    return sorted(files, key=lambda p: p.name)  # or key=lambda p: p.stat().st_mtime

def load_csv(filepath: str) -> pd.DataFrame:
    """Load a CSV file with appropriate settings"""
    try:
        # Try UTF-8 first
        return pd.read_csv(
            filepath, 
            sep='|', 
            dtype=str,
            na_values=["", "NA", "NULL", "-"],
            low_memory=False
        )
    except UnicodeDecodeError:
        # Fall back to Latin-1
        return pd.read_csv(
            filepath, 
            sep='|', 
            dtype=str,
            encoding='latin1',
            na_values=["", "NA", "NULL", "-"],
            low_memory=False
        )