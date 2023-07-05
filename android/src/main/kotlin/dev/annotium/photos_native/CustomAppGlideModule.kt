// Copyright Annotium 2021

package dev.annotium.photos_native

import android.content.Context
import com.bumptech.glide.annotation.GlideModule
import com.bumptech.glide.module.AppGlideModule
import com.bumptech.glide.request.RequestOptions
import com.bumptech.glide.GlideBuilder

@GlideModule
class CustomAppGlideModule : AppGlideModule()
{
	override fun applyOptions(context: Context, builder: GlideBuilder) {
		builder.setDefaultRequestOptions(
			RequestOptions().disallowHardwareConfig()
		)
	}
}