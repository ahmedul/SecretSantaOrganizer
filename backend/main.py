from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import List, Optional
import resend
import os
from database import SessionLocal, Base, engine
from models import Group, Participant, Exclusion
from derangement import derange_with_exclusions

resend.api_key = os.getenv("RESEND_API_KEY")  # put your key in Render env vars

app = FastAPI(title="DrawJoy API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class ParticipantCreate(BaseModel):
    name: str
    email: Optional[EmailStr] = None
    wishlist: Optional[str] = None

class GroupCreate(BaseModel):
    name: str
    budget: Optional[str] = None
    reveal_at: Optional[str] = None

@app.post("/groups", status_code=201)
def create_group(group: GroupCreate, db: Session = Depends(get_db)):
    db_group = Group(name=group.name, budget=group.budget)
    db.add(db_group)
    db.commit()
    db.refresh(db_group)
    return {"group_id": db_group.id, "share_link": f"https://yourdomain.com/join/{db_group.id}"}

@app.post("/groups/{group_id}/join")
def join_group(group_id: int, participant: ParticipantCreate, db: Session = Depends(get_db)):
    db_group = db.query(Group).filter(Group.id == group_id).first()
    if not db_group:
        raise HTTPException(404, "Group not found")
    db_part = Participant(**participant.dict(), group_id=group_id)
    db.add(db_part)
    db.commit()
    db.refresh(db_part)
    return db_part

@app.post("/groups/{group_id}/exclude")
def add_exclusion(group_id: int, giver_id: int, receiver_id: int, db: Session = Depends(get_db)):
    db_group = db.query(Group).filter(Group.id == group_id).first()
    if not db_group:
        raise HTTPException(404)
    excl = Exclusion(giver_id=giver_id, receiver_id=receiver_id, group_id=group_id)
    db.add(excl)
    db.commit()
    return {"status": "excluded"}

@app.post("/groups/{group_id}/draw")
def draw(group_id: int, db: Session = Depends(get_db)):
    group = db.query(Group).filter(Group.id == group_id).first()
    if group.drawn:
        raise HTTPException(400, "Already drawn")
    participants = db.query(Participant).filter(Participant.group_id == group_id).all()
    if len(participants) < 2:
        raise HTTPException(400, "Need ≥2")

    exclusions = {(e.giver_id, e.receiver_id) for e in group.exclusions}
    assignment = derange_with_exclusions(participants, exclusions)
    if not assignment:
        raise HTTPException(400, "No valid assignment (too many exclusions)")

    for giver_id, target_id in assignment.items():
        p = db.query(Participant).filter(Participant.id == giver_id).first()
        p.target_id = target_id
    group.drawn = True
    db.commit()

    # Optional email blast
    for p in participants:
        if p.email and p.target_id:
            target = db.query(Participant).filter(Participant.id == p.target_id).first()
            resend.Emails.send({
                "from": "santa@drawjoy.app",
                "to": p.email,
                "subject": f"Your Secret Santa for {group.name}!",
                "html": f"You are buying for <b>{target.name}</b>!<br>Wishlist: {target.wishlist or '—'}",
            })

    return {"status": "drawn"}

@app.get("/groups/{group_id}/my-target/{participant_id}")
def get_my_target(group_id: int, participant_id: int, db: Session = Depends(get_db)):
    p = db.query(Participant).filter(Participant.id == participant_id, Participant.group_id == group_id).first()
    if not p or not p.target_id:
        raise HTTPException(404, "Not drawn yet or wrong person")
    target = db.query(Participant).filter(Participant.id == p.target_id).first()
    return {"name": target.name, "wishlist": target.wishlist or ""}

@app.get("/groups/{group_id}")
def get_group(group_id: int, db: Session = Depends(get_db)):
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(404)
    return {
        "name": group.name,
        "drawn": group.drawn,
        "participants": [{"id": p.id, "name": p.name, "wishlist": p.wishlist} for p in group.participants]
    }

# Initialize database
Base.metadata.create_all(bind=engine)
