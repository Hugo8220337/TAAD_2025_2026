import os
import glob


def get_data_files(directory: str,
                   pattern: str = "*",
                   recursive: bool = False):
    """
    Return a sorted list of file paths (strings) for files in `directory`.
    - pattern: glob pattern (e.g., '*.csv' or '*')
    - recursive: if True, searches subfolders using '**'
    Returns an empty list if `directory` does not exist or is not a directory.
    """
    if not os.path.isdir(directory):
        return []

    if recursive:
        glob_pattern = os.path.join(directory, "**", pattern)
        files = glob.glob(glob_pattern, recursive=True)
    else:
        glob_pattern = os.path.join(directory, pattern)
        files = glob.glob(glob_pattern)

    files = [f for f in files if os.path.isfile(f)]
    return sorted(files, key=lambda p: os.path.basename(p))