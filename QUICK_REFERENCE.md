# 📋 DrawJoy Quick Reference Card

## For Organizers

### Creating a Group (30 seconds)
```
1. Tap "Create New Group"
2. Enter name + budget
3. Share the link
4. Wait for people to join
5. Tap "Draw Names"
✅ Done!
```

### What You Can Do
- ✅ Create unlimited groups
- ✅ See all participants
- ✅ Draw names (once per group)
- ✅ Share invite link
- ✅ Add exclusions (future feature)

### What You CAN'T Do
- ❌ See other people's assignments
- ❌ Manually assign people
- ❌ Draw names twice
- ❌ Remove participants after draw

---

## For Participants

### Joining a Group (20 seconds)
```
1. Click invite link (or enter code)
2. Add your name
3. Add wishlist (optional)
4. Tap "Join Group"
5. Wait for names to be drawn
6. See who you're buying for!
✅ Done!
```

### What You Can See
- ✅ Your own assignment
- ✅ Everyone's wishlists
- ✅ Group name & budget
- ✅ Number of participants

### What You CAN'T See
- ❌ Who's buying for you
- ❌ Other people's assignments
- ❌ Full assignment list
- ❌ Organizer's special access

---

## API Endpoints (For Developers)

### Create Group
```http
POST /groups
Body: { "name": "string", "budget": "string?" }
Returns: { "group_id": int, "share_link": "string" }
```

### Join Group
```http
POST /groups/{group_id}/join
Body: { "name": "string", "email": "string?", "wishlist": "string?" }
Returns: { "id": int, "name": "string", ... }
```

### Get Group Details
```http
GET /groups/{group_id}
Returns: { "name": "string", "drawn": bool, "participants": [...] }
```

### Draw Names
```http
POST /groups/{group_id}/draw
Returns: { "status": "drawn" }
```

### Get My Assignment
```http
GET /groups/{group_id}/my-target/{participant_id}
Returns: { "name": "string", "wishlist": "string" }
```

### Add Exclusion
```http
POST /groups/{group_id}/exclude
Body: { "giver_id": int, "receiver_id": int }
Returns: { "status": "excluded" }
```

---

## Database Schema (Quick)

```sql
groups (id, name, budget, drawn, created_at)
participants (id, name, email, wishlist, group_id, target_id)
exclusions (id, giver_id, receiver_id, group_id)
```

---

## Algorithm (Pseudocode)

```python
def secret_santa(participants, exclusions):
    for attempt in range(1000):
        assignments = shuffle(participants)
        if is_valid(assignments, exclusions):
            return assignments
    return None  # No valid assignment found

def is_valid(assignments, exclusions):
    for i, giver in enumerate(participants):
        receiver = assignments[i]
        if giver == receiver:  # Can't draw self
            return False
        if (giver, receiver) in exclusions:  # Excluded pair
            return False
    return True
```

---

## Tech Stack

### Frontend
- **Framework**: Flutter 3.0+
- **UI**: Material Design 3
- **State**: StatefulWidgets
- **HTTP**: http package

### Backend
- **Framework**: FastAPI (Python)
- **Database**: SQLite (dev) / PostgreSQL (prod)
- **ORM**: SQLAlchemy
- **Email**: Resend API

### Deployment
- **Backend**: Render.com (free tier)
- **iOS**: App Store
- **Android**: Google Play
- **Web**: Firebase Hosting / Netlify

---

## Commands Cheat Sheet

### Backend (Local)
```bash
# Setup
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run
uvicorn main:app --reload

# Test API
curl http://localhost:8000/docs
```

### Frontend (Local)
```bash
# Setup
cd flutter_app
flutter pub get

# Run
flutter run              # Default device
flutter run -d chrome    # Web
flutter run -d ios       # iOS simulator
flutter run -d android   # Android emulator
```

### Deployment
```bash
# Backend to Render
git push origin main  # Auto-deploys

# Flutter Web
flutter build web
firebase deploy --only hosting

# iOS
flutter build ios
# Then upload via Xcode

# Android
flutter build appbundle
# Then upload to Play Console
```

---

## Environment Variables

### Backend (.env or Render dashboard)
```bash
RESEND_API_KEY=re_xxxxx        # For email notifications
DATABASE_URL=postgresql://...   # For production database
```

### Flutter (update api_service.dart)
```dart
static const String baseUrl = 'https://your-api.onrender.com';
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Can't see my assignment" | Wait for organizer to draw names |
| "Draw button disabled" | Need ≥2 participants |
| "Invalid group code" | Check number, ask organizer |
| "Backend won't start" | Check Python version (3.10+) |
| "Flutter errors" | Run `flutter pub get` |
| "Database locked" | Delete `drawjoy.db` and restart |

---

## Key Files

```
backend/
  main.py          → API routes
  models.py        → Database tables
  derangement.py   → Secret Santa algorithm
  database.py      → DB configuration

flutter_app/lib/
  main.dart        → App entry
  screens/
    home_screen.dart         → Landing
    create_group_screen.dart → Create flow
    join_group_screen.dart   → Join flow
    group_detail_screen.dart → View/draw
  services/
    api_service.dart         → HTTP client
```

---

## Important URLs

- **API Docs**: http://localhost:8000/docs (local)
- **Production API**: https://your-app.onrender.com
- **Resend Dashboard**: https://resend.com/emails
- **Render Dashboard**: https://dashboard.render.com

---

## Support & Resources

- 📖 **Full Guide**: [HOW_TO_USE.md](HOW_TO_USE.md)
- 🎯 **App Flow**: [APP_FLOW.md](APP_FLOW.md)
- 🚀 **Deployment**: [DEPLOYMENT.md](DEPLOYMENT.md)
- 🆚 **Comparisons**: [COMPARISON.md](COMPARISON.md)
- 📝 **Main README**: [README.md](README.md)

---

## Quick Stats

- ⚡ **Setup Time**: 10 minutes
- 💰 **Cost**: $0 (free tier everything)
- 📱 **Platforms**: iOS, Android, Web
- 🔒 **Privacy**: No tracking, minimal data
- 🌍 **Remote**: Works anywhere, anytime
- 👥 **Scalability**: Tested up to 100 participants

---

## License & Credits

**License**: MIT (free to use and modify)

**Built With**: Flutter, FastAPI, SQLAlchemy, Resend

**Ship Date**: December 2025 🎄

---

**Questions?** Read the docs or create an issue on GitHub!

**Happy Secret Santa-ing!** 🎅🎁
