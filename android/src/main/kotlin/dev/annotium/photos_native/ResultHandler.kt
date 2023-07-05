// Copyright Annotium 2021

package dev.annotium.photos_native

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

class ResultHandler(private var result: MethodChannel.Result?) {
//    private val handler = Handler(Looper.getMainLooper())

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
            }
        }
    }
}