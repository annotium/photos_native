//
//  Constants.h
//  Pods
//
//  Created by Hoang Le on 12/18/20.
//

#ifndef Constants_h
#define Constants_h

static const int DEFAULT_QUALITY = 80;

static NSString* const ANNOTIUM = @"Annotium";

static NSString* const MIME_PNG = @"image/png";
static NSString* const MIME_JPG = @"image/jpeg";
static NSString* const APP_VERSION = @"appVersion";
static NSString* const BUILD_NUMBER = @"buildNumber";

static NSString* const FUNC_QUERY_ALBUMS = @"queryAlbums";
static NSString* const FUNC_GET_THUMBNAIL = @"getThumbnail";
static NSString* const FUNC_GET_BYTES = @"getBytes";
static NSString* const FUNC_GET_PIXELS = @"getPixels";
static NSString* const FUNC_DELETE = @"delete";
static NSString* const FUNC_SAVE = @"save";
static NSString* const FUNC_SHARE = @"share";
static NSString* const FUNC_GET_VERSION = @"getVersion";
static NSString* const FUNC_REQUEST_PERMISSIONS = @"requestPermissions";
static NSString* const FUNC_LAUNCH_URL = @"launchUrl";
static NSString* const FUNC_GET_INITIAL_PATH = @"getInitialPath";
static NSString* const FUNC_IS_MEDIA_STORE_CHANGED = @"isMediaStoreChanged";
static NSString* const FUNC_ACQUIRE_TEXTURE = @"acquireTexture";
static NSString* const FUNC_RELEASE_TEXTURE = @"releaseTexture";

static NSString* const ARG_ID = @"id";
static NSString* const ARG_IDS = @"ids";
static NSString* const ARG_WIDTH = @"width";
static NSString* const ARG_HEIGHT = @"height";
static NSString* const ARG_MAXSIZE = @"maxSize";
static NSString* const ARG_DATA = @"data";
static NSString* const ARG_MIME = @"mime";
static NSString* const ARG_QUALITY = @"quality";
static NSString* const ARG_URL = @"url";
static NSString* const ARG_URI = @"uri";
static NSString* const ARG_DEVICE_PIXEL_RATIO = @"devicePixelRatio";
static NSString* const ARG_TITLE = @"title";

static NSString* const ERR_UNKNOWN = @"error_unknown";
static NSString* const ERR_PARAMETER_MISSING = @"error_paremeter_missing";
static NSString* const ERR_NOT_FOUND = @"error_id_not_found";

static NSString* const KEY_ID = @"id";
static NSString* const KEY_TITLE = @"title";
static NSString* const KEY_ITEMS = @"items";
static NSString* const KEY_APP_VERSION = @"appVersion";
static NSString* const KEY_BUILD_NUMBER = @"buildNumber";
static NSString* const KEY_WIDTH = @"width";
static NSString* const KEY_HEIGHT = @"height";
static NSString* const KEY_DATA = @"data";
static NSString* const KEY_SHARED = @"shared";
static NSString* const KEY_PATH = @"path";
static NSString* const KEY_ERROR = @"error";
static NSString* const KEY_SDK_INT = @"sdkInt";

static NSString* const TYPE_MEDIA = @"media";
static NSString* const ANNOTIUM_GROUP = @"group.app.ngockhanh.annotium";

#endif /* Constants_h */
