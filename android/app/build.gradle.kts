plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.mikepenz.aboutlibraries.plugin")
}

android {
    namespace = "com.example.uplift_reconnect"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.uplift_reconnect"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Gradle keeps no record of what the libraries it pulls in are licensed under,
// and Flutter's licence page only knows about Dart packages. This writes the
// Android half of what the app ships as attribution; see
// `tool/update_native_licenses.dart` for the rest and for how to regenerate.
aboutLibraries {
    // Every build type is collected by default, which lists each Flutter engine
    // artefact three times over. Only the release dependencies ship.
    filterVariants = arrayOf("release")
    prettyPrint = true
}
