# Production Deployment Guide — THE KRISHA ARCHIVE

This document outlines the deployment roadmap, backend database setup, and native compilation prerequisites for deploying **THE KRISHA ARCHIVE** to production across iOS, Android, macOS, and Windows.

---

## 1. Supabase Backend Infrastructure Setup

### A. Run Database Migrations
1. Create a new project in the [Supabase Dashboard](https://supabase.com).
2. Navigate to the **SQL Editor** tab.
3. Copy the entire contents of [schema.sql](file:///c:/Users/Shadow/Desktop/The%20archive/schema.sql) and paste it into a new query sheet.
4. Click **Run** to execute the table creation script, RLS policies, index builds, and the timeline sync triggers.

### B. Configure Authentication Settings
1. Go to **Authentication > Providers > Email**.
2. Customize the Email Confirmation and Password Reset email template redirects to target the app's deep-link schema (`krishaarchive://`).
3. (Optional) For development testing, you can toggle off *Confirm Email* to allow instant mock registrations.

### C. Create Media Storage Bucket
1. Navigate to **Storage** in the Supabase menu.
2. Create a new Bucket named **`media`**.
3. Set the bucket privacy mode to **Public** (or keep private and specify authenticated RLS policies if you intend to sign media URL access tokens on the client).
4. Assign the following RLS policies to the bucket:
   - **SELECT**: Allow public read access (or authenticated users).
   - **INSERT/UPDATE**: `auth.uid() is not null` (Only authenticated users can upload media).

---

## 2. Flutter App Configuration & Compilation

### A. Configure Environment Variables
Pass your Supabase project credentials as Dart environment variables during the build phase:
```bash
# Run application in Dev mode
flutter run --dart-define=SUPABASE_URL=https://your-proj.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key-here

# Build release bundle
flutter build apk --dart-define=SUPABASE_URL=https://your-proj.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

### B. Biometrics Configuration (Platform specific)

#### 1. Android Configuration
Add the biometric permission to your `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```
Set the MainActivity to extend `FlutterFragmentActivity` instead of `FlutterActivity` to allow the biometric dialogue prompt to attach:
```kotlin
// android/app/src/main/kotlin/com/krishaarchive/krisha_archive/MainActivity.kt
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}
```

#### 2. iOS Configuration
Add the biometric access description to your `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>Authenticate using Face ID to unlock your secure vaults and archive database</string>
```

#### 3. macOS & Windows Desktop
- **macOS**: Enable target capability for "Keychain Sharing" in Xcode to allow `flutter_secure_storage` to write key materials to the native macOS keychain.
- **Windows**: Biometrics uses Windows Hello authentication natively; no special permissions are required.

---

## 3. Production Hardening Checklist

- [ ] **Zero-Knowledge Warning**: Display a prominent screen on first setup explaining that if the user forgets their Vault Password, their encrypted data cannot be recovered by the server.
- [ ] **Enable Obfuscation**: Always obfuscate production builds to protect the local encryption keys and APIs from decompilation:
  ```bash
  flutter build apk --obfuscate --split-debug-info=/<output-directory>
  ```
- [ ] **Enable RLS Policies**: Check that you do not have any "bypass RLS" flags toggled on tables containing user credentials.
