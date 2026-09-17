// Cricket8Bit Nearby Connections Plugin for Godot 4.x Android Export
// Uses Google Play Services Nearby Connections API with P2P_STAR strategy.
// Advertiser = Host, Discoverer = Challenger.

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.cricket8bit.nearby"
    compileSdk = 34

    defaultConfig {
        minSdk = 24
        targetSdk = 34
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    // Godot Android library (provided by the export template)
    compileOnly(fileTree("libs") { include("godot-lib.*.aar") })

    // Google Nearby Connections
    implementation("com.google.android.gms:play-services-nearby:19.3.0")
}
