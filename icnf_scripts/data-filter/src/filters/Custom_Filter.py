import logging
import pandas as pd

from filters.Abstract_Filter import Filter

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

class CustomFilter(Filter):
    """A configurable filter that uses a custom function"""
    
    def __init__(self, filter_func, desc: str):
        self.filter_func = filter_func
        self._description = desc
    
    def apply(self, df: pd.DataFrame) -> pd.DataFrame:
        return self.filter_func(df)
    
    @property
    def description(self) -> str:
        return self._description