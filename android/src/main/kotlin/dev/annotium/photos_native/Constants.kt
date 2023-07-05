// Copyright Annotium 2021

package dev.annotium.photos_native

object Constants {
    object Functions {
        const val QUERY_ALBUMS = "queryAlbums"
        const val GET_PIXELS = "getPixels"
        const val GET_THUMBNAIL = "getThumbnail"
        const val DELETE = "delete"
        const val SAVE = "save"
        const val SHARE = "share"
        const val GET_VERSION = "getVersion"
        const val LAUNCH_URL = "launchUrl"
        const val GET_INITIAL_PATH = "getInitialPath"
        const val IS_MEDIA_STORE_CHANGED = "isMediaStoreChanged"

        // trial
        const val ACQUIRE_TEXTURE = "acquireTexture"
        const val RELEASE_TEXTURE = "releaseTexture"
    }

    object Album {
        const val AllPhotos = "__ALL__"
    }
    
    object Arguments {
        const val ID = "id"
        const val IDS = "ids"
        const val DATA = "data"
        const val WIDTH = "width"
        const val HEIGHT = "height"
        const val MAXSIZE = "maxSize"
        const val MIME = "mime"
        const val QUALITY = "quality"
        const val URL = "url"
        const val URI = "uri"
        const val TITLE = "title"
        const val DIRECTORY = "directory"
        const val PATH = "path"
        const val OVERWRITE = "overwrite"
    }
    
    object Errors {
        const val INVALID = "error_invalid_call"
        const val UNKNOWN = "error_unknown"
        const val PERMISSION_DENIED = "permission_denied"
    }

    object Mime {
        const val JPG = "image/jpeg"
        const val PNG = "image/png"
        const val WEBP = "image/webp"
    }

    object Extension {
        const val JPG = ".jpg"
//        const val PNG = ".png"
    }

    object Permission {
        const val REQUEST_DEFAULT_PERMISSION = 34264
    }

    const val HIGHEST_QUALITY = 100
    const val MAXSIZE = 3000
    const val THUMB_SIZE = 300
    const val DEFAULT_QUALITY = 80

    const val APP_VERSION = "appVersion"
    const val BUILD_NUMBER = "buildNumber"
    const val SDK_INT = "sdkInt"

    const val TAG = "PhotosNative"
//    const val ANNOTIUM = "Annotium"
    const val PICTURES_PATH = "Pictures/"
    const val FILE_PROVIDER_ID = "dev.annotium.photos_native.fileprovider"
    const val DEFAULT_NAME = "Annotium"
    const val CHANNEL_NAME = "photos_native"
}
