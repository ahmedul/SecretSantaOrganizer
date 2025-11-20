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
