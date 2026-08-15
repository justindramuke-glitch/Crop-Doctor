# Crop Doctor — Real Android Build Project

This repository is prepared so a cloud build can produce an actual Android APK.

## Easiest phone-only route

1. Create a GitHub account if you do not have one.
2. Create a new repository named `crop-doctor`.
3. Upload all files from this project.
4. Commit them to the `main` branch.
5. Open the repository's **Actions** tab.
6. Run **Build Crop Doctor APK**.
7. When the workflow finishes, open the run and download the `crop-doctor-apk` artifact.
8. Extract the artifact and install `app-release.apk` on your Android phone.

The workflow automatically creates the Android platform files, installs Flutter, gets dependencies, analyzes the project, and builds the release APK.

Flutter's official documentation confirms that `flutter build apk` produces an APK and documents APK installation/release signing. For a Play Store release, a proper signing key should be configured rather than relying on an unsigned/debug build.
