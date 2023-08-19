// Copyright Annotium 2021

package dev.annotium.photos_native

object Constants {
    object Functions {
        const val QUERY_ALBUMS = "queryAlbums"
        const val GET_PIXELS = "getPixels"
        const val GET_THUMBNAIL = "getThumbnail"
        const val DELETE = "delete"
        const val SAVE = "save"
        const val SAVE_FILE = "saveFile"
        const val ENCODE = "encode"
        const val SHARE = "share"
        const val GET_VERSION = "getVersion"
        const val LAUNCH_URL = "launchUrl"
        const val IS_MEDIA_STORE_CHANGED = "isMediaStoreChanged"
        const val SET_MEMO = "setMemo";
        const val GET_MEMO = "getMemo";

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
        const val ALBUM = "album"
        const val QUALITY = "quality"
        const val URL = "url"
        const val URI = "uri"
        const val PATH = "path"
        const val TITLE = "title"
        const val KEY = "key"
        const val VALUE = "value"
    }

    object Keys {
        const val SHARED_URI = "dev.annotium.photos_native.shared_uri";
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
    const val PICTURES_PATH = "Pictures/"
    const val DEFAULT_NAME = "Annotium"
    const val CHANNEL_NAME = "photos_native"
}
