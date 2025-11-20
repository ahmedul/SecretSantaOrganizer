# Deployment Guide

Complete guide for deploying DrawJoy Secret Santa Organizer.

## 🎯 Quick Summary

- **Backend API**: ✅ Deployed at https://secretsantaorganizer-jbof.onrender.com
- **API Docs**: https://secretsantaorganizer-jbof.onrender.com/docs
- **Flutter App**: Configured to use production API

## 📱 Building Android APK

### Prerequisites
- Android SDK installed
- Flutter SDK installed
- Environment variable `ANDROID_HOME` set

### Steps

1. **Navigate to flutter_app directory:**
   ```bash
   cd flutter_app
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Build release APK:**
   ```bash
   flutter build apk --release
   ```

4. **Find the APK:**
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

5. **Distribute:**
   - Upload to Google Play Store (requires developer account)
   - Share APK file directly for sideloading
   - Host on GitHub Releases

### APK Installation
Users can install by:
1. Download `app-release.apk` to their Android device
2. Enable "Install from Unknown Sources" in Settings
3. Tap the APK file to install

## 🌐 Building for Web

### Known Issue
The `share_plus` package currently has compatibility issues with web builds (uses platform-specific code). 

### Workaround Options

**Option 1: Remove share_plus for web**

Edit `lib/screens/group_detail_screen.dart` and wrap share functionality:
```dart
import 'package:flutter/foundation.dart' show kIsWeb;

// In share button:
if (kIsWeb) {
  // Show dialog with group code to copy
  showDialog(...);
} else {
  Share.share(...);
}
```

**Option 2: Build without optimization**
```bash
flutter build web --release --no-wasm
```

**Option 3: Wait for package update**
The `share_plus` maintainers are working on web compatibility.

### Web Build Steps (after fixing share_plus)

1. **Clean build:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Build for web:**
   ```bash
   flutter build web --release
   ```

3. **Output directory:**
   ```
   build/web/
   ```

4. **Deploy to hosting:**
   - Firebase Hosting
   - Netlify
   - Vercel
   - GitHub Pages

## 🚀 Hosting Options

### Firebase Hosting

1. **Install Firebase CLI:**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login:**
   ```bash
   firebase login
   ```

3. **Initialize:**
   ```bash
   firebase init hosting
   ```
   - Public directory: `build/web`
   - Single-page app: Yes
   - Overwrite index.html: No

4. **Deploy:**
   ```bash
   firebase deploy
   ```

### Netlify

1. **Install Netlify CLI:**
   ```bash
   npm install -g netlify-cli
   ```

2. **Deploy:**
   ```bash
   cd build/web
   netlify deploy --prod
   ```

Or use drag-and-drop in Netlify web interface.

### GitHub Pages

1. **Build the web app**

2. **Create gh-pages branch:**
   ```bash
   git checkout -b gh-pages
   ```

3. **Copy web build to root:**
   ```bash
   cp -r flutter_app/build/web/* .
   ```

4. **Commit and push:**
   ```bash
   git add .
   git commit -m "Deploy web app"
   git push origin gh-pages
   ```

5. **Enable GitHub Pages:**
   - Go to repo Settings → Pages
   - Source: Deploy from branch
   - Branch: gh-pages / root

## 🔧 Backend Deployment (Already Complete)

The backend is deployed on Render.com:

### Configuration
- **Runtime:** Python 3.10+
- **Build Command:** `pip install -r backend/requirements.txt`
- **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
- **Root Directory:** `backend`

### Environment Variables (Optional)
- `RESEND_API_KEY` - For email notifications when names are drawn

### Auto-Deploy
Render automatically deploys when you push to the `main` branch on GitHub.

## 📦 Release Checklist

### Before Release
- [ ] Test all features with production backend
- [ ] Update version in `pubspec.yaml`
- [ ] Update CHANGELOG.md
- [ ] Create git tag: `git tag v1.0.0`
- [ ] Push tag: `git push origin v1.0.0`

### Android Release
- [ ] Build release APK
- [ ] Test APK on real device
- [ ] Sign APK (for Play Store)
- [ ] Upload to Play Store or GitHub Releases

### Web Release
- [ ] Fix share_plus compatibility
- [ ] Build web release
- [ ] Test on different browsers
- [ ] Deploy to hosting
- [ ] Update README with web URL

## 🔐 Security Notes

### API Key Management
- Never commit `RESEND_API_KEY` to git
- Set as environment variable in Render.com dashboard
- Email is optional - app works without it

### CORS Configuration
Current backend allows all origins (`*`). For production:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://your-web-app.netlify.app",
        "https://your-custom-domain.com"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 📊 Monitoring

### Render.com Dashboard
- View logs: https://dashboard.render.com
- Monitor: CPU, Memory, Response time
- Free tier spins down after 15 min inactivity (cold start ~30s)

### Database
- SQLite database persists on Render disk
- Backup: Download from Render dashboard
- For high traffic, consider PostgreSQL

## 🎉 Testing Production

1. **Test Backend:**
   ```bash
   curl https://secretsantaorganizer-jbof.onrender.com/docs
   ```

2. **Test App:**
   - Create a group
   - Join from another device
   - Draw names
   - Test reset functionality

## 📝 Next Steps

1. Fix `share_plus` web compatibility
2. Build and test Android APK (requires Android SDK)
3. Deploy web app to Firebase/Netlify
4. Create GitHub Release with APK
5. Add app to Play Store (optional)

## 🆘 Troubleshooting

### Backend Issues
- **Cold Start**: Free tier sleeps after inactivity. First request takes ~30s.
- **Database Reset**: If database is corrupted, delete `drawjoy.db` on Render.

### Flutter Build Issues
- **Web Build Fails**: Check for platform-specific packages
- **APK Build Fails**: Verify Android SDK installation
- **API Connection**: Check `lib/services/api_service.dart` has correct URL

## 📮 Support

For issues or questions:
1. Check the logs in Render dashboard
2. Review API docs: https://secretsantaorganizer-jbof.onrender.com/docs
3. Test with E2E script: `/tmp/e2e_api_test_v2.py`

---

Last Updated: November 20, 2025
Backend Status: ✅ Deployed and Running
