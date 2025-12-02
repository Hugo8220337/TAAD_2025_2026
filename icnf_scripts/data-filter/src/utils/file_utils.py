def load_csv(filepath):
    import pandas as pd
    return pd.read_csv(filepath, sep='|')

def get_data_files(data_dir, pattern='*.csv', recursive=False):
    from pathlib import Path
    import glob
    
    path = Path(data_dir)
    if recursive:
        return list(path.rglob(pattern))
    else:
        return list(path.glob(pattern))