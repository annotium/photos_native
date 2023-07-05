// Copyright Annotium 2022

package dev.annotium.photos_native

import android.graphics.Bitmap
import android.graphics.Paint
import android.util.Log
import android.view.Surface
import io.flutter.view.TextureRegistry

class ImageTexture(val width: Int, val height: Int, registry: TextureRegistry) {
	private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
	private var surface: Surface?
	//	private var bitmap: Bitmap? = null
	var textureId: Long = -1

	init {
//		this.bitmap = bitmap
		textureEntry = registry.createSurfaceTexture()
		surface = Surface(textureEntry!!.surfaceTexture())
	}

	fun post(bitmap: Bitmap): Long {
		if (surface == null || !surface!!.isValid) {
			return -1
		}

		val safeSurface = surface as Surface
		textureEntry?.let { entry ->
			entry.surfaceTexture().setDefaultBufferSize(width, height)
			val canvas = safeSurface.lockCanvas(null)
			canvas.drawBitmap(bitmap, 0f, 0f, Paint())
			safeSurface.unlockCanvasAndPost(canvas)
			textureId = entry.id()
			// Log.d(Constants.TAG, "Draw texture(${textureId})")
		}

		return textureId
	}

	fun dispose() {
		// Log.d(Constants.TAG, "Dispose texture($textureId)")

		surface?.release()
		surface = null

		textureEntry?.release()
		textureEntry = null

//		if(bitmap != null && !bitmap!!.isRecycled){
//			bitmap?.recycle()
//			bitmap = null
//		}
	}
}