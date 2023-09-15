// Copyright Annotium 2021

package dev.annotium.photos_native

import android.content.Context
import android.net.Uri
import android.util.Log
import com.bumptech.glide.Glide
import com.bumptech.glide.load.DecodeFormat
import io.flutter.view.TextureRegistry
import kotlinx.coroutines.*
import java.io.IOException
import java.util.concurrent.Executors

class MethodCallHandlerImpl
{
    private val job = Job()
    private val mainScope = CoroutineScope(Dispatchers.Main + job)
    private val poolDispatcher = Executors.newFixedThreadPool(
        (Runtime.getRuntime().availableProcessors() - 1).coerceAtLeast(1)
    ).asCoroutineDispatcher()

    private val textureMap = HashMap<String, ImageTexture>()

    fun cancel() {
        clearTexture()
        poolDispatcher.cancel()
		job.cancel()
	}

    fun queryAlbums(context: Context, title: String, result: ResultHandler)
    {
        mainScope.launch {
            Log.d(Constants.TAG, "[${Thread.currentThread().name}] Query album")
            val galleryResult = PhotoManager.getInstance().queryAlbums(
                context,
                title
            )

            galleryResult.onSuccess {
                result.success(it.toMessageCodec())
            }
            .onFailure {
                result.error(
                    Constants.Errors.UNKNOWN,
                    it.localizedMessage,
                    it.stackTrace
                )
            }
        }
    }

    fun getBytes(context: Context, id: String, resultHandler: ResultHandler)
    {
        val uri = ContentHelper.getUriWithId(id.toLong())
        getBytesFromUri(context, uri, resultHandler)
    }

    fun getPixels(context: Context, id: String, maxSize: Int, resultHandler: ResultHandler)
    {
        val uri = ContentHelper.getUriWithId(id.toLong())
        getPixelsFromUri(context, uri, maxSize, resultHandler)
    }

    fun getThumbnail(
        context: Context,
        uri: Uri,
        width: Int,
        height: Int,
        resultHandler: ResultHandler)
    {
        val request = Glide.with(context)
            .asBitmap()
            .load(uri)
            .centerCrop()
            .override(width, height)

        mainScope.launch {
            val result = PhotoManager.getInstance().loadImageData(
                request.submit()
            )

            result.onSuccess {
                resultHandler.success(it.toMessageCodec())
            }
                .onFailure {
                    resultHandler.error(
                        Constants.Errors.UNKNOWN,
                        it.localizedMessage,
                        it.stackTrace
                    )
                }
        }
    }

    fun getBytesFromUri(context: Context, uri: Uri, resultHandler: ResultHandler) {

        mainScope.launch {
            try {
                val bytes = PhotoManager.getInstance().readBytes(context, uri)
                if (bytes == null) {
                    resultHandler.error(
                        Constants.Errors.UNKNOWN
                    )
                } else {
                    resultHandler.success(bytes)
                }

            } catch (e: Exception) {
                resultHandler.error(
                    Constants.Errors.UNKNOWN,
                    e.localizedMessage,
                    e.stackTrace
                )
            }

        }
    }

    fun getPixelsFromUri(context: Context, uri: Uri, maxSize: Int, resultHandler: ResultHandler)
    {
        val request = Glide.with(context)
            .asBitmap()
            .load(uri)
            .centerInside()
            .format(DecodeFormat.PREFER_ARGB_8888)
            .override(maxSize)

        mainScope.launch {
            val target = request.submit()
            val result = PhotoManager.getInstance().loadImageData(target)

            result.onSuccess {
                resultHandler.success(it.toMessageCodec())
            }
            .onFailure {
                resultHandler.error(
                    Constants.Errors.UNKNOWN,
                    it.localizedMessage,
                    it.stackTrace
                )
            }

            target.cancel(true)
        }
    }

    fun save(
        context: Context,
        data: ByteArray,
        width: Int,
        height: Int,
        mime: String,
        album: String?,
        quality: Int,
        resultHandler: ResultHandler,
    ) {
        mainScope.launch {
            val saveResult = PhotoManager.getInstance().save(
                    context,
                    data,
                    width,
                    height,
                    mime,
                    album,
                    quality,
                    poolDispatcher
                )


            saveResult.onSuccess {
                resultHandler.success(true)
            }
            .onFailure {
                resultHandler.error(
                    Constants.Errors.UNKNOWN,
                    it.localizedMessage,
                    it.stackTrace
                )
            }
        }
    }

    fun saveFile(
        context: Context,
        data: ByteArray,
        width: Int,
        height: Int,
        mime: String,
        quality: Int,
        path: String,
        resultHandler: ResultHandler,
    ) {
        mainScope.launch {
            val saveResult = PhotoManager.getInstance().saveFile(
                context,
                data,
                width,
                height,
                mime,
                quality,
                path,
                poolDispatcher
            )


            saveResult.onSuccess {
                resultHandler.success(true)
            }
                .onFailure {
                    resultHandler.error(
                        Constants.Errors.UNKNOWN,
                        it.localizedMessage,
                        it.stackTrace
                    )
                }
        }
    }

    fun encode(
        data: ByteArray,
        width: Int,
        height: Int,
        mime: String,
        quality: Int,
        resultHandler: ResultHandler,
    ) {
        mainScope.launch {
            val result = PhotoManager.getInstance().encode(
                data,
                width,
                height,
                mime,
                quality,
                poolDispatcher
            )

            result.onSuccess {
                resultHandler.success(it)
            }
                .onFailure {
                    resultHandler.error(
                        Constants.Errors.UNKNOWN,
                        it.localizedMessage,
                        it.stackTrace
                    )
                }
        }
    }

    fun share(
        context: Context,
        data: ByteArray,
        width: Int,
        height: Int,
        title: String,
        resultHandler: ResultHandler
    ) {
        mainScope.launch {
            val uriResult = PhotoManager.getInstance().generateDataUri(
                context,
                data,
                width,
                height,
                Constants.DEFAULT_QUALITY,
                poolDispatcher
            )

            uriResult.onSuccess { uri ->
                try {
                    val chooserIntent = IntentHelper.createChooserIntent(context, uri, title)

                    if (chooserIntent?.resolveActivity(context.packageManager) == null) {
                        resultHandler.error(
                            Constants.Errors.UNKNOWN,
                            "Share image failed",
                            null
                        )
                    }
                    else {
                        context.startActivity(chooserIntent)
                        resultHandler.success(true)
                    }
                }
                catch (exception: Exception) {
                    resultHandler.error(
                        Constants.Errors.UNKNOWN,
                        "Share image failed",
                        null
                    )
                }
            }
            .onFailure {
                resultHandler.error(Constants.Errors.UNKNOWN, it.toString(), null)
            }
        }
    }

    fun acquireTexture(
        context: Context,
        textureRegistry: TextureRegistry,
        id: String,
        width: Int,
        height: Int,
        resultHandler: ResultHandler)
    {
		if (textureMap.containsKey(id)) {
			resultHandler.success(textureMap[id]!!.textureId)
			return
		}

        val uri = ContentHelper.getUriWithId(id.toLong())
        val request = Glide.with(context)
            .asBitmap()
            .format(DecodeFormat.PREFER_RGB_565)
            .load(uri)
            .centerCrop()
            .override(width, height)

        mainScope.launch {
            val target = request.submit()
            val result = PhotoManager.getInstance().loadImageOnBackgroundThread(
                target
            )

            result.onSuccess { bitmap ->
                val texture = ImageTexture(width, height, textureRegistry)

                try {
                    if (texture.post(bitmap) < 0) {
                        texture.dispose()
                        resultHandler.error(Constants.Errors.UNKNOWN)
                    }
                    else {
                        val textureId = texture.textureId
                        textureMap[id] = texture
                        resultHandler.success(textureId)
                    }
                }
                catch (ex: Exception) {
                    texture.dispose()
                    resultHandler.error(
                        Constants.Errors.UNKNOWN,
                        ex.localizedMessage,
                        ex.stackTrace)
                }
            }
            .onFailure {
                Log.e(Constants.TAG,it.localizedMessage ?: "")
                resultHandler.error(
                    Constants.Errors.UNKNOWN,
                    it.localizedMessage,
                    it.stackTrace
                )
            }

            Glide.with(context).clear(target)
        }
    }

    fun releaseTexture(id: String) {
        // Log.d(Constants.TAG, "Release texture: $id")
        textureMap.remove(id)?.dispose()
    }

    private fun clearTexture()
    {
        textureMap.forEach {
            it.value.dispose()
        }
        textureMap.clear()
    }

//    private fun loadTarget(target: FutureTarget<Bitmap>, resultHandler: ResultHandler) {
//        try {
//            val bitmap = target.get()
//            val data = ByteArray(bitmap.allocationByteCount)
//            bitmap.copyPixelsToBuffer(ByteBuffer.wrap(data))
//            val phDesc = PHImageDescriptor(bitmap.width, bitmap.height, data)
//            resultHandler.success(phDesc.toMessageCodec())
//        } catch (e: Exception) {
//            Log.e(Constants.Errors.UNKNOWN, e.localizedMessage ?: "")
//            resultHandler.error(Constants.Errors.UNKNOWN, e.localizedMessage, e.stackTrace)
//        }
//
//        target.cancel(false)
//    }
}