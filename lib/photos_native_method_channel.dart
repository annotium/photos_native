// Copyright Annotium 2023

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photos_native/constants.dart';
import 'package:photos_native/ph_types.dart';
import 'package:photos_native/ph_version.dart';

import 'photos_native_platform_interface.dart';

/// An implementation of [PhotosNativePlatform] that uses method channels.
class MethodChannelPhotosNative extends PhotosNativePlatform {
  bool allowed = false;

  late final PHVersion version;

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('photos_native');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  /// Temporarily key-value memo getter usage to share between platform and Flutter
  ///
  /// [String] key to get memo value
  @override
  Future<T?> getMemo<T>(String key) async {
    return await methodChannel.invokeMethod<T>(Functions.getMemo, {
      Arguments.key: key,
    });
  }

  /// Temporarily key-value memo setter usage to share between platform and Flutter
  /// If value is null, then it will clear memo key
  ///
  /// [String] key
  /// [String] value
  @override
  Future<bool> setMemo<T>(String key, T? value) async {
    return await methodChannel.invokeMethod<bool>(Functions.setMemo, {
          Arguments.key: key,
          Arguments.value: value,
        }) ??
        false;
  }

  /// Ensure to requests photo library permission before access
  ///
  /// return true if permission is granted, otherwise false
  @override
  Future<bool> requestPermissions() async {
    version = await getVersion();
    if (!allowed) {
      final permission = await _getPermissionsGroup();
      allowed = await permission.request().isGranted;
      if (!allowed) {
        throw Exception("error_accessdenied");
      }
    }

    return allowed;
  }

  /// Query all albums from gallery, [title] is the title of default album
  /// (Default album contains all photos in gallery)
  ///
  /// [PHGallery] gallery contains all albums
  @override
  Future<PHGallery> loadGallery({required String title}) async {
    if (!allowed) {
      await requestPermissions();
    }

    final result = await methodChannel.invokeMethod(Functions.queryAlbums, {
      Arguments.title: title,
    });

    if (result == null) {
      throw Exception('error_load_gallery');
    }

    return PHGallery.fromCodecMessage(result);
  }

  /// Get photo thumbnail for an photo item (only one of [id]/[uri] is used).
  /// Result thumbnail will have size of given [width]/[height] parameters
  ///
  /// [width] expected width of result thumbnail
  /// [height] expected height of result thumbnail
  /// [id] ID of the photo
  /// [uri] URI of the photo
  ///
  /// [PHImageDescriptor] thumbnail image descriptor
  @override
  Future<PHImageDescriptor> getThumbnail(
    int width,
    int height, {
    String? id,
    String? uri,
  }) {
    assert(id != null || uri != null, "Id or uri must be provided");

    return _invokeMethod<PHImageDescriptor>(
      method: Functions.getThumbnail,
      arguments: {
        Arguments.id: id,
        Arguments.uri: uri,
        Arguments.width: width,
        Arguments.height: height,
      },
      postProcess: (value) => PHImageDescriptor.fromCodecMessage(
        Map<String, dynamic>.from(value),
      ),
    );
  }

  /// Get photo description of the photo
  ///
  /// [id] ID of the photo
  /// [uri] URI of the photo
  /// [maxSize] max size of result photo, if the photo has bigger size, it will
  /// be resized to the given size
  /// [isPath]
  ///
  /// [PHImageDescriptor] image descriptor
  @override
  Future<PHImageDescriptor> getPixels(
    String id, {
    String? uri,
    required int maxSize,
  }) {
    assert(id.isNotEmpty || uri != null, "Id or uri must be provided");

    return _invokeMethod<PHImageDescriptor>(
      method: Functions.getPixels,
      arguments: {
        Arguments.id: id,
        Arguments.uri: uri,
        Arguments.maxSize: maxSize,
      },
      postProcess: (value) => PHImageDescriptor.fromCodecMessage(
        Map<String, dynamic>.from(value),
      ),
    );
  }

  /// Delete photos
  ///
  /// [ids] IDs request of the deleting photos
  ///
  /// return number of deleted photos
  @override
  Future<int> delete(List<String> ids) {
    if (ids.isEmpty) {
      return Future.value(0);
    }

    return _invokeMethod<int>(
      method: Functions.deletePhotos,
      arguments: {Arguments.ids: ids},
      postProcess: (value) => value as int,
    );
  }

  /// Save photo
  ///
  /// [bytes] image data to save
  /// [width] width of save image
  /// [height] height of save image
  /// [mime] MIME type of the save image
  /// [quality] quality of the save image, maximum is 100, size of saved image
  /// will be directly proportional to the quality
  ///
  /// return true if successful otherwise false
  @override
  Future<bool> save(
    Uint8List bytes,
    int width,
    int height, {
    required int quality,
    String? album,
    String? mime,
  }) =>
      _invokeMethod<bool>(method: Functions.savePhoto, arguments: {
        Arguments.data: bytes,
        Arguments.width: width,
        Arguments.height: height,
        Arguments.album: album,
        Arguments.mime: mime,
        Arguments.quality: quality,
      });

  /// Encode(or compress) image data to given format/inputs
  ///
  /// [bytes] image data to save
  /// [width] width of save image
  /// [height] height of save image
  /// [mime] MIME type of the save image
  /// [quality] quality of the save image, maximum is 100, size of saved image
  /// will be directly proportional to the quality
  ///
  /// return byte array of encoded image if successful otherwise exception will be thrown
  @override
  Future<Uint8List> encode(
    Uint8List bytes,
    int width,
    int height, {
    required int quality,
    String? mime,
  }) =>
      _invokeMethod<Uint8List>(method: Functions.encode, arguments: {
        Arguments.data: bytes,
        Arguments.width: width,
        Arguments.height: height,
        Arguments.mime: mime,
        Arguments.quality: quality,
      });

  /// Share photo, on Android, it will invoke shared [Intent], on iOS it will
  /// invoke [UIActivityViewController]
  ///
  /// [bytes] image data
  /// [width] width of save image
  /// [height] height of save image
  /// [devicePixelRatio] device pixel ratio
  /// [title] title of the save image
  /// return true if successful otherwise false
  @override
  Future<bool> share(
    Uint8List bytes,
    int width,
    int height, {
    String title = "",
  }) =>
      _invokeMethod<bool>(method: Functions.sharePhoto, arguments: {
        Arguments.data: bytes,
        Arguments.width: width,
        Arguments.height: height,
        Arguments.title: title
      });

  /// Get app version
  @override
  Future<PHVersion> getVersion() => _invokeMethod<PHVersion>(
        method: Functions.getVersion,
        postProcess: (value) {
          debugPrint("$value");
          return PHVersion.fromCodecMessage(Map<String, dynamic>.from(value));
        },
      );

  /// Launch URL
  ///
  /// [url] URL to launch
  @override
  Future<bool> launchUrl(String url) => _invokeMethod<bool>(
      method: Functions.launchUrl, arguments: {Arguments.url: url});

  /// Private utility function to invoke dynamic platform method
  ///
  /// [method] Method name
  /// [arguments] Method arguments
  /// [postProcess] dynamic function to handle returned codec message data
  Future<T> _invokeMethod<T>({
    required String method,
    dynamic arguments,
    _ValuePostProcess<T>? postProcess,
  }) {
    final completer = Completer<T>();

    if (postProcess == null) {
      methodChannel.invokeMethod<T>(method, arguments).then((value) {
        completer.complete(value);
      }).catchError((error) {
        debugPrint("Invoke '$method' failed: $error");
        completer.completeError(error);
      });
    } else {
      methodChannel.invokeMethod(method, arguments).then((value) {
        completer.complete(postProcess(value));
      }).catchError((error) {
        debugPrint("Invoke '$method' failed: $error");
        completer.completeError(error);
      });
    }

    return completer.future;
  }

  /// (Experiment) to acquire photo texture using GPU
  ///
  /// [id] image ID
  /// [width] width of save image
  /// [height] height of save image
  @override
  Future<int> acquireTexture(String id, int width, int height) =>
      _invokeMethod<int>(
        method: Functions.acquireTexture,
        arguments: {
          Arguments.id: id,
          Arguments.width: width,
          Arguments.height: height
        },
      );

  /// (Experiment) to release photo texture using GPU
  ///
  /// [id] image ID
  @override
  Future<void> releaseTexture(String id) => _invokeMethod(
        method: Functions.releaseTexture,
        arguments: {
          Arguments.id: id,
        },
      );

  /// Private utility function to get photo access permission. On Android 13 and
  /// iOS, it required `photos` permission, on Android before 13 it will require
  /// `storage` permission
  Future<Permission> _getPermissionsGroup() async {
    if (Platform.isAndroid) {
      final sdkInt = version.sdkInt;
      final isTiramisu = Platform.isAndroid && sdkInt != null && sdkInt >= 33;

      return isTiramisu ? Permission.photos : Permission.storage;
    }

    return Permission.photos;
  }
}

typedef _ValuePostProcess<T> = T Function(dynamic value);
