// Copyright Annotium 2021

package dev.annotium.photos_native

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class ResultHandler(private var result: MethodChannel.Result?) {
    private var isReply = false

    fun success(any: Any?) {
        if (isReply) {
            return
        }

        isReply = true
        val result = this.result
        this.result = null
        Handler(Looper.getMainLooper()).post {
            try {
                result?.success(any)
            }
            catch (e: Exception) {
                Log.e(Constants.TAG, "Failed to reply success: ${e.localizedMessage}")
            }
        }
    }

    fun error(code: String, message: String? = null, obj: Any? = null) {
        if (isReply) {
            return
        }
        isReply = true
        val result = this.result
        this.result = null

        Handler(Looper.getMainLooper()).post {
            try {
                result?.error(code, message, obj?.toString())
            } catch (e: Exception) {
                Log.e(Constants.TAG, "Failed to reply error: ${e.localizedMessage}")
            }
        }
    }
}