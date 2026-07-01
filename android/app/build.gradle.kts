plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.wheel.wheel_of_fortune"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Включаем десугаринг для плагина уведомлений
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.wheel.wheel_of_fortune"
        minSdk = 28
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // С кавычками и равно для Kotlin DSL
        
        manifestPlaceholders += mapOf(
            "enableAliases" to "true",
            "isDebug" to "false"
        )
    }


    buildTypes {
        release {
           signingConfig = signingConfigs.getByName("debug")
           isMinifyEnabled = true 
           isShrinkResources = true
           proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Оставляем пустым, как у тебя и было
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
    dependencies {
        implementation(platform("com.google.firebase:firebase-bom:34.15.0"))
        implementation("com.google.firebase:firebase-analytics")
        implementation("com.google.android.play:core:1.10.3")
        // Подключаем сам десугаринг через правильный синтаксис функции
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    }

flutter {
    source = "../.."
}

