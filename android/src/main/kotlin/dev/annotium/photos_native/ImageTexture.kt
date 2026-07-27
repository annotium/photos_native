// Copyright Annotium 2022

package dev.annotium.photos_native

import android.graphics.Bitmap
import android.graphics.Paint
import android.util.Log
import android.view.Surface
import io.flutter.view.TextureRegistry

class ImageTexture(val width: Int, val height: Int, registry: TextureRegistry) {
	private val lock = Any()
	private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
	private var surface: Surface?
	var textureId: Long = -1

	init {
		textureEntry = registry.createSurfaceTexture()
		surface = Surface(textureEntry!!.surfaceTexture())
	}

	fun post(bitmap: Bitmap): Long = synchronized(lock) {
		val safeSurface = surface
		if (safeSurface == null || !safeSurface.isValid) {
			return -1
		}

		textureEntry?.let { entry ->
			entry.surfaceTexture().setDefaultBufferSize(width, height)
			val canvas = safeSurface.lockCanvas(null)
			canvas.drawBitmap(bitmap, 0f, 0f, Paint())
			safeSurface.unlockCanvasAndPost(canvas)
			textureId = entry.id()
		}

		return textureId
	}

	fun dispose() = synchronized(lock) {
		surface?.release()
		surface = null

		textureEntry?.release()
		textureEntry = null
	}
}