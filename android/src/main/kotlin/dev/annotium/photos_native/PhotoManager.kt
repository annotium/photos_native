// Copyright Annotium 2021

package dev.annotium.photos_native

import android.util.Log
import android.content.*
import android.database.Cursor
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import com.bumptech.glide.request.FutureTarget
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.OutputStream
import java.nio.ByteBuffer
import kotlin.coroutines.CoroutineContext

class PhotoManager {
    companion object {
        @Volatile private var pmInstance: PhotoManager? = null
        fun getInstance(): PhotoManager =
            pmInstance ?: synchronized(this) {
                pmInstance ?: PhotoManager().also { pmInstance = it }
            }
    }

    suspend fun loadImageOnBackgroundThread(
        target: FutureTarget<Bitmap>,
        context: CoroutineContext = Dispatchers.Default):
            Result<Bitmap> = withContext(context)
    {
        val result = try {
            val bitmap = target.get()
            Result.success(bitmap)
        } catch (e: Exception) {
            Log.e(Constants.TAG,e.localizedMessage ?: "")
            Result.failure(e)
        }

        return@withContext result
    }

    suspend fun loadImageData(target: FutureTarget<Bitmap>,context: CoroutineContext = Dispatchers.Default):
            Result<PHImageDescriptor> = withContext(context)
    {
        val result = try {
            val bitmap = target.get()
            val buffer = ByteBuffer.allocate(bitmap.allocationByteCount)
            bitmap.copyPixelsToBuffer(buffer)

            val data = buffer.array()

            Result.success(
                PHImageDescriptor(bitmap.width, bitmap.height, data)
            )
        } catch (e: Exception) {
            Log.e(Constants.TAG,e.localizedMessage ?: "")
            Result.failure(e)
        } finally {
            target.cancel(false)
        }

        return@withContext result
    }

    suspend fun queryAlbums(
        appContext: Context,
        allPhotosTitle: String,
        context: CoroutineContext = Dispatchers.IO
    ): Result<PHGallery> = withContext(context) {
        try {
            val cursor = appContext.contentResolver.query(
                ContentHelper.externalContentUri,
                ContentHelper.ALBUM_PROJECTIONS,
                null,
                null,
                ContentHelper.DATE_ADDED_SORTBY
            ) ?: return@withContext Result.failure(Exception(Constants.Errors.UNKNOWN))

            val gallery = PHGallery()
            val allIds = mutableListOf<String>()
            val allPhotosAlbum = PHAlbum(Constants.Album.AllPhotos, allPhotosTitle, allIds)
            gallery.albums.add(allPhotosAlbum)
            if (!cursor.moveToFirst()) {
                return@withContext Result.success(gallery)
            }

            cursor.use {
                val bucketIdColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_ID)
                val idColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
                val bucketDisplayNameColumn = it.getColumnIndexOrThrow(
                    MediaStore.Images.Media.BUCKET_DISPLAY_NAME
                )

                val albums = mutableMapOf<String, PHAlbum>()
                do {
                    loadCursor(
                        it,
                        idColumn,
                        bucketDisplayNameColumn,
                        bucketIdColumn,
                        albums,
                        allPhotosAlbum)
                } while (it.moveToNext())

                gallery.albums += albums.values.filter { album -> album.items.isNotEmpty() }
            }

            return@withContext Result.success(gallery)
        }
        catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    private fun loadCursor(
            cursor: Cursor,
            idColumn: Int,
            bucketDisplayNameColumn: Int,
            bucketIdColumn: Int,
            albums: MutableMap<String, PHAlbum>,
            allPhotosAlbum: PHAlbum
    )
    {
        try {
            val bucketId = cursor.getLong(bucketIdColumn)
            val isBucketIdValid = bucketId >= 0

            var album: PHAlbum? = if (isBucketIdValid) {
                albums.getOrElse(bucketId.toString()) { null }
            }
            else {
                null
            }

            if (isBucketIdValid && album == null) {
                val albumTitle = cursor.getString(bucketDisplayNameColumn)
                if (albumTitle != null) {
                    album = PHAlbum(bucketId.toString(), albumTitle)
                    albums[bucketId.toString()] = album
                }
            }

            val id = cursor.getLong(idColumn).toString()
            if (isBucketIdValid && album != null) {
                album.items += id
            }

            allPhotosAlbum.items += id
        }
        catch (e: Exception) {
            Log.e(Constants.TAG, e.toString())
        }
    }

    suspend fun save(
        appContext: Context,
        data: ByteArray,
        width: Int,
        height: Int,
        mime: String,
        quality: Int,
        context: CoroutineContext = Dispatchers.IO):
            Result<Uri> = withContext(context)
    {
        Log.d(Constants.TAG, "Saving $mime")

        val contentResolver = appContext.contentResolver
        val curTime = System.currentTimeMillis()
        val timestamp = curTime / 1000
        val ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mime)
        val imageName = "${Constants.DEFAULT_NAME}$timestamp.$ext"

        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, imageName)
            put(MediaStore.Images.Media.TITLE, imageName)
            put(MediaStore.Images.Media.DESCRIPTION, "Annotium Photo Annotation $timestamp")
            put(MediaStore.Images.Media.MIME_TYPE, mime)
            put(MediaStore.Images.Media.DATE_ADDED, timestamp)
            put(MediaStore.MediaColumns.DATE_MODIFIED, timestamp)
            put(MediaStore.Images.Media.DATE_TAKEN, curTime)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
//                put(MediaStore.Images.Media.BUCKET_DISPLAY_NAME, Constants.ANNOTIUM)
                put(MediaStore.Images.Media.RELATIVE_PATH, Constants.PICTURES_PATH)
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            else {
                val dir = AnnotiumHelper.prepareExternalStorageFolder(Constants.PICTURES_PATH)
                @Suppress("DEPRECATION")
                put(MediaStore.Images.Media.DATA, File(dir, imageName).path)
            }
        }

        // Insert file into MediaStore
        try {
            val galleryFileUri = contentResolver.insert(
                ContentHelper.externalPrimaryContentUri, values
            ) ?: return@withContext Result.failure(Exception("Failed to insert image collection"))

            contentResolver.openOutputStream(galleryFileUri).use { outputStream ->
                if (outputStream == null) {
                    return@withContext Result.failure(Exception(Constants.Errors.UNKNOWN))
                }

                toStream(outputStream, data, width, height, quality, mime)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                contentResolver.update(galleryFileUri, values, null, null)
            }

            return@withContext Result.success(galleryFileUri)
        }
        catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    suspend fun encode(
        data: ByteArray,
        width: Int,
        height: Int,
        mime: String,
        quality: Int,
        context: CoroutineContext = Dispatchers.IO):
            Result<ByteArray> = withContext(context) {
        try {
            ByteArrayOutputStream().use { outputStream ->
                toStream(outputStream, data, width, height, quality, mime)
                val buffer = outputStream.toByteArray()

                return@withContext Result.success(buffer)
            }
        } catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }


    suspend fun saveDocument(
        appContext: Context,
        data: ByteArray,
        width: Int,
        height: Int,
        mime: String,
        quality: Int,
        directory: String?,
        path: String?,
        overwrite: Boolean = false,
        context: CoroutineContext = Dispatchers.IO):
            Result<Uri> = withContext(context)
    {
        Log.d(Constants.TAG, "Saving file $path $mime")

        val contentResolver = appContext.contentResolver

        try {
            val timestamp = System.currentTimeMillis() / 1000
            val imageName = if (overwrite && !path.isNullOrEmpty()) {
                val fileUri = Uri.parse(path)
                val curFile = File(fileUri.path.toString())

                if (curFile.exists()) {
                    curFile.delete()
                }

                resolveName(curFile.nameWithoutExtension, timestamp)
            } else {
                "${Constants.DEFAULT_NAME}-$timestamp"
            }

            val ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mime)
            val fileName = "$imageName.$ext"

            val file = File(directory!!).resolve(fileName)
            val uri = Uri.fromFile(file)

            contentResolver.openOutputStream(uri).use { outputStream ->
                if (outputStream == null) {
                    return@withContext Result.failure(Exception(Constants.Errors.UNKNOWN))
                }

                toStream(outputStream, data, width, height, quality, mime)
            }

            return@withContext Result.success(uri)
        }
        catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    suspend fun generateDataUri(
        appContext: Context,
        data: ByteArray,
        width: Int,
        height: Int,
        quality: Int,
        context: CoroutineContext = Dispatchers.IO
    ): Result<Uri> = withContext(context)
    {
        val contentResolver = appContext.contentResolver
        val cachedPath = AnnotiumHelper.getExternalCachedPath(appContext)
        val addedDate = System.currentTimeMillis() / 1_000
        val imageName = Constants.DEFAULT_NAME + addedDate + Constants.Extension.JPG
        val file = File(cachedPath, imageName)

        try {
            contentResolver.openOutputStream(Uri.fromFile(file)).use { outputStream ->
                if (outputStream == null) {
                    return@withContext Result.failure(Exception(Constants.Errors.UNKNOWN))
                }

                toStream(outputStream, data, width, height, quality)
            }

            val providerId = appContext.packageName + ".photos_native.fileprovider"
            return@withContext Result.success(
                FileProvider.getUriForFile(appContext, providerId, file)
            )
        }
        catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    private fun toStream(
        outputStream: OutputStream,
        data: ByteArray,
        width: Int,
        height: Int,
        quality: Int,
        mime: String = Constants.Mime.JPG)
    {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).apply {
            this.copyPixelsFromBuffer(ByteBuffer.wrap(data))
        }

        val format = getCompressFormat(mime, quality)
        bitmap.compress(format, quality, outputStream)
        outputStream.flush()
        bitmap.recycle()
    }

    suspend fun delete(
        appContext: Context,
        ids: List<String>,
        context: CoroutineContext = Dispatchers.IO
    ): Result<Int> = withContext(context)
    {
        if (ids.isEmpty()) {
            return@withContext Result.success(0)
        }

        val where = ids.joinToString(",") { "?" }

        try {
            val count = appContext.contentResolver.delete(
                ContentHelper.externalContentUri,
                "${MediaStore.MediaColumns._ID} in ($where)", ids.toTypedArray()
            )

            return@withContext Result.success(count)
        }
        catch (e: Exception) {
            return@withContext Result.failure(e)
        }
    }

    private fun getCompressFormat(mime: String, quality: Int): Bitmap.CompressFormat {
        return when {
            mime.equals(Constants.Mime.PNG, true) -> Bitmap.CompressFormat.PNG
            mime.equals(Constants.Mime.WEBP, true) -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    if (quality < Constants.HIGHEST_QUALITY) {
                        Bitmap.CompressFormat.WEBP_LOSSY
                    }
                    else {
                        Bitmap.CompressFormat.WEBP_LOSSLESS
                    }
                }
                else {
                    @Suppress("DEPRECATION")
                    Bitmap.CompressFormat.WEBP
                }
            }
            else -> Bitmap.CompressFormat.JPEG
        }
    }

    private fun resolveName(name: String, timestamp: Long): String {
        val parts = name.split("-")
        if (parts.size < 2) {
            return "${name}-$timestamp"
        }

        val newParts = parts.mapIndexed { idx, value ->
            if (idx == 1) {
                ((value.toLongOrNull() ?: timestamp) + 1).toString()
            } else value
        }

        return newParts.joinToString("-")
    }

//    @ExperimentalCoroutinesApi
//    private suspend fun scanFilePath(
//        path: String,
//        mimeType: String,
//    ): Result<Uri> {
//        return suspendCancellableCoroutine { continuation ->
//            MediaScannerConnection.scanFile(
//                appContext,
//                arrayOf(path),
//                arrayOf(mimeType)
//            ) { _, scannedUri ->
//                if (scannedUri != null) {
//                    continuation.resume(Result.success(scannedUri), null)
//                } else {
//                    continuation.resume(
//                        Result.failure(Exception(Constants.Errors.UNKNOWN)),
//                        null
//                    )
//                }
//            }
//        }
//    }
}