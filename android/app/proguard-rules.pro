# ProGuard Rules — Retinoscopy Simulator (JMR Technologies)
# Applied during release builds for code obfuscation and shrinking.

# Flutter engine — keep all Flutter classes intact
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep plugins
-keep class com.google.android.gms.** { *; }
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class dev.fluttercommunity.plus.shareplus.** { *; }
-keep class net.nfet.flutter.printing.** { *; }

# Keep annotation processors & attributes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int d(...);
}

# Suppress warnings for missing optional classes & Play Core deferred components
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn org.jspecify.annotations.**
