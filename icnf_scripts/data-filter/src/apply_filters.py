import logging
import argparse
from typing import Optional
from pathlib import Path

from filters.Not_Incendio_Filter import NotIncendioFilter
from filters.Queimada_Filter import QueimadaFilter
from filters.Custom_Filter import CustomFilter
from utils.file_utils import get_data_files
from filters.Area_Threshold_Filter import AreaThresholdFilter
from filters.False_Alarm_Filter import FalseAlarmFilter
from filters.Filter_Pipeline import FilterPipeline
from filters.Missing_Coordinates_Filter import MissingCoordinatesFilter
from utils.file_utils import load_csv


def process_file(filepath: Path, pipeline: FilterPipeline, output_dir: Optional[Path] = None) -> None:
    logging.info(f"Processing {filepath}")
    
    df = load_csv(filepath)
    original_count = len(df)
    logging.info(f"Original record count: {original_count}")
    
    filtered_df = pipeline.apply(df)
    
    if output_dir:
        output_path = output_dir / filepath.name
        output_dir.mkdir(parents=True, exist_ok=True)
    else:
        output_path = filepath
    
    filtered_df.to_csv(output_path, sep='|', index=False)
    logging.info(f"Saved filtered data with {len(filtered_df)} records to {output_path}")


def run(data_dir: str = "data", output_dir: Optional[str] = None, 
        pattern: str = "*.csv", recursive: bool = False) -> None:
    output_path = Path(output_dir) if output_dir else None
    
    pipeline = FilterPipeline()
    pipeline.add_filter(FalseAlarmFilter())
    pipeline.add_filter(MissingCoordinatesFilter())
    pipeline.add_filter(AreaThresholdFilter(min_area=5.0))
    pipeline.add_filter(QueimadaFilter()) 
    pipeline.add_filter(NotIncendioFilter())
    
    pipeline.add_filter(CustomFilter(
        lambda df: df.dropna(subset=["DHINICIO", "DHFIM"]),
        "Remove entries with missing start/end times"
    ))

    files = get_data_files(data_dir, pattern=pattern, recursive=recursive)
    if not files:
        logging.error("No CSV files found.")
        return
    
    logging.info(f"Found {len(files)} files to process")
    
    for file_path in files:
        process_file(file_path, pipeline, output_path)


def main():
    parser = argparse.ArgumentParser(description='Filter CSV files containing fire detection data')
    
    parser.add_argument(
        '--data_dir', '-i',
        type=str,
        default='./data',
        help='Input directory containing CSV files (default: data)'
    )
    
    parser.add_argument(
        '--output_dir', '-o',
        type=str,
        default=None,
        help='Output directory for filtered files (default: overwrite original files)'
    )
    
    parser.add_argument(
        '--pattern', '-p',
        type=str,
        default='*.csv',
        help='File pattern to match (default: *.csv)'
    )
    
    parser.add_argument(
        '--recursive', '-r',
        action='store_true',
        help='Search subdirectories recursively'
    )
    
    args = parser.parse_args()
    
    logging.basicConfig(
        level=getattr(logging, "INFO"),
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    
    run(
        data_dir=args.data_dir,
        output_dir=args.output_dir,
        pattern=args.pattern,
        recursive=args.recursive
    )


if __name__ == "__main__":
    main()