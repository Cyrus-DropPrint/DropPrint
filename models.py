from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class SlicingJob(Base):
    __tablename__ = 'slicing_jobs'

    id = Column(Integer, primary_key=True)
    filename = Column(String, nullable=False)
    print_time_seconds = Column(Float)
    filament_length_mm = Column(Float)
    status = Column(String, default="pending")
    created_at = Column(DateTime, default=datetime.utcnow)
