import logging
import pandas as pd
import os
from pathlib import Path
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Callable, Optional

from filters.Abstract_Filter import Filter

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

class QueimadaFilter(Filter):
    """Filter that removes Queimada records"""

    def apply(self, df: pd.DataFrame) -> pd.DataFrame:
        """Remove records where QUEIMADA is True/1/SIM"""
        if "QUEIMADA" in df.columns:
            # Handle different variations of true values
            false_alarms = df["QUEIMADA"].astype(str).str.upper().isin(["1", "SIM", "TRUE", "YES", "S", "Y", "T"])
            removed_count = sum(false_alarms)
            if removed_count > 0:
                logging.info(f"Removing {removed_count} Queimada records")
            return df[~false_alarms]
        return df
    
    @property
    def description(self) -> str:
        return "Removes records marked as Queimada"