from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import List, Optional
import resend
import os
from database import SessionLocal, Base, engine
from models import Group, Participant, Exclusion, Expense
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
    if db_group.drawn:
        raise HTTPException(400, "Registration is closed. Names have already been drawn. Ask the organizer to reset the draw if you need to join.")
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

    # Optional email blast (only if API key is configured)
    try:
        for p in participants:
            if p.email and p.target_id:
                target = db.query(Participant).filter(Participant.id == p.target_id).first()
                resend.Emails.send({
                    "from": "santa@drawjoy.app",
                    "to": p.email,
                    "subject": f"Your Secret Santa for {group.name}!",
                    "html": f"You are buying for <b>{target.name}</b>!<br>Wishlist: {target.wishlist or '—'}",
                })
    except Exception as e:
        # Email sending failed, but draw was successful
        print(f"Email sending skipped: {e}")

    return {"status": "drawn"}

@app.post("/groups/{group_id}/reset-draw")
def reset_draw(group_id: int, db: Session = Depends(get_db)):
    """Reset the draw to allow adding more participants or re-drawing"""
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(404, "Group not found")
    if not group.drawn:
        raise HTTPException(400, "Names haven't been drawn yet")
    
    # Clear all target assignments
    participants = db.query(Participant).filter(Participant.group_id == group_id).all()
    for p in participants:
        p.target_id = None
    
    # Mark group as not drawn
    group.drawn = False
    db.commit()
    
    return {"status": "reset", "message": "Draw has been reset. You can now add participants or draw again."}

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
        "budget": group.budget,
        "participants": [{"id": p.id, "name": p.name, "wishlist": p.wishlist} for p in group.participants],
        "exclusions": [{"giver_id": e.giver_id, "receiver_id": e.receiver_id} for e in group.exclusions]
    }

# New endpoints for additional features

@app.put("/participants/{participant_id}/wishlist")
def update_wishlist(participant_id: int, wishlist: str, db: Session = Depends(get_db)):
    """Update participant's wishlist"""
    p = db.query(Participant).filter(Participant.id == participant_id).first()
    if not p:
        raise HTTPException(404, "Participant not found")
    p.wishlist = wishlist
    db.commit()
    return {"status": "updated", "wishlist": wishlist}

@app.delete("/groups/{group_id}")
def delete_group(group_id: int, db: Session = Depends(get_db)):
    """Delete a group and all its participants"""
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(404, "Group not found")
    # Delete all participants first
    db.query(Participant).filter(Participant.group_id == group_id).delete()
    # Delete all exclusions
    db.query(Exclusion).filter(Exclusion.group_id == group_id).delete()
    # Delete the group
    db.delete(group)
    db.commit()
    return {"status": "deleted"}

@app.delete("/participants/{participant_id}")
def remove_participant(participant_id: int, db: Session = Depends(get_db)):
    """Remove a participant from a group (only before drawing)"""
    p = db.query(Participant).filter(Participant.id == participant_id).first()
    if not p:
        raise HTTPException(404, "Participant not found")
    group = db.query(Group).filter(Group.id == p.group_id).first()
    if group.drawn:
        raise HTTPException(400, "Cannot remove participant after names have been drawn")
    db.delete(p)
    db.commit()
    return {"status": "removed"}

@app.get("/groups/{group_id}/exclusions")
def get_exclusions(group_id: int, db: Session = Depends(get_db)):
    """Get all exclusion rules for a group"""
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(404, "Group not found")
    exclusions = db.query(Exclusion).filter(Exclusion.group_id == group_id).all()
    participants = {p.id: p.name for p in group.participants}
    return {
        "exclusions": [
            {
                "id": e.id,
                "giver_id": e.giver_id,
                "giver_name": participants.get(e.giver_id, "Unknown"),
                "receiver_id": e.receiver_id,
                "receiver_name": participants.get(e.receiver_id, "Unknown")
            }
            for e in exclusions
        ]
    }

@app.delete("/exclusions/{exclusion_id}")
def delete_exclusion(exclusion_id: int, db: Session = Depends(get_db)):
    """Delete an exclusion rule"""
    excl = db.query(Exclusion).filter(Exclusion.id == exclusion_id).first()
    if not excl:
        raise HTTPException(404, "Exclusion not found")
    db.delete(excl)
    db.commit()
    return {"status": "deleted"}

# Budget Tracker endpoints

class ExpenseCreate(BaseModel):
    participant_id: int
    amount: float
    description: Optional[str] = None

@app.post("/groups/{group_id}/expenses")
def add_expense(group_id: int, expense: ExpenseCreate, db: Session = Depends(get_db)):
    """Add an expense for budget tracking"""
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(404, "Group not found")
    participant = db.query(Participant).filter(Participant.id == expense.participant_id).first()
    if not participant or participant.group_id != group_id:
        raise HTTPException(404, "Participant not found in this group")
    
    db_expense = Expense(
        participant_id=expense.participant_id,
        group_id=group_id,
        amount=expense.amount,
        description=expense.description
    )
    db.add(db_expense)
    db.commit()
    db.refresh(db_expense)
    return db_expense

@app.get("/groups/{group_id}/expenses")
def get_expenses(group_id: int, db: Session = Depends(get_db)):
    """Get all expenses for a group with budget summary"""
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(404, "Group not found")
    
    expenses = db.query(Expense).filter(Expense.group_id == group_id).all()
    total_spent = sum(e.amount for e in expenses)
    
    participants = {p.id: p.name for p in group.participants}
    budget = float(group.budget) if group.budget and group.budget.replace('.', '').isdigit() else None
    
    return {
        "budget": budget,
        "total_spent": total_spent,
        "remaining": (budget - total_spent) if budget else None,
        "expenses": [
            {
                "id": e.id,
                "participant_id": e.participant_id,
                "participant_name": participants.get(e.participant_id, "Unknown"),
                "amount": e.amount,
                "description": e.description,
                "created_at": e.created_at.isoformat()
            }
            for e in expenses
        ]
    }

@app.delete("/expenses/{expense_id}")
def delete_expense(expense_id: int, db: Session = Depends(get_db)):
    """Delete an expense"""
    expense = db.query(Expense).filter(Expense.id == expense_id).first()
    if not expense:
        raise HTTPException(404, "Expense not found")
    db.delete(expense)
    db.commit()
    return {"status": "deleted"}

# Initialize database
Base.metadata.create_all(bind=engine)
