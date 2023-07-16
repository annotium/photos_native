// Copyright Annotium 2023

package dev.annotium.photos_native

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.os.Build
import android.os.Build.VERSION.SDK_INT
import android.os.Parcelable


fun PackageManager.getPackageInfoCompat(packageName: String, flags: Int = 0): PackageInfo = when {
    SDK_INT >= Build.VERSION_CODES.TIRAMISU ->
        getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(flags.toLong()))
    else ->
        @Suppress("DEPRECATION") getPackageInfo(packageName, flags)
}

fun PackageManager.queryIntentActivitiesCompat(intent: Intent, flags: Int = 0): List<ResolveInfo> = when {
    SDK_INT >= Build.VERSION_CODES.TIRAMISU ->
        queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(flags.toLong()))
    else ->
        @Suppress("DEPRECATION") queryIntentActivities(intent, flags)
}

inline fun <reified T : Parcelable> Intent.parcelable(key: String): T? = when {
    SDK_INT >= Build.VERSION_CODES.TIRAMISU -> getParcelableExtra(key, T::class.java)
    else -> @Suppress("DEPRECATION") getParcelableExtra(key) as? T
}
