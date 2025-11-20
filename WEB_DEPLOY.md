# 🌐 Deploy Web App to Netlify

Quick guide to deploy DrawJoy web app to Netlify (free hosting).

## 🚀 Quick Deploy (Drag & Drop)

**Fastest Method - 5 minutes:**

1. **Build the app** (already done!):
   ```bash
   cd flutter_app
   flutter build web --release
   ```
   Output: `build/web/`

2. **Go to Netlify**:
   - Visit: https://app.netlify.com/drop
   - No account needed for first deploy!

3. **Drag & Drop**:
   - Drag the entire `flutter_app/build/web/` folder
   - Drop it on the Netlify page
   - Wait 10-30 seconds

4. **Get Your URL**:
   - Netlify gives you a URL like: `https://random-name-123.netlify.app`
   - App is now live! 🎉

5. **Optional - Custom subdomain**:
   - Click "Site settings"
   - Change site name to: `drawjoy` or `secretsanta-organizer`
   - New URL: `https://drawjoy.netlify.app`

---

## 📦 Deploy via CLI (Recommended for Updates)

**For ongoing updates:**

### 1. Install Netlify CLI

```bash
npm install -g netlify-cli
# or
sudo snap install netlify
```

### 2. Login

```bash
netlify login
```
Browser opens → Sign in with GitHub/Email

### 3. Initialize Site

```bash
cd flutter_app/build/web
netlify init
```

Follow prompts:
- Create new site
- Team: Your account
- Site name: `drawjoy` (or your choice)
- Publish directory: `.` (we're already in build/web)

### 4. Deploy

```bash
netlify deploy --prod
```

Done! Your site is live.

### 5. Future Updates

```bash
# From flutter_app directory
flutter build web --release
cd build/web
netlify deploy --prod
```

---

## 🔗 Deploy via GitHub (Auto-Deploy)

**Best for continuous deployment:**

### 1. Create `netlify.toml` in repo root:

```toml
[build]
  base = "flutter_app"
  command = "flutter build web --release"
  publish = "build/web"

[build.environment]
  FLUTTER_VERSION = "3.38.2"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### 2. Push to GitHub

```bash
git add netlify.toml
git commit -m "Add Netlify config"
git push origin main
```

### 3. Connect to Netlify

1. Go to: https://app.netlify.com
2. Click "Add new site" → "Import an existing project"
3. Choose "GitHub"
4. Select `SecretSantaOrganizer` repo
5. Netlify auto-detects settings from `netlify.toml`
6. Click "Deploy site"

### 4. Auto-Deploy Enabled!

Now every push to `main` branch automatically deploys! ✨

---

## 🎯 Custom Domain (Optional)

### Free Netlify Subdomain:
`https://drawjoy.netlify.app` (already done in step 5 above)

### Custom Domain ($12/year):
1. Buy domain (Namecheap, Google Domains, etc.)
2. In Netlify: Site settings → Domain management
3. Click "Add custom domain"
4. Follow DNS instructions
5. SSL certificate added automatically!

---

## ✅ Post-Deploy Checklist

After deployment:

- [ ] Visit your URL - app loads correctly
- [ ] Test creating a group
- [ ] Test joining a group
- [ ] Check share link works (copy to clipboard)
- [ ] Test draw names function
- [ ] Verify API connection to Render backend
- [ ] Test on mobile browser
- [ ] Test on different browsers (Chrome, Firefox, Safari)
- [ ] Update README with web app URL

---

## 🔧 Troubleshooting

### "Failed to load flutter.js"
**Solution**: Clear browser cache or try incognito mode

### "API connection failed"
**Check**: 
- Backend is running: https://secretsantaorganizer-jbof.onrender.com/docs
- CORS settings allow your Netlify domain
- No console errors about mixed content (http vs https)

### "Share button doesn't work"
**Expected**: On web, it shows a dialog with copyable link (not native share)

### Build fails on Netlify
**Solution**: 
1. Check Flutter version in `netlify.toml` matches yours
2. Ensure `pubspec.yaml` dependencies are compatible
3. Check build logs for specific errors

---

## 📊 Your Current Setup

✅ **Backend**: https://secretsantaorganizer-jbof.onrender.com  
✅ **Web Build**: Ready in `flutter_app/build/web/`  
✅ **Branding**: Logo and colors updated  
✅ **Web Compatibility**: Share function fixed  

**Ready to deploy!** 🚀

---

## 🎁 Quick Deploy Script

Save this as `deploy-web.sh` in your repo root:

```bash
#!/bin/bash

echo "🎄 Building DrawJoy for web..."
cd flutter_app
flutter clean
flutter pub get
flutter build web --release

echo ""
echo "✅ Build complete!"
echo ""
echo "📦 Deployment options:"
echo ""
echo "1. Drag & Drop to Netlify:"
echo "   Visit: https://app.netlify.com/drop"
echo "   Drag folder: flutter_app/build/web"
echo ""
echo "2. CLI Deploy:"
echo "   cd flutter_app/build/web"
echo "   netlify deploy --prod"
echo ""
echo "3. Open build folder:"
echo "   xdg-open flutter_app/build/web"
echo ""
```

Make executable:
```bash
chmod +x deploy-web.sh
./deploy-web.sh
```

---

## 🌟 You're All Set!

Your web app is ready to deploy. Choose your method:

1. **Quickest**: Drag & drop to https://app.netlify.com/drop (5 min)
2. **Best for updates**: Netlify CLI (10 min setup)
3. **Most automated**: GitHub integration (15 min setup)

All are free for your use case! 🎉
