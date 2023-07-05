// Copyright Annotium 2021

package dev.annotium.photos_native

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.PluginRegistry

typealias RequestFinishedHandler = (granted: Boolean) -> Unit

class PermissionHandler(private val activity: Activity):
    PluginRegistry.RequestPermissionsResultListener
{
    companion object {
        private val DefaultPermissions
            get() =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                    !Environment.isExternalStorageLegacy())
                    arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
                else
                    arrayOf(
                            Manifest.permission.READ_EXTERNAL_STORAGE,
                            Manifest.permission.WRITE_EXTERNAL_STORAGE
                    )
    }

    private var onRequestFinished: RequestFinishedHandler? = null

    val hasDefaultPermissions get() = hasSpecificPermissions(DefaultPermissions)

    fun requestPermissions(onRequestDone: (granted: Boolean) -> Unit) {
        onRequestFinished = onRequestDone

        if (hasSpecificPermissions(DefaultPermissions)) {
            onRequestDone.invoke(true)
        }
        else {
            ActivityCompat.requestPermissions(
                activity,
                DefaultPermissions,
                Constants.Permission.REQUEST_DEFAULT_PERMISSION
            )
        }
    }

    // This is invoked after the user chooses an option on the Android permission dialog
    // Note that the code to check the grant is simplified, if you request multiple
    // permissions you can't make the assumptions this makes.
    override fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<out String>,
            grantResults: IntArray): Boolean {
        when (requestCode) {
            Constants.Permission.REQUEST_DEFAULT_PERMISSION -> {
                var granted = grantResults.isNotEmpty()
				grantResults.forEach {
					granted = granted and (it == PackageManager.PERMISSION_GRANTED)
				}

				onRequestFinished?.invoke(granted)

                return true
            }
        }

        return false
    }

    private fun hasSpecificPermissions(permissions: Array<String>): Boolean {
        var granted = true
        permissions.forEach {
            granted = granted and hasSpecificPermission(it)
        }

        return granted
    }

    private fun hasSpecificPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(
            activity.application,
            permission
        ) == PackageManager.PERMISSION_GRANTED
    }
}