// Copyright Annotium 2021

package dev.annotium.photos_native

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Browser
import java.lang.Exception

class UrlLauncher
{
    enum class LaunchStatus {
        SUCCESS,
        FAILED,
        ACTIVITY_NOT_FOUND
    }

    fun launch(activity: Activity, url: String?, headersBundle: Bundle?): LaunchStatus {
        val launchIntent: Intent = Intent(Intent.ACTION_VIEW)
                .setData(Uri.parse(url))
                .putExtra(Browser.EXTRA_HEADERS, headersBundle)

        return try {
            activity.startActivity(launchIntent)
            LaunchStatus.SUCCESS
        } catch (e: ActivityNotFoundException) {
            LaunchStatus.ACTIVITY_NOT_FOUND
        } catch (e: Exception) {
            LaunchStatus.FAILED
        }
    }
}