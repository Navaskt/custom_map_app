```markdown
# Flutter: Custom Map with Search (Google Maps + Places)

This Flutter example shows:
- A Google map (google_maps_flutter)
- A search box with autocomplete suggestions (Places API via google_place)
- Selecting a suggestion moves the map, adds a marker, and shows place info
- Tapping the map adds a custom marker

Prerequisites
- Flutter installed (stable)
- A Google Cloud Platform project with:
  - Maps SDK for Android enabled
  - Maps SDK for iOS enabled
  - Places API enabled
- An API key with those APIs allowed

Quick start
1. Create a new Flutter project (or place these files into a new project):
   flutter create custom_map_search
   cd custom_map_search

2. Replace the project's pubspec.yaml with the provided pubspec.yaml content (or add the dependencies).

3. Add lib/main.dart (replace any existing main.dart) with the provided file.

4. Replace the API key placeholder in lib/main.dart (kGoogleApiKey) with your API key.

Platform configuration (important)

Android
- Open android/app/src/main/AndroidManifest.xml and inside the <application> element add:
  <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_API_KEY_HERE"/>

iOS
- In ios/Runner/AppDelegate.swift (or AppDelegate.m for Obj-C), add:
  import GoogleMaps
  import GooglePlaces

  and inside application(_:didFinishLaunchingWithOptions:)
  GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
  GMSPlacesClient.provideAPIKey("YOUR_API_KEY_HERE")

Notes:
- Use the same API key for both Android and iOS; restrict the key using Application restrictions (Android package name + SHA1, iOS bundle id) and API restrictions (Maps SDK, Places API).
- If you prefer to avoid embedding the key in source, use secure storage or native runtime injection (not covered here).

Run
- Android:
  flutter run -d emulator-5554
- iOS:
  open ios/Runner.xcworkspace in Xcode, set signing, then run, or use:
  flutter run -d <device-id>

Next steps & extensions
- Add Place photos (call Place Details and render images)
- Save favorite places to local storage / backend
- Add directions/routing using Directions API
- Convert API key configuration to environment variables (flutter_dotenv) for safer management

Troubleshooting
- If the map is blank on Android: ensure the API key is in AndroidManifest and Maps SDK is enabled in GCP.
- If autocomplete returns zero suggestions: ensure Places API is enabled and key has Places permission.
- Check device logs (flutter run) for useful errors.
```