// Copyright Annotium 2021

package dev.annotium.photos_native

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager.MATCH_DEFAULT_ONLY
import android.net.Uri
import android.os.Build

object IntentHelper {
    fun createChooserIntent(context: Context, uri: Uri, title: String): Intent?
    {
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = Constants.Mime.JPG
        }

        val curPackageName = context.packageName
        val chooserIntent: Intent?

        val compatibleActivities = context.packageManager.queryIntentActivities(
            shareIntent, MATCH_DEFAULT_ONLY
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val excludedComponents = arrayListOf<ComponentName>()
            for (resInfo in compatibleActivities) {
                val packageName = resInfo.activityInfo.packageName
                if (packageName.equals(curPackageName, true)) {
                    excludedComponents.add(
                        ComponentName(packageName, resInfo.activityInfo.name)
                    )
                }

                context.grantUriPermission(
                    packageName,
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )
            }

            shareIntent.apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                setDataAndType(uri, Constants.Mime.JPG)
                putExtra(Intent.EXTRA_STREAM, uri)
            }

            chooserIntent = Intent.createChooser(shareIntent, title).apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(
                    Intent.EXTRA_EXCLUDE_COMPONENTS,
                    excludedComponents.toTypedArray()
                )
            }
        }
        else {
            val shareIntentList = arrayListOf<Intent>()
            for (resInfo in compatibleActivities) {
                val packageName = resInfo.activityInfo.packageName
                if (packageName.equals(curPackageName, true)) continue

                shareIntentList.add(
                    createShareIntent(packageName, resInfo.activityInfo.name, uri)
                )
            }

            chooserIntent = Intent.createChooser(Intent(), title).apply {
                putExtra(
                    Intent.EXTRA_INITIAL_INTENTS,
                    shareIntentList.toTypedArray()
                )
            }
        }

        chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        return chooserIntent
    }

    private fun createShareIntent(packageName: String, cls: String, uri: Uri): Intent {
        return Intent(Intent.ACTION_SEND).apply {
            component = ComponentName(packageName, cls)
            type = Constants.Mime.JPG
            `package` = packageName
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            putExtra(Intent.EXTRA_STREAM, uri)
        }
    }
}