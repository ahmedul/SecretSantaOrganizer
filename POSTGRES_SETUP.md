# 🗄️ PostgreSQL Setup for Render (Data Persistence)

## ⚠️ The Problem

Your SQLite database is stored in the container filesystem, which gets **wiped** when:
- Render service restarts (after 15 min inactivity on free tier)
- You redeploy the service
- The container is recreated

**Result:** All groups and data are lost! 😱

## ✅ The Solution: PostgreSQL

Render offers a **free PostgreSQL database** (512 MB) that persists data permanently.

---

## 📋 Step-by-Step Setup

### Step 1: Create PostgreSQL Database on Render

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click **"New +"** → **"PostgreSQL"**
3. Fill in:
   - **Name:** `secretsanta-db`
   - **Database:** `drawjoy` (or leave default)
   - **User:** (auto-generated)
   - **Region:** Same as your web service (for speed)
   - **Instance Type:** **Free** ✅
4. Click **"Create Database"**
5. Wait 2-3 minutes for it to provision

### Step 2: Get Database Connection String

1. Once created, click on your database
2. Scroll to **"Connections"** section
3. Copy the **"Internal Database URL"** (starts with `postgres://`)
   - Example: `postgres://user:pass@hostname/dbname`
   - Use **Internal** (faster, free bandwidth within Render)

### Step 3: Add Database URL to Web Service

1. Go to your **Web Service** (`secretsantaorganizer-jbof`)
2. Click **"Environment"** tab (left sidebar)
3. Click **"Add Environment Variable"**
4. Add:
   - **Key:** `DATABASE_URL`
   - **Value:** Paste the Internal Database URL you copied
5. Click **"Save Changes"**

### Step 4: Deploy Updated Code

**Option A: Auto-deploy (if connected to GitHub)**
```bash
# Commit and push the changes
cd /home/akabir/git/my-projects/SecretSantaOrganizer
git add backend/database.py backend/requirements.txt
git commit -m "feat: add PostgreSQL support for data persistence"
git push origin main
```
Render will auto-deploy in 2-3 minutes.

**Option B: Manual deploy**
1. Go to your Web Service on Render
2. Click **"Manual Deploy"** → **"Deploy latest commit"**

### Step 5: Verify It Works

After deployment completes (5-10 minutes):

```bash
# Test creating a group
curl -X POST https://secretsantaorganizer-jbof.onrender.com/groups \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Persistence","budget":50}'

# You should get back a group with ID
# Save the ID (e.g., 1)

# Test that it persists (wait 30 seconds, then check)
curl https://secretsantaorganizer-jbof.onrender.com/groups/1

# Should return the group data!
```

---

## 🎯 Quick Commands

### Create the database and deploy:

```bash
# 1. Commit the changes
cd /home/akabir/git/my-projects/SecretSantaOrganizer
git add backend/database.py backend/requirements.txt POSTGRES_SETUP.md
git commit -m "feat: add PostgreSQL support for persistent storage

- Modified database.py to use DATABASE_URL env variable
- Falls back to SQLite for local development
- Added psycopg2-binary for PostgreSQL support
- Fixes data loss on Render service restarts"

git push origin main

# 2. Then go to Render Dashboard and:
#    - Create PostgreSQL database (free tier)
#    - Copy Internal Database URL
#    - Add DATABASE_URL env variable to web service
#    - Wait for auto-deploy
```

---

## 🔧 Local Development

The code automatically uses SQLite locally and PostgreSQL in production:

```bash
# Local (no DATABASE_URL set) - uses SQLite
cd backend
uvicorn main:app --reload

# Production (DATABASE_URL set) - uses PostgreSQL
# Render sets this automatically
```

---

## 📊 Free Tier Limits

**PostgreSQL Free Tier:**
- ✅ 512 MB storage
- ✅ Persistent data (never deleted)
- ✅ 90 day expiry warning (just click "keep" to extend)
- ✅ Automatic backups (point-in-time recovery)
- ✅ SSL encryption

**Estimated Capacity:**
- ~50,000 groups
- ~500,000 participants
- ~1,000,000 wishlists

**More than enough for your needs!** 🎉

---

## 🐛 Troubleshooting

### "Server Error 500" after adding DATABASE_URL

**Cause:** PostgreSQL not ready or wrong URL format

**Fix:**
1. Check database status in Render (should be "Available")
2. Verify DATABASE_URL is the **Internal** URL
3. Check logs: Render Dashboard → Your Service → Logs
4. Look for `sqlalchemy.exc` errors

### Tables not created automatically

The app creates tables on startup, but if there's an issue:

**Manual fix:**
```bash
# Connect to your database via Render shell
# Or create tables manually:
# Tables will auto-create on first request in main.py
```

### Want to reset the database

**Option 1: Drop all data (careful!)**
```sql
-- In Render database shell
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
```

**Option 2: Delete and recreate database**
1. Delete PostgreSQL service on Render
2. Create new one
3. Update DATABASE_URL env variable

---

## 💰 Cost Breakdown

| Service | Free Tier | Your Usage | Cost |
|---------|-----------|------------|------|
| Web Service | ✅ 750 hrs/month | Always on | $0 |
| PostgreSQL | ✅ 512 MB | ~10 MB | $0 |
| Bandwidth | ✅ 100 GB/month | <1 GB | $0 |
| **Total** | | | **$0/month** |

---

## 🎓 What Changed in the Code

### `backend/database.py`
```python
# Before
SQLALCHEMY_DATABASE_URL = "sqlite:///./drawjoy.db"

# After
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./drawjoy.db")
# Falls back to SQLite if DATABASE_URL not set
# Handles postgres:// → postgresql:// conversion for Render
```

### `backend/requirements.txt`
```
# Added
psycopg2-binary==2.9.9  # PostgreSQL adapter
```

---

## ✅ After Setup Checklist

- [ ] PostgreSQL database created on Render
- [ ] DATABASE_URL environment variable added to web service
- [ ] Code committed and pushed to GitHub
- [ ] Render auto-deployed successfully
- [ ] Tested creating a group
- [ ] Tested that group persists after 5 minutes
- [ ] Updated screenshots with persistent data for marketing

---

## 🚀 Benefits

Before PostgreSQL:
- ❌ Data lost on restart
- ❌ Groups disappear
- ❌ Users frustrated
- ❌ Can't use for real events

After PostgreSQL:
- ✅ Data persists forever
- ✅ Professional reliability
- ✅ Ready for real users
- ✅ Scales to thousands of groups
- ✅ Automatic backups

---

**Ready to set it up? Go to [Render Dashboard](https://dashboard.render.com/) and create the PostgreSQL database now!**

Estimated time: **5 minutes** ⏱️
