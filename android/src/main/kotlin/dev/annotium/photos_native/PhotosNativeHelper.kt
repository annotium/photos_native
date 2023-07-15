// Copyright Annotium 2023

package dev.annotium.photos_native

import android.content.Context
import android.os.Environment
import java.io.File

object PhotosNativeHelper {
    private const val IMAGES = "images"

    fun getExternalCachedPath(context: Context): File {
        val externalCachedPath = File(context.externalCacheDir, IMAGES)
        clearCachePath(externalCachedPath)

        return externalCachedPath
    }

    private fun clearCachePath(cachedPath: File) {
        try {
            if (cachedPath.exists()) {
                cachedPath.deleteRecursively()
            }
        }
        catch (e: Exception) {
        }

        cachedPath.mkdir()
    }

    fun prepareExternalStorageFolder(folder: String?): File {
        @Suppress("DEPRECATION")
        val dir = if (folder.isNullOrEmpty()) {
            Environment.getExternalStorageDirectory()
        }
        else{
            File(Environment.getExternalStorageDirectory(), folder)
        }

        if (!dir.exists()) {
            dir.mkdirs()
        }

        return dir
    }
}
