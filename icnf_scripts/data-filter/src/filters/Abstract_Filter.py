import logging
import pandas as pd
from abc import ABC, abstractmethod

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

class Filter(ABC):
    """Base abstract class for all filters"""
    
    @abstractmethod
    def apply(self, df: pd.DataFrame) -> pd.DataFrame:
        """Apply the filter to a dataframe and return the filtered dataframe"""
        pass
    
    @property
    @abstractmethod
    def description(self) -> str:
        """Return a human-readable description of what this filter does"""
        pass