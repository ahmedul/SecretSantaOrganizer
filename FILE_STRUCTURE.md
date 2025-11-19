# 📁 Complete Project Structure

## DrawJoy - File Tree

```
SecretSantaOrganizer/
│
├── 📄 Documentation (7 files)
│   ├── README.md ........................... Main project overview
│   ├── HOW_TO_USE.md ....................... User guide (organizers & participants)
│   ├── APP_FLOW.md ......................... Visual diagrams & data flow
│   ├── DEPLOYMENT.md ....................... Deploy to Render/iOS/Android/Web
│   ├── COMPARISON.md ....................... vs other Secret Santa methods
│   ├── QUICK_REFERENCE.md .................. Developer cheat sheet
│   └── PROJECT_SUMMARY.md .................. What you just built (this summary)
│
├── 🐍 Backend (FastAPI + Python)
│   ├── main.py ............................. API endpoints (create, join, draw)
│   ├── models.py ........................... Database models (Group, Participant, Exclusion)
│   ├── database.py ......................... SQLite/PostgreSQL configuration
│   ├── derangement.py ...................... Secret Santa algorithm ⭐
│   ├── requirements.txt .................... Python dependencies
│   ├── __init__.py ......................... Python package marker
│   ├── .gitignore .......................... Ignore venv, *.db, etc.
│   └── venv/ ............................... Virtual environment (not in git)
│
├── 📱 Flutter App (Mobile + Web)
│   ├── pubspec.yaml ........................ Flutter dependencies
│   ├── .gitignore .......................... Flutter-specific ignores
│   │
│   └── lib/
│       ├── main.dart ....................... App entry point
│       │
│       ├── services/
│       │   └── api_service.dart ............ HTTP client for backend
│       │
│       └── screens/
│           ├── home_screen.dart ............ Landing page (create/join buttons)
│           ├── create_group_screen.dart .... Create new Secret Santa group
│           ├── join_group_screen.dart ...... Join existing group
│           └── group_detail_screen.dart .... View group, draw names, see assignment
│
└── .git/ (after git init) .................. Version control
```

## File Purposes at a Glance

### 📚 Documentation (for humans)
| File | Purpose | Audience |
|------|---------|----------|
| `README.md` | Project overview, setup | Everyone |
| `HOW_TO_USE.md` | Step-by-step user guide | End users |
| `APP_FLOW.md` | Visual diagrams, internals | Developers, curious users |
| `DEPLOYMENT.md` | Deploy to production | DevOps, deployment |
| `COMPARISON.md` | Why use DrawJoy | Marketing, users |
| `QUICK_REFERENCE.md` | API docs, commands | Developers |
| `PROJECT_SUMMARY.md` | What was built | Project overview |

### 🐍 Backend (the brains)
| File | Purpose | Lines | Key Functions |
|------|---------|-------|---------------|
| `main.py` | API routes | ~130 | `create_group()`, `join_group()`, `draw()` |
| `models.py` | DB schema | ~40 | `Group`, `Participant`, `Exclusion` classes |
| `database.py` | DB config | ~10 | Engine setup, session management |
| `derangement.py` | Algorithm | ~25 | `derange()`, `derange_with_exclusions()` |
| `requirements.txt` | Dependencies | ~9 | FastAPI, SQLAlchemy, Resend, etc. |

### 📱 Flutter (the face)
| File | Purpose | Lines | Key Widgets |
|------|---------|-------|-------------|
| `main.dart` | App setup | ~40 | `DrawJoyApp`, theme config |
| `api_service.dart` | Backend client | ~15 | API endpoint URLs |
| `home_screen.dart` | Landing page | ~120 | Create/Join buttons |
| `create_group_screen.dart` | Create flow | ~180 | Form, share dialog |
| `join_group_screen.dart` | Join flow | ~160 | Form, validation |
| `group_detail_screen.dart` | Main screen | ~250 | Participant list, draw button |
| `pubspec.yaml` | Dependencies | ~30 | http, share_plus, etc. |

## Code Statistics

```
Language      Files    Lines    Purpose
─────────────────────────────────────────────────
Markdown         7    1,600    Documentation
Python           5      500    Backend API & algorithm
Dart             7      900    Flutter mobile/web app
YAML             1       30    Flutter dependencies
─────────────────────────────────────────────────
Total           20    3,030    Complete application
```

## Data Flow Through Files

```
User Interaction
      ↓
┌─────────────────────────────────────┐
│  home_screen.dart                   │ → User taps "Create Group"
└──────────┬──────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  create_group_screen.dart           │ → Form validation
└──────────┬──────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  api_service.dart                   │ → HTTP POST /groups
└──────────┬──────────────────────────┘
           │ (Network Request)
           ↓
┌─────────────────────────────────────┐
│  main.py → create_group()           │ → Validate, create DB entry
└──────────┬──────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  models.py → Group()                │ → ORM object
└──────────┬──────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  database.py → SessionLocal()       │ → Database transaction
└──────────┬──────────────────────────┘
           ↓
        SQLite DB
           │
           ↓ (Response back up the chain)
           
    Returns {group_id, share_link}
           ↓
     Flutter shows success dialog
```

## Import Dependencies

### Backend (main.py imports)
```python
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
import resend
import os

from database import SessionLocal, Base, engine
from models import Group, Participant, Exclusion
from derangement import derange_with_exclusions
```

### Flutter (screens import)
```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';
```

## Critical Files (Don't Delete!)

### Must Have for Backend
- ✅ `main.py` - Without this, no API
- ✅ `models.py` - Without this, no database structure
- ✅ `derangement.py` - Without this, can't draw names
- ✅ `database.py` - Without this, can't persist data

### Must Have for Flutter
- ✅ `main.dart` - App won't start
- ✅ `pubspec.yaml` - Can't install dependencies
- ✅ `api_service.dart` - Can't talk to backend
- ✅ All 4 screen files - Missing UI

## Optional Files (Can Modify/Remove)

### Safe to Customize
- 📝 All `.md` files (documentation only)
- 🎨 Flutter screen designs (UI preference)
- 🔧 `requirements.txt` (if you swap libraries)
- ⚙️ `.gitignore` files (preference)

### Never Commit
- 🚫 `venv/` folder
- 🚫 `*.db` files
- 🚫 `__pycache__/`
- 🚫 `.env` files (if you add them)

## File Size Reference

```
Largest Files:
  group_detail_screen.dart  →  ~10 KB  (Most complex UI)
  main.py                   →  ~5 KB   (All API endpoints)
  HOW_TO_USE.md             →  ~20 KB  (Most detailed doc)

Smallest Files:
  __init__.py               →  48 B    (Empty marker file)
  .gitignore                →  ~300 B  (Few lines)
  database.py               →  ~430 B  (Simple config)

Total Project Size:
  Without venv: ~100 KB
  With venv:    ~50 MB (Python packages)
  With docs:    ~150 KB
```

## How to Navigate This Project

### I want to...

**Understand what this does**
→ Start with `README.md`, then `HOW_TO_USE.md`

**See how it works internally**
→ Read `APP_FLOW.md` for diagrams

**Deploy to production**
→ Follow `DEPLOYMENT.md` step-by-step

**Modify the algorithm**
→ Edit `backend/derangement.py`

**Change the UI**
→ Edit files in `flutter_app/lib/screens/`

**Add new API endpoint**
→ Add function to `backend/main.py`

**Fix a bug**
→ Use `QUICK_REFERENCE.md` to understand structure

**Compare to alternatives**
→ Read `COMPARISON.md`

## Version Control Setup

### Initialize Git
```bash
cd /home/akabir/git/my-projects/SecretSantaOrganizer
git init
git add .
git commit -m "Initial commit - DrawJoy Secret Santa 🎁"
```

### What Gets Committed?
```
✅ All .md files (documentation)
✅ All .py files (backend code)
✅ All .dart files (Flutter code)
✅ pubspec.yaml (Flutter config)
✅ requirements.txt (Python packages list)
✅ .gitignore files

❌ venv/ (virtual environment)
❌ *.db (database files)
❌ __pycache__/ (Python cache)
❌ build/ (Flutter builds)
```

## Next Steps

### 1. Test Locally
```bash
# Terminal 1
cd backend
source venv/bin/activate
uvicorn main:app --reload

# Terminal 2
cd flutter_app
flutter run -d chrome
```

### 2. Deploy
```bash
# Push to GitHub
git remote add origin <your-repo-url>
git push -u origin main

# Deploy backend (Render auto-detects)
# Deploy Flutter (follow DEPLOYMENT.md)
```

### 3. Share
```
Send friends/family:
- The deployed web URL
- Or the App Store link
- Or the Play Store link
```

---

## File Checklist ✅

- [x] 7 documentation files
- [x] 5 Python backend files
- [x] 7 Dart Flutter files
- [x] 1 Python requirements file
- [x] 1 Flutter dependencies file
- [x] 2 .gitignore files

**Total: 23 essential files + 1 venv folder**

---

**Everything is organized, documented, and ready to ship! 🚀**

Check [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) for what to do next!
