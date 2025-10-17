import logging
from typing import Optional
from zipfile import Path

from filters.Custom_Filter import CustomFilter
from utils.file_utils import get_data_files
from filters.Area_Threshold_Filter import AreaThresholdFilter
from filters.False_Alarm_Filter import FalseAlarmFilter
from filters.Filter_Pipeline import FilterPipeline
from filters.Missing_Coordinates_Filter import MissingCoordinatesFilter
from utils.file_utils import load_csv


def process_file(filepath: Path, pipeline: FilterPipeline, output_dir: Optional[Path] = None) -> None:
    """Process a single file through the filter pipeline"""
    logging.info(f"Processing {filepath}")
    
    # Load the data
    df = load_csv(filepath)
    original_count = len(df)
    logging.info(f"Original record count: {original_count}")
    
    # Apply filters
    filtered_df = pipeline.apply(df)
    
    # Determine where to save
    if output_dir:
        output_path = output_dir / filepath.name
        output_dir.mkdir(parents=True, exist_ok=True)
    else:
        # Overwrite the original file
        output_path = filepath
    
    # Save the filtered data
    filtered_df.to_csv(output_path, sep='|', index=False)
    logging.info(f"Saved filtered data with {len(filtered_df)} records to {output_path}")


def run(data_dir: str = "data", output_dir: Optional[str] = None, 
        pattern: str = "*.csv", recursive: bool = False) -> None:
    """Run the filtering pipeline on all CSV files in the data directory"""
    output_path = Path(output_dir) if output_dir else None
    
    # Build the filter pipeline
    # ADD FILTERS HERE
    pipeline = FilterPipeline()
    pipeline.add_filter(FalseAlarmFilter())
    pipeline.add_filter(MissingCoordinatesFilter())
    pipeline.add_filter(AreaThresholdFilter(min_area=0.5))  # remove areas < 0.5 ha
    
    # Example of adding a custom filters
    pipeline.add_filter(CustomFilter(
        lambda df: df[df["TIPO"] != "QUEIMADA"],
        "Remove records of type QUEIMADA"
        
    ))
    
    pipeline.add_filter(CustomFilter(
        lambda df: df[df["TIPO"] != "Agrícola"],
        "Remove records of type Agrícola"
    ))

    # Find all CSV files
    files = get_data_files(data_dir, pattern=pattern, recursive=recursive)
    if not files:
        logging.error("No CSV files found.")
        return
    
    logging.info(f"Found {len(files)} files to process")
    
    # Process each file
    for file_path in files:
        process_file(file_path, pipeline, output_path)


if __name__ == "__main__":
    run(
        data_dir="data",       # Source directory 
        output_dir=None,       # Set to None to overwrite original files, or specify a different directory
        pattern="*.csv",       # File pattern to match
        recursive=False        # Whether to search subdirectories
    )