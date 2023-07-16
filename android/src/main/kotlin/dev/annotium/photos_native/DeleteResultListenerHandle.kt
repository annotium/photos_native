// Copyright Annotium 2021

package dev.annotium.photos_native

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.*
import android.os.Build
import android.os.Build.VERSION.SDK_INT
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.lang.Exception

object DeleteHelper {
	fun getHandle(activity: Activity): DeleteResultListenerHandle {
		return when {
			SDK_INT >= Build.VERSION_CODES.R -> DeleteResultListenerHandleR(activity)
			SDK_INT == Build.VERSION_CODES.Q -> DeleteResultListenerHandleQ(activity)
			else -> DeleteResultListenerHandle(activity)

		}
	}
}

// delete activity handle base class
open class DeleteResultListenerHandle(
	protected val activity: Activity): PluginRegistry.ActivityResultListener
{
	protected var resultHandler: ResultHandler? = null
	protected var deleteRequestCode: Int = 28_000

	override fun onActivityResult(
		requestCode: Int,
		resultCode: Int, data: Intent?
	): Boolean = false

	open fun delete(ids: List<String>, resultHandler: ResultHandler)
	{
		CoroutineScope(Dispatchers.IO).launch {
			val result = PhotoManager.getInstance().delete(activity, ids)
			result
				.onSuccess { count ->
					resultHandler.success(count)
				}
				.onFailure {
					resultHandler.error(
						Constants.Errors.UNKNOWN,
						it.toString(),
						it.stackTrace.toString()
					)
				}
		}
	}
}

// delete activity handle for Android Q
@RequiresApi(Build.VERSION_CODES.Q)
class DeleteResultListenerHandleQ(activity: Activity): DeleteResultListenerHandle(activity) {
	private val deleteItems = mutableSetOf<String>()
	private var deletingItem: String? = null
	private var deleted: Int = 0

	init {
		deleteRequestCode = 29_000
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
		if (requestCode == deleteRequestCode) {
			if (resultCode == Activity.RESULT_OK) {
				// User allow delete asset
				if (deletingItem != null) {
					delete(deletingItem!!)
				}
			}
			else {
				resultHandler?.success(deleted)
			}

			return true
		}

		return false
	}

	override fun delete(ids: List<String>, resultHandler: ResultHandler)
	{
		this.resultHandler = resultHandler
		deleteItems.addAll(ids)

		try {
			if (Environment.isExternalStorageLegacy()) {
				super.delete(ids, resultHandler)
			}
			else {
				delete(deleteItems.first(), false)
			}
		}
		catch (e: Exception) {
			resultHandler.error(Constants.Errors.UNKNOWN, e.localizedMessage)
		}
	}

	private fun delete(id: String, havePermission: Boolean = true) {
		try {
			val uri = ContentHelper.getUriWithId(id.toLong())
			// store in deleting item
			if (!havePermission) {
				deletingItem = id
			}

			activity.contentResolver.delete(
				uri,
				"${MediaStore.Images.Media._ID} = ?",
				arrayOf(id)
			)

			deleteItems.remove(deletingItem)
			deleted++
			deletingItem = null

			if (deleteItems.isEmpty()) {
				resultHandler?.success(deleted)
			}
			else {
				delete(deleteItems.first(), false)
			}
		}
		catch (e: RecoverableSecurityException) {
			val recoverableSecurityException = e as? RecoverableSecurityException
				?: throw e
			deleteRequestCode++
			activity.startIntentSenderForResult(
				recoverableSecurityException.userAction.actionIntent.intentSender,
				deleteRequestCode,
				null,
				0,
				0,
				0
			)
		}
	}
}

// delete activity handle for Android R
@RequiresApi(Build.VERSION_CODES.R)
class DeleteResultListenerHandleR(activity: Activity) : DeleteResultListenerHandle(activity) {
	private var count = 0

	init {
		deleteRequestCode = 30_000
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
		if (requestCode == deleteRequestCode) {
			if (resultCode == Activity.RESULT_OK) {
				resultHandler?.apply {
					resultHandler?.success(count)
				}
			} else {
				resultHandler?.error(
					Constants.Errors.PERMISSION_DENIED,
					null,
					null)
			}
		}
		else {
			return false
		}

		return true
	}

	override fun delete(ids: List<String>, resultHandler: ResultHandler)
	{
		this.resultHandler = resultHandler
		this.count = ids.size
		val uris = ids.map {
			ContentUris.withAppendedId(ContentHelper.externalContentUri, it.toLong())
		}

		val pendingIntent = MediaStore.createDeleteRequest(
			activity.contentResolver,
			uris.map { it }
		)

		activity.startIntentSenderForResult(
			pendingIntent.intentSender,
			deleteRequestCode,
			null,
			0,
			0,
			0)
	}
}