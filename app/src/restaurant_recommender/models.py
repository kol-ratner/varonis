from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import time


class Restaurant(BaseModel):
    name: str
    style: str
    address: str
    open_hour: str
    close_hour: str
    vegetarian: bool
    delivers: bool

    @validator('open_hour', 'close_hour')
    def validate_time_format(cls, v):
        try:
            hour, minute, second = map(int, v.split(':'))
            return time(hour, minute, second).strftime('%H:%M:%S')
        except ValueError:
            raise ValueError('Time must be in HH:MM:SS format')


class DatabaseConfig(BaseModel):
    user: str
    database: str
    host: str
    port: str
    min_pool_size: int = 5
    max_pool_size: int = 20