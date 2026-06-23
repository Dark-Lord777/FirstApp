plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.wheel.wheel_of_fortune"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.wheel.wheel_of_fortune"
        minSdk = flutter.minSdkVersion
        targetSdk = 36  // ← ЖЕСТКО СТАВИМ 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders += mapOf(
            "enableAliases" to "true",
            "isDebug" to "false"
        )
    }

    buildTypes {
        release {
           signingConfig = signingConfigs.getByName("debug")
           manifestPlaceholders += mapOf(
               "enableAliases" to "true",
               "isDebug" to "false"
           )
        }
        debug {
            //ignore trial errors of anifest related with plagin bee_dynamic_launcher
            //really. i really i have no words fux....
            manifestPlaceholders += mapOf(
                    "enableAliases" to "false", 
                    "isDebug" to "true"
                )
            }
    }
         sourceSets {
            getByName("main") {
                manifest.srcFile("src/main/AndroidManifest.xml")
            }
            getByName("debug") {
                manifest.srcFile("src/debug/AndroidManifest.xml")
            }
            getByName("release") {
                manifest.srcFile("src/release/AndroidManifest.xml")
            }
        }


}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
