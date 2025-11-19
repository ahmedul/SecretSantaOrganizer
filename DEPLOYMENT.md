# 🚀 DrawJoy Deployment Checklist

## Pre-Deployment Setup

### 1. Email Service (Resend)
- [ ] Sign up at [resend.com](https://resend.com)
- [ ] Get API key from dashboard
- [ ] (Optional) Verify custom domain for branded emails
- [ ] Test email sending locally

### 2. GitHub Repository
- [ ] Create new GitHub repository
- [ ] Push all code:
  ```bash
  git init
  git add .
  git commit -m "Initial commit - DrawJoy Secret Santa"
  git branch -M main
  git remote add origin https://github.com/yourusername/drawjoy.git
  git push -u origin main
  ```

## Backend Deployment (Render.com)

### Step-by-Step:

1. **Go to [render.com](https://render.com) and sign up/login**

2. **Click "New +" → "Web Service"**

3. **Connect GitHub repository:**
   - Select "SecretSantaOrganizer" repo
   - Click "Connect"

4. **Configure service:**
   - Name: `drawjoy-api` (or your choice)
   - Region: Choose closest to users
   - Branch: `main`
   - Root Directory: `backend`
   - Runtime: `Python 3`
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

5. **Environment Variables:**
   - Click "Advanced" → "Add Environment Variable"
   - Key: `RESEND_API_KEY`
   - Value: `[your-resend-api-key]`

6. **Instance Type:**
   - Select "Free" tier (perfect for starting)

7. **Click "Create Web Service"**

8. **Wait for deployment** (2-5 minutes)
   - Monitor logs for any errors
   - Note your live URL: `https://drawjoy-api.onrender.com`

### Post-Deployment:

- [ ] Test API at `https://your-url.onrender.com/docs`
- [ ] Create a test group via API
- [ ] Verify database persistence (create → reload page)

## Update Flutter App with Backend URL

1. **Edit `flutter_app/lib/services/api_service.dart`:**
   ```dart
   static const String baseUrl = 'https://drawjoy-api.onrender.com';
   ```

2. **Test locally:**
   ```bash
   cd flutter_app
   flutter run
   ```

3. **Verify:**
   - [ ] Can create groups
   - [ ] Can join groups
   - [ ] Can draw names
   - [ ] Can view assignments

## Optional: Database Upgrade to PostgreSQL

### If your app grows beyond SQLite:

1. **In Render dashboard:**
   - Click "New +" → "PostgreSQL"
   - Name: `drawjoy-db`
   - Select Free tier
   - Click "Create Database"

2. **Copy "Internal Database URL" from database dashboard**

3. **Add to Web Service Environment Variables:**
   - Key: `DATABASE_URL`
   - Value: `[your-postgres-url]`

4. **Update `backend/database.py`:**
   ```python
   import os
   
   SQLALCHEMY_DATABASE_URL = os.getenv(
       "DATABASE_URL",
       "sqlite:///./drawjoy.db"
   )
   
   # Fix for Render's postgres:// URLs
   if SQLALCHEMY_DATABASE_URL.startswith("postgres://"):
       SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace(
           "postgres://", "postgresql://", 1
       )
   
   connect_args = {} if "postgresql" in SQLALCHEMY_DATABASE_URL else {"check_same_thread": False}
   engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args=connect_args)
   ```

5. **Redeploy** (auto-deploys on git push)

## Flutter App Store Deployment

### iOS App Store

**Prerequisites:**
- Apple Developer Account ($99/year)
- Mac with Xcode

**Steps:**

1. **App Store Connect Setup:**
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Create new app
   - Bundle ID: `com.yourcompany.drawjoy`

2. **Update Flutter project:**
   ```bash
   cd flutter_app/ios
   open Runner.xcworkspace
   ```
   - Update Bundle Identifier
   - Select Team
   - Configure signing

3. **Build:**
   ```bash
   flutter build ios --release
   ```

4. **Archive & Upload in Xcode:**
   - Product → Archive
   - Distribute App → App Store Connect
   - Upload

5. **Submit for Review:**
   - Add screenshots
   - App description
   - Privacy policy URL
   - Submit

### Android Google Play

**Prerequisites:**
- Google Play Developer Account ($25 one-time)

**Steps:**

1. **Create keystore:**
   ```bash
   keytool -genkey -v -keystore ~/drawjoy-upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias drawjoy
   ```

2. **Create `flutter_app/android/key.properties`:**
   ```
   storePassword=<password-from-step-1>
   keyPassword=<password-from-step-1>
   keyAlias=drawjoy
   storeFile=/Users/yourname/drawjoy-upload-keystore.jks
   ```

3. **Update `flutter_app/android/app/build.gradle`:**
   Add before `android` block:
   ```gradle
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }
   ```

   In `android` block:
   ```gradle
   signingConfigs {
       release {
           keyAlias keystoreProperties['keyAlias']
           keyPassword keystoreProperties['keyPassword']
           storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
           storePassword keystoreProperties['storePassword']
       }
   }
   buildTypes {
       release {
           signingConfig signingConfigs.release
       }
   }
   ```

4. **Build release bundle:**
   ```bash
   flutter build appbundle
   ```

5. **Google Play Console:**
   - Go to [play.google.com/console](https://play.google.com/console)
   - Create app
   - Upload `build/app/outputs/bundle/release/app-release.aab`
   - Fill in store listing
   - Submit for review

### Web Deployment (FREE - Firebase/Netlify)

**Option A: Firebase Hosting**

1. **Install Firebase CLI:**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Initialize:**
   ```bash
   cd flutter_app
   firebase init hosting
   ```
   - Select "Use an existing project" or create new
   - Public directory: `build/web`
   - Single-page app: Yes
   - GitHub deploys: Optional

3. **Build & Deploy:**
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

**Option B: Netlify**

1. **Build:**
   ```bash
   flutter build web --release
   ```

2. **Go to [netlify.com](https://netlify.com)**
   - Drag and drop `flutter_app/build/web` folder
   - Or connect GitHub for auto-deploys

## Post-Launch Monitoring

### Render Dashboard
- [ ] Check logs for errors
- [ ] Monitor response times
- [ ] Set up Render alerts

### Testing
- [ ] Test all features on production
- [ ] Try creating group with 10+ people
- [ ] Verify email notifications work
- [ ] Test on multiple devices

### Analytics (Optional)
- [ ] Add Firebase Analytics
- [ ] Track app installs
- [ ] Monitor user engagement

## Launch Checklist

- [ ] Backend deployed and tested
- [ ] Flutter app pointing to production API
- [ ] Email notifications working
- [ ] iOS app submitted (if ready)
- [ ] Android app submitted (if ready)
- [ ] Web app live
- [ ] Privacy policy published
- [ ] Social media ready (optional)
- [ ] Friends/family beta test complete

## 🎉 You're Live!

Share your creation:
- iOS: `https://apps.apple.com/app/drawjoy/[your-app-id]`
- Android: `https://play.google.com/store/apps/details?id=com.yourcompany.drawjoy`
- Web: `https://your-site.web.app`

---

**Questions? Issues? Debug:**
1. Check Render logs
2. Test API at `/docs` endpoint
3. Use Flutter DevTools for app debugging
4. Check email sent logs in Resend dashboard

**Ship it! 🚀🎄**
