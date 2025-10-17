import logging
import pandas as pd
import os
from pathlib import Path
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Callable, Optional

from filters.Abstract_Filter import Filter

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

class AreaThresholdFilter(Filter):
    """Filter that removes records with area below a threshold"""
    
    def __init__(self, min_area: float = 0.1):
        self.min_area = min_area
    
    def apply(self, df: pd.DataFrame) -> pd.DataFrame:
        if "AREATOTAL" in df.columns:
            # Convert to numeric and handle comma as decimal separator
            df["AREATOTAL_NUMERIC"] = pd.to_numeric(
                df["AREATOTAL"].astype(str).str.replace(',', '.'), 
                errors='coerce'
            )
            # Filter by minimum area
            small_areas = df["AREATOTAL_NUMERIC"] < self.min_area
            removed_count = sum(small_areas)
            if removed_count > 0:
                logging.info(f"Removing {removed_count} records with area < {self.min_area}")
            # Remove the temporary numeric column
            result = df[~small_areas].drop(columns=["AREATOTAL_NUMERIC"])
            return result
        return df
    
    @property
    def description(self) -> str:
        return f"Removes records with total area below {self.min_area}"