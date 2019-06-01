#!/bin/bash
set -e 

# Basic template create, rnfb install, link
\rm -fr rnfbdemo
react-native init rnfbdemo
cd rnfbdemo
npm i react-native-firebase
cd ios
cp ../../Podfile .
pod install
cd ..
react-native link react-native-firebase

# Perform the minimal edit to integrate it on iOS
sed -i -e $'s/AppDelegate.h"/AppDelegate.h"\\\n#import "Firebase.h"/' ios/rnfbdemo/AppDelegate.m
rm -f ios/rnfbdemo/AppDelegate.m??
sed -i -e $'s/RCTBridge \*bridge/[FIRApp configure];\\\n  RCTBridge \*bridge/' ios/rnfbdemo/AppDelegate.m
rm -f ios/rnfbdemo/AppDelegate.m??

# Copy the Firebase config files in
cp ../GoogleService-Info.plist ios/rnfbdemo/
cp ../google-services.json android/app/

# Copy in a project file that is pre-constructed - no way to patch it cleanly that I've found
# To build it do this:
# 1.  stop this script here (by uncommenting the exit line)
# 2.  open the .xcworkspace created by running the script to this point
# 3.  alter the bundleID to com.rnfbdemo
# 4.  alter the target to 'both' instead of iPhone only
# 5.  "add files to " project and select rnfbdemo/GoogleService-Info.plist for rnfbdemo and rnfbdemo-tvOS
#exit 1
rm -f ios/rnfbdemo.xcodeproj/project.pbxproj
cp ../project.pbxproj ios/rnfbdemo.xcodeproj/

# Add our messaging dependency for Java
sed -i -e $'s/dependencies {/dependencies {\\\n    implementation "com.google.firebase:firebase-messaging:18.0.0"/' android/app/build.gradle
rm -f android/app/build.gradle??

# Add shortcut badging for Java, because people like it even though shortcut badging on Android is discouraged and is terrible and basically unsupportable
# (Pixel Launcher won't do it, launchers have to grant permissions, it is vendor specific, Material Design says no, etc etc)
sed -i -e $'s/dependencies {/dependencies {\\\n    implementation "me.leolin:ShortcutBadger:1.1.22@aar"/' android/app/build.gradle
rm -f android/app/build.gradle??

# Set the Java application up for multidex (needed for API<21 w/Firebase)
sed -i -e $'s/dependencies {/dependencies {\\\n    implementation "com.android.support:multidex:1.0.3"/' android/app/build.gradle
rm -f android/app/build.gradle??
sed -i -e $'s/import android.app.Application;/import android.support.multidex.MultiDexApplication;/' android/app/src/main/java/com/rnfbdemo/MainApplication.java
rm -f android/app/src/main/java/com/rnfbdemo/MainApplication.java??
sed -i -e $'s/extends Application/extends MultiDexApplication/' android/app/src/main/java/com/rnfbdemo/MainApplication.java
rm -f android/app/src/main/java/com/rnfbdemo/MainApplication.java??

# Run the thing for iOS
react-native run-ios

# Run it for Android (assumes you have an android emulator running)
USER=`whoami`
echo "sdk.dir=/Users/$USER/Library/Android/sdk" > android/local.properties
npx react-native run-android