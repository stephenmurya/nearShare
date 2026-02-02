plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.crescence.nearshare"
    // Use 35 to ensure compatibility with modern Firebase
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    // This enables the BuildConfig generation required by Cloud Firestore
    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.crescence.nearshare"
        
        // Firebase Auth and Firestore now require minSdk 23+
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
        
        // Recommended for Firebase projects to prevent 64k method limit crashes
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
}
