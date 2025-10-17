import logging
import pandas as pd
import os
from pathlib import Path
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Callable, Optional

from filters.Abstract_Filter import Filter

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

class FilterPipeline:
    """A pipeline that applies multiple filters in sequence"""
    
    def __init__(self):
        self.filters: List[Filter] = []
    
    def add_filter(self, filter_obj: Filter) -> 'FilterPipeline':
        """Add a filter to the pipeline"""
        self.filters.append(filter_obj)
        return self
    
    def apply(self, df: pd.DataFrame) -> pd.DataFrame:
        """Apply all filters in sequence"""
        result = df.copy()
        original_count = len(result)
        
        for f in self.filters:
            logging.info(f"Applying filter: {f.description}")
            result = f.apply(result)
        
        removed_count = original_count - len(result)
        if removed_count > 0:
            logging.info(f"Total records removed: {removed_count} ({removed_count/original_count:.1%})")
        
        return result