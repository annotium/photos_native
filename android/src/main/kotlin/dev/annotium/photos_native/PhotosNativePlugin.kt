// Copyright Annotium 2022

package dev.annotium.photos_native

import android.app.Application
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.*
import io.flutter.plugin.common.PluginRegistry.NewIntentListener

/** PhotosNativePlugin */
class PhotosNativePlugin: FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
  private var applicationContext: Context? = null
  private var pluginBinding: FlutterPluginBinding? = null

  private var activityBinding: ActivityPluginBinding? = null
  private var channel: MethodChannel? = null

  private var permissionHandler: PermissionHandler? = null
  private var methodCallHandler: MethodCallHandlerImpl? = null
  private val newIntentListenerHandle = OnNewIntentListenerHandle()
  private var deleteHandler: DeleteResultListenerHandle? = null

  private var _mediaStoreChanged = false
  private var _sharedUri: String? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
    pluginBinding = flutterPluginBinding
  }

  override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
    pluginBinding = null
  }

  private fun setup(
    messenger: BinaryMessenger,
    application: Application,
    activityBinding: ActivityPluginBinding
  ) {
    applicationContext = application
    val activity = activityBinding.activity

    methodCallHandler = MethodCallHandlerImpl()

    channel = MethodChannel(messenger, Constants.CHANNEL_NAME)
    channel?.setMethodCallHandler(this)

    activityBinding.addOnNewIntentListener(newIntentListenerHandle)

    permissionHandler = PermissionHandler(activity)
    permissionHandler?.let {
      activityBinding.addRequestPermissionsResultListener(it)
    }

    deleteHandler = DeleteHelper.getHandle(activity)
    deleteHandler?.let {
      activityBinding.addActivityResultListener(it)
    }

    handleIntent(activity.intent)
  }

  private fun tearDown()
  {
    activityBinding?.let { activityBinding ->
      deleteHandler?.let {
        activityBinding.removeActivityResultListener(it)
      }
      deleteHandler = null

      permissionHandler?.let {
        activityBinding.removeRequestPermissionsResultListener(it)
      }
      permissionHandler = null

      activityBinding.removeOnNewIntentListener(newIntentListenerHandle)
    }

    methodCallHandler?.cancel()
    channel?.setMethodCallHandler(null)
    channel = null
    activityBinding = null
  }

  //  #region ActivityAware
  override fun onDetachedFromActivity() {
    // your plugin is no longer associated with an Activity.
    tearDown()
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    // plugin is now attached to an Activity
    activityBinding = binding
    pluginBinding?.let {
      setup(
        it.binaryMessenger,
        it.applicationContext as Application,
        activityBinding!!
      )
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    // the Activity your plugin was attached to was destroyed to change configuration.
    // This call will be followed by onReattachedToActivityForConfigChanges().
    onDetachedFromActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    // your plugin is now attached to a new Activity after a configuration change.
    onAttachedToActivity(binding)
  }

  private fun handleIntent(intent: Intent) {
    // Log.d("TAG", "Handle intent $intent")

    if (intent.type?.startsWith("image/") == true) {
      when (intent.action) {
        Intent.ACTION_SEND -> {
          val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
          _sharedUri = uri?.toString()
        }

        Intent.ACTION_VIEW, Intent.ACTION_EDIT -> {
          val uri = intent.data
          _sharedUri = uri?.toString()
        }
      }
    }
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result)
  {
    // Log.d("TAG", "Handle method '${call.method}'")
    val activity = activityBinding?.activity
    if (activity == null) {
      result.error(Constants.Errors.UNKNOWN, "Activity is not binding", null)
      return
    }

    val resultHandler = ResultHandler(result)
    when (call.method) {
      Constants.Functions.QUERY_ALBUMS -> {
        val title = call.argument<String>(Constants.Arguments.TITLE) ?: ""
        methodCallHandler?.queryAlbums(activity, title, resultHandler)
      }
      Constants.Functions.GET_THUMBNAIL -> {
        val id = call.argument<String>(Constants.Arguments.ID)
        val uriStr = call.argument<String>(Constants.Arguments.URI)
        val width = call.argument<Int>(Constants.Arguments.WIDTH) ?: Constants.THUMB_SIZE
        val height = call.argument<Int>(Constants.Arguments.HEIGHT) ?: Constants.THUMB_SIZE

        if (!id.isNullOrEmpty()) {
          val uri = ContentHelper.getUriWithId(id.toLong())
          methodCallHandler?.getThumbnail(activity, uri, width, height, resultHandler)
        }
        else if (!uriStr.isNullOrEmpty()) {
          val uri = Uri.parse(uriStr)
          methodCallHandler?.getThumbnail(activity, uri, width, height, resultHandler)
        }

        else {
          resultHandler.error(Constants.Errors.INVALID, "Invalid image")
        }
      }
      Constants.Functions.GET_PIXELS -> {
        val id = call.argument<String>(Constants.Arguments.ID)
        val maxSize = call.argument<Int>(Constants.Arguments.MAXSIZE) ?: Constants.MAXSIZE

        if (id.isNullOrEmpty()) {
          val uri = call.argument<String>(Constants.Arguments.URI) ?: _sharedUri
          if (uri.isNullOrEmpty()) {
            resultHandler.error(Constants.Errors.INVALID, "Invalid image")
          }
          else {
            val handleUri = Uri.parse(uri)
            methodCallHandler?.getPixelsFromUri(
              activity,
              handleUri,
              maxSize,
              resultHandler
            )
            _sharedUri = null
          }
        }
        else {
          methodCallHandler?.getPixels(activity, id, maxSize, resultHandler)
        }
      }
      Constants.Functions.DELETE -> {
        val ids = call.argument<List<String>>(Constants.Arguments.IDS)!!
        if (deleteHandler != null) {
          deleteHandler?.delete(ids, resultHandler)
          for (id in ids) {
            methodCallHandler?.releaseTexture(id)
          }
        }
        else {
          resultHandler.error(
            Constants.Errors.INVALID,
            "Invalid delete handler"
          )
        }
      }
      Constants.Functions.SAVE -> {
        val data = call.argument<ByteArray>(Constants.Arguments.DATA)!!
        val width = call.argument<Int>(Constants.Arguments.WIDTH)!!
        val height = call.argument<Int>(Constants.Arguments.HEIGHT)!!
        val mime = call.argument<String>(Constants.Arguments.MIME)!!
        val quality = call.argument<Int>(Constants.Arguments.QUALITY)
          ?: Constants.DEFAULT_QUALITY

        methodCallHandler?.save(
          activity,
          data,
          width,
          height,
          mime,
          quality,
          resultHandler,
        )
      }
      Constants.Functions.SHARE -> {
        val data = call.argument<ByteArray>(Constants.Arguments.DATA)!!
        val width = call.argument<Int>(Constants.Arguments.WIDTH)!!
        val height = call.argument<Int>(Constants.Arguments.HEIGHT)!!
        val title = call.argument<String>(Constants.Arguments.TITLE) ?: ""
        methodCallHandler?.share(activity, data, width, height, title, resultHandler)
      }
      Constants.Functions.LAUNCH_URL -> {
        val url = call.argument<String>(Constants.Arguments.URL)
        if (url.isNullOrEmpty()) {
          result.success(false)
        }

        val urlLauncher = UrlLauncher()
        urlLauncher.launch(activity, url, null)
        result.success(true)
      }
      Constants.Functions.GET_INITIAL_PATH -> {
        result.success(_sharedUri)
      }
      Constants.Functions.IS_MEDIA_STORE_CHANGED -> {
        result.success(_mediaStoreChanged)
      }
      Constants.Functions.GET_VERSION -> {
        getVersion(result)
      }
      Constants.Functions.ACQUIRE_TEXTURE -> {
        val id = call.argument<String>(Constants.Arguments.ID)
        val width = call.argument<Int>(Constants.Arguments.WIDTH) ?: Constants.THUMB_SIZE
        val height = call.argument<Int>(Constants.Arguments.HEIGHT) ?: Constants.THUMB_SIZE

        if (id.isNullOrEmpty()) {
          resultHandler.error(Constants.Errors.INVALID, "Invalid image id")
        }
        else {
          methodCallHandler?.acquireTexture(
            activity,
            pluginBinding!!.textureRegistry,
            id,
            width,
            height,
            resultHandler
          )
        }
      }
      Constants.Functions.RELEASE_TEXTURE -> {
        val id = call.argument<String>(Constants.Arguments.ID)
        if (id.isNullOrEmpty()) {
          resultHandler.error(Constants.Errors.INVALID, "Missing texture id")
        }
        else {
          methodCallHandler?.releaseTexture(id)
        }
      }
    }
  }

  private fun getVersion(result: MethodChannel.Result) {
    Log.d(Constants.TAG, "Get build version")
    if (applicationContext == null) {
      result.error(
        Constants.Errors.UNKNOWN,
        "Failed to get version",
        null
      )

      return
    }

    applicationContext?.let { context ->
      val info = context.packageManager.getPackageInfo(
        context.packageName,
        PackageManager.GET_ACTIVITIES
      )

      val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        info.longVersionCode.toString()
      } else {
        @Suppress("DEPRECATION")
        info.versionCode.toString()
      }

      result.success(
        mapOf<String, Any>(
          Constants.APP_VERSION to info.versionName,
          Constants.BUILD_NUMBER to versionCode,
          Constants.SDK_INT to Build.VERSION.SDK_INT
        )
      )
    }
  }

  private inner class OnNewIntentListenerHandle: NewIntentListener {
    override fun onNewIntent(intent: Intent): Boolean {
      handleIntent(intent)
      return false
    }
  }
}
