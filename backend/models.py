from sqlalchemy import Column, Integer, String, ForeignKey, Boolean, DateTime
from sqlalchemy.orm import relationship
from database import Base
import datetime

class Group(Base):
    __tablename__ = "groups"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    budget = Column(String, nullable=True)
    reveal_at = Column(DateTime, nullable=True)
    drawn = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    participants = relationship("Participant", back_populates="group")
    exclusions = relationship("Exclusion", back_populates="group")

class Participant(Base):
    __tablename__ = "participants"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String, nullable=True)
    wishlist = Column(String, nullable=True)
    group_id = Column(Integer, ForeignKey("groups.id"))
    target_id = Column(Integer, nullable=True)  # filled after draw

    group = relationship("Group", back_populates="participants")

class Exclusion(Base):
    __tablename__ = "exclusions"
    id = Column(Integer, primary_key=True, index=True)
    giver_id = Column(Integer, ForeignKey("participants.id"))
    receiver_id = Column(Integer, ForeignKey("participants.id"))
    group_id = Column(Integer, ForeignKey("groups.id"))

    group = relationship("Group", back_populates="exclusions")
