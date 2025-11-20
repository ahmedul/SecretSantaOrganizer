# 🎄 DrawJoy - Secret Santa Organizer

**🚀 Live Backend API**: https://secretsantaorganizer-jbof.onrender.com  
**📚 API Documentation**: https://secretsantaorganizer-jbof.onrender.com/docs  
**🌐 Web App**: Ready to deploy! See [WEB_DEPLOY.md](WEB_DEPLOY.md)

A privacy-first Secret Santa app with Flutter frontend and FastAPI backend. Create groups, share links, draw names server-side, and send email notifications — all at $0 cost.

> **✨ New to the project?** Start with [HOW_TO_USE.md](HOW_TO_USE.md) to understand what this does!  
> **🛠️ Developer?** Check [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for API docs and commands.  
> **🚀 Deploy Web App**: See [WEB_DEPLOY.md](WEB_DEPLOY.md) - drag & drop to Netlify in 5 minutes!  
> **📱 Publish to Play Store**: See [PLAY_STORE_GUIDE.md](PLAY_STORE_GUIDE.md) for complete guide.

---

## 🎅 What Does This App Do?

DrawJoy solves the classic Secret Santa problem: **how do you randomly assign gift-givers to recipients without anyone knowing the full list?**

### The Problem It Solves:
1. **Traditional Secret Santa** - Drawing names from a hat is tedious and requires everyone to be present
2. **Privacy Issues** - Using spreadsheets or group chats exposes who's buying for whom
3. **Coordination Headaches** - Managing exclusions (couples shouldn't draw each other), budgets, and wishlists manually
4. **Remote Groups** - Hard to organize when people aren't in the same location

### How DrawJoy Works:

#### 1️⃣ **Create a Group** (The Organizer)
- Open the app and tap "Create New Group"
- Enter group name (e.g., "Office Party 2025") and optional budget
- Get a unique shareable link automatically
- Share the link via text, email, or social media

#### 2️⃣ **Join the Group** (Participants)
- Click the link or manually enter the group code
- Add your name, email (optional), and wishlist
- Your wishlist helps your Secret Santa know what you'd like!

#### 3️⃣ **Draw Names** (The Organizer)
- Once everyone has joined, tap "Draw Names"
- The **server** runs a derangement algorithm that:
  - Ensures everyone gets exactly one person to buy for
  - Nobody draws themselves
  - Respects exclusion rules (if set)
  - Keeps assignments completely private
- If emails were provided, everyone gets notified automatically
- **⚠️ Important**: Once names are drawn, registration closes automatically to prevent late joiners from disrupting assignments

#### 4️⃣ **View Your Assignment** (Everyone)
- Open the app and go to your group
- See who you're buying for and their wishlist
- **Important**: You can ONLY see who YOU'RE buying for, not who has you!

### Two-Phase System: Registration vs. Draw Complete

DrawJoy uses a **two-phase workflow** to ensure fair Secret Santa assignments:

**📝 Phase 1: Registration Open**
- Anyone with the group code can join
- Organizer can add/remove participants
- Set exclusions and manage budget
- No assignments yet - participants can freely join

**🔒 Phase 2: Draw Complete (Registration Closed)**
- Names have been drawn and assigned
- New participants **cannot** join to prevent disrupting assignments
- All participants can view their Secret Santa assignment
- Organizer can still manage the group

**❓ What if someone needs to join late?**
If someone needs to join after names are drawn:
1. **Organizer** opens the group menu (⋮)
2. Tap **"Reset Draw"** to clear all assignments
3. The late joiner can now join the group
4. **Organizer** taps **"Draw Names"** again to generate new assignments
5. Everyone gets notified of their new assignments

This ensures the Secret Santa assignments remain fair and complete - everyone has exactly one person to buy for!

### Real-World Example:

**The Smith Family Secret Santa:**
1. Mom creates "Smith Family 2025" group with $30 budget
2. She shares link in family group chat
3. Dad, Sister, Brother, Grandma all join and add wishlists
4. Brother excludes his wife from drawing him (they'll buy gifts separately)
5. Mom hits "Draw Names" → everyone gets an email
6. Dad opens app → sees he's buying for Sister (wishlist: books, coffee)
7. Sister opens app → sees she's buying for Grandma (wishlist: garden tools)
8. **Nobody knows** who has them until gift exchange day! 🎁

## ✨ Key Features

- 🔒 **True Privacy** - Server-side derangement algorithm ensures fair draws, no cheating possible
- 🔗 **Shareable Links** - Easy group invites via URLs (no account signup needed!)
- 🎁 **Wishlists** - Participants can add gift ideas so Secret Santas know what to buy
- 🚫 **Exclusions** - Prevent certain pairings (e.g., couples, best friends who already exchange gifts)
- 📧 **Email Notifications** - Optional notifications when names are drawn
- 📱 **Cross-Platform** - iOS, Android, and Web support
- 💰 **Budget Tracking** - Set spending limits and track expenses for your group
- 🌐 **Works Remotely** - Perfect for distributed teams or families
- 🔄 **Reset & Redraw** - Need to add someone late? Organizers can reset and redraw names
- 🎯 **Two-Phase System** - Registration open until draw, then locked to preserve assignments

## 📁 Project Structure

```
SecretSantaOrganizer/
├── backend/              # FastAPI Python backend
│   ├── main.py          # API endpoints (create group, join, draw, etc.)
│   ├── models.py        # Database models (Group, Participant, Exclusion)
│   ├── database.py      # Database configuration (SQLite/PostgreSQL)
│   ├── derangement.py   # Secret Santa algorithm (the magic!)
│   └── requirements.txt # Python dependencies
└── flutter_app/         # Flutter frontend
    ├── lib/
    │   ├── main.dart              # App entry point
    │   ├── services/
    │   │   └── api_service.dart   # Backend API client
    │   └── screens/
    │       ├── home_screen.dart         # Landing page
    │       ├── create_group_screen.dart # Create new group
    │       ├── join_group_screen.dart   # Join existing group
    │       └── group_detail_screen.dart # View group & draw names
    └── pubspec.yaml       # Flutter dependencies
```

## 🧠 The Secret Sauce: How the Algorithm Works

The **derangement algorithm** is what makes Secret Santa work. Here's the technical breakdown:

### What's a Derangement?
A derangement is a permutation where no element appears in its original position. In Secret Santa terms:
- Everyone must draw someone
- Nobody can draw themselves
- Each person is drawn exactly once

### The Algorithm (`backend/derangement.py`):

```python
def derange(names: list[str]) -> dict[str, str]:
    """
    Shuffle names until nobody draws themselves.
    Returns: {giver: receiver} dictionary
    """
    n = len(names)
    max_attempts = 1000  # Prevent infinite loops
    
    for _ in range(max_attempts):
        targets = names[:]
        random.shuffle(targets)
        
        # Check if valid: nobody drew themselves
        if all(targets[i] != names[i] for i in range(n)):
            return dict(zip(names, targets))
    
    return None  # Failed to find valid arrangement
```

### With Exclusions:
The algorithm gets more complex when you add exclusions (e.g., couples can't draw each other):

```python
def derange_with_exclusions(participants, exclusions):
    """
    Find a valid Secret Santa assignment respecting exclusions.
    
    Args:
        participants: List of Participant objects
        exclusions: Set of (giver_id, receiver_id) tuples
    
    Returns:
        {giver_id: receiver_id} dictionary or None if impossible
    """
    # Keep trying random arrangements until we find one that:
    # 1. Nobody draws themselves
    # 2. No excluded pairs are matched
    # 3. Everyone gets exactly one person
```

### Why Server-Side?
- **Privacy**: No participant can peek at the full assignment list
- **Fairness**: Organizer can't manipulate results
- **Reliability**: Works even if participants go offline
- **Security**: Prevents cheating or early reveals

### Example Flow:
```
Participants: [Alice, Bob, Charlie, Diana]
Exclusions: Bob ↔ Diana (they're married)

Attempt 1: Alice→Bob, Bob→Diana, Charlie→Alice, Diana→Charlie
❌ Violates exclusion (Bob→Diana)

Attempt 2: Alice→Charlie, Bob→Alice, Charlie→Diana, Diana→Bob
❌ Violates exclusion (Diana→Bob)

Attempt 3: Alice→Diana, Bob→Charlie, Charlie→Alice, Diana→Bob
❌ Violates exclusion (Diana→Bob)

Attempt 4: Alice→Bob, Bob→Charlie, Charlie→Diana, Diana→Alice
✅ Valid! Nobody draws self, no exclusions violated
```

## 📁 Project Structure

```
SecretSantaOrganizer/
├── backend/              # FastAPI Python backend
│   ├── main.py          # API endpoints
│   ├── models.py        # SQLAlchemy models
│   ├── database.py      # Database configuration
│   ├── derangement.py   # Secret Santa algorithm
│   └── requirements.txt # Python dependencies
└── flutter_app/         # Flutter frontend
    ├── lib/
    │   ├── main.dart
    │   ├── services/
    │   │   └── api_service.dart
    │   └── screens/
    │       ├── home_screen.dart
    │       ├── create_group_screen.dart
    │       ├── join_group_screen.dart
    │       └── group_detail_screen.dart
    └── pubspec.yaml
```

## 📚 Documentation

**Start Here:**
- 📖 **[HOW_TO_USE.md](HOW_TO_USE.md)** - Step-by-step guide for organizers and participants
- 🎯 **[APP_FLOW.md](APP_FLOW.md)** - Visual diagrams and data flow explanations
- ⚡ **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Cheat sheet for developers

**Additional Resources:**
- 🚀 **[DEPLOYMENT.md](DEPLOYMENT.md)** - Deploy to Render, iOS, Android, and Web
- 🆚 **[COMPARISON.md](COMPARISON.md)** - Why DrawJoy vs other Secret Santa methods

## �🚀 Quick Start

### Backend Setup (Local Development)

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Create virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the server:**
   ```bash
   uvicorn main:app --reload
   ```

   Server will be available at `http://localhost:8000`

5. **Test the API:**
   - Visit `http://localhost:8000/docs` for interactive API documentation
   - Or `http://localhost:8000/redoc` for alternative docs

### Flutter App Setup

1. **Navigate to flutter_app directory:**
   ```bash
   cd flutter_app
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

   For web:
   ```bash
   flutter run -d chrome
   ```

   For iOS (macOS only):
   ```bash
   flutter run -d ios
   ```

   For Android:
   ```bash
   flutter run -d android
   ```

## 🌐 Deployment

### Backend Deployment (Render.com - FREE)

1. **Create Render account** at [render.com](https://render.com)

2. **Push code to GitHub**

3. **Create new Web Service on Render:**
   - Connect your GitHub repository
   - Runtime: **Python 3**
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

4. **Add Environment Variable:**
   - Key: `RESEND_API_KEY`
   - Value: Get free API key from [resend.com](https://resend.com)

5. **Deploy!** Your API will be live at `https://your-app.onrender.com`

6. **Update Flutter app:**
   - Edit `flutter_app/lib/services/api_service.dart`
   - Change `baseUrl` from `http://localhost:8000` to your Render URL

### Database Upgrade (Optional - For Production)

The app uses SQLite by default. For production, switch to PostgreSQL:

1. **Add Render PostgreSQL** (free tier available)

2. **Update `backend/database.py`:**
   ```python
   import os
   SQLALCHEMY_DATABASE_URL = os.getenv(
       "DATABASE_URL",
       "sqlite:///./drawjoy.db"
   ).replace("postgres://", "postgresql://", 1)  # Render compatibility
   ```

3. **Add `DATABASE_URL` environment variable** in Render dashboard

### Flutter App Deployment

#### iOS (App Store)

1. **Setup Apple Developer Account** ($99/year)

2. **Configure in Xcode:**
   ```bash
   cd flutter_app
   open ios/Runner.xcworkspace
   ```
   - Set bundle identifier
   - Configure signing & capabilities

3. **Build and deploy:**
   ```bash
   flutter build ios
   ```
   - Upload to App Store Connect via Xcode

#### Android (Google Play)

1. **Create keystore:**
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Configure signing** in `android/key.properties`

3. **Build release APK:**
   ```bash
   flutter build appbundle
   ```

4. **Upload to Google Play Console**

#### Web Deployment (FREE)

Deploy to Firebase Hosting, Netlify, or Vercel:

```bash
flutter build web
# Then deploy the build/web folder
```

## 🔧 API Endpoints

### Groups

- `POST /groups` - Create new group
- `GET /groups/{group_id}` - Get group details
- `POST /groups/{group_id}/join` - Join a group
- `POST /groups/{group_id}/exclude` - Add exclusion rule
- `POST /groups/{group_id}/draw` - Perform Secret Santa draw
- `GET /groups/{group_id}/my-target/{participant_id}` - Get assigned person

### Example API Calls

**Create Group:**
```bash
curl -X POST http://localhost:8000/groups \
  -H "Content-Type: application/json" \
  -d '{"name": "Office Party 2025", "budget": "$25"}'
```

**Join Group:**
```bash
curl -X POST http://localhost:8000/groups/1/join \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com", "wishlist": "Books, coffee"}'
```

**Draw Names:**
```bash
curl -X POST http://localhost:8000/groups/1/draw
```

## 🧪 Testing the Derangement Algorithm

The heart of Secret Santa is the derangement algorithm (`backend/derangement.py`). Test it:

```python
from backend.derangement import derange

names = ["Alice", "Bob", "Charlie", "Diana"]
result = derange(names)
print(result)
# Example output: {'Alice': 'Charlie', 'Bob': 'Diana', 'Charlie': 'Alice', 'Diana': 'Bob'}
```

## 🛠️ Troubleshooting

### Backend Issues

**Port already in use:**
```bash
# Find and kill process using port 8000
lsof -ti:8000 | xargs kill -9
```

**Database locked error:**
```bash
# Remove database and restart
rm drawjoy.db
uvicorn main:app --reload
```

### Flutter Issues

**Dependency conflicts:**
```bash
flutter clean
flutter pub get
```

**iOS build fails:**
```bash
cd ios
pod deinstall
pod install
cd ..
flutter run
```

## 📋 Todo Before Launch

- [ ] Replace `yourdomain.com` in code with actual domain
- [ ] Set up custom domain for Render backend
- [ ] Configure Resend email sender domain
- [ ] Test on real devices (iOS + Android)
- [ ] Add app icons and splash screens
- [ ] Write privacy policy & terms of service
- [ ] Set up analytics (optional)
- [ ] Add deep linking for group invites
- [ ] Test with 10+ participants
- [ ] Add exclusion management UI

## 🎯 Roadmap to Launch (Dec 8-10)

### Week 1 (Nov 19-25)
- ✅ Backend API complete
- ✅ Flutter app UI complete
- [ ] Test end-to-end flow locally
- [ ] Deploy backend to Render

### Week 2 (Nov 26-Dec 2)
- [ ] Add app icons & branding
- [ ] Implement deep linking
- [ ] Add exclusion management
- [ ] Beta testing with friends

### Week 3 (Dec 3-9)
- [ ] Polish UI/UX
- [ ] App store submissions
- [ ] Final testing
- [ ] 🚀 Launch!

## 📜 License

MIT License - Free to use and modify

## 🤝 Contributing

This is a personal project built to ship fast. Feel free to fork and customize!

---

**Built with ❤️ for the holidays** 🎅🎄

Ready to ship? Let's make Secret Santa magical! ✨
