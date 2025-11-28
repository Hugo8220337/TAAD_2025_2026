import logging
import pandas as pd
import os
from pathlib import Path
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Callable, Optional

from filters.Abstract_Filter import Filter

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

class NotIncendioFilter(Filter):
    """Filter that removes Incendio records"""

    def apply(self, df: pd.DataFrame) -> pd.DataFrame:
        """Remove records where INCENDIO is True/1/SIM"""
        if "INCENDIO" in df.columns:
            # Handle different variations of true values
            false_alarms = df["INCENDIO"].astype(str).str.upper().isin(["0", "NAO", "NÃO", "FALSE", "SIM", "N", "F"])
            removed_count = sum(false_alarms)
            if removed_count > 0:
                logging.info(f"Removing {removed_count} Incendio records")
            return df[~false_alarms]
        return df
    
    @property
    def description(self) -> str:
        return "Removes records marked as Incendio"