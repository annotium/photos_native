// Copyright Annotium 2021

package dev.annotium.photos_native

import android.content.ContentUris
import android.net.Uri
import android.os.Build
import android.provider.MediaStore

object ContentHelper {
    const val DATE_ADDED_SORTBY = "${MediaStore.Files.FileColumns.DATE_ADDED} DESC "
    private val BUCKET_ID: String
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Images.Media.BUCKET_ID
        } else {
            MediaStore.Images.ImageColumns.BUCKET_ID
        }

    private val BUCKET_DISPLAY_NAME: String
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME
        } else {
            MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME
        }

    val ALBUM_PROJECTIONS = arrayOf(
        BUCKET_ID,
        BUCKET_DISPLAY_NAME,
        MediaStore.Images.Media._ID
    )

    val externalContentUri: Uri
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        }

    val externalPrimaryContentUri: Uri
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        }

    fun getUriWithId(id: Long): Uri {
        return ContentUris.withAppendedId(externalContentUri, id)
    }
}