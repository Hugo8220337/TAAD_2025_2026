import logging
import pandas as pd
import os
from pathlib import Path
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Callable, Optional

from filters.Abstract_Filter import Filter

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

class MissingCoordinatesFilter(Filter):
    """Filter that removes records with missing coordinates"""
    
    def apply(self, df: pd.DataFrame) -> pd.DataFrame:
        if "LAT" in df.columns and "LON" in df.columns:
            # Convert to numeric to handle different formats
            df["LAT_NUMERIC"] = pd.to_numeric(
                df["LAT"].astype(str).str.replace(',', '.'), 
                errors='coerce'
            )
            df["LON_NUMERIC"] = pd.to_numeric(
                df["LON"].astype(str).str.replace(',', '.'), 
                errors='coerce'
            )
            # Check for NaN or 0,0 coordinates
            missing_coords = df["LAT_NUMERIC"].isna() | df["LON_NUMERIC"].isna() | \
                            ((df["LAT_NUMERIC"] == 0) & (df["LON_NUMERIC"] == 0))
            
            removed_count = sum(missing_coords)
            if removed_count > 0:
                logging.info(f"Removing {removed_count} records with missing coordinates")
            
            # Remove temporary columns and return filtered data
            result = df[~missing_coords].drop(columns=["LAT_NUMERIC", "LON_NUMERIC"])
            return result
        return df
    
    @property
    def description(self) -> str:
        return "Removes records with missing or invalid coordinates"