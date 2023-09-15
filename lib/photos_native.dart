// Copyright Annotium 2023

import 'dart:typed_data';

import 'package:photos_native/ph_types.dart';
import 'package:photos_native/ph_version.dart';

import 'photos_native_platform_interface.dart';

class FlutterPhotoNative {
  FlutterPhotoNative._();

  /// Max photo size
  static const kImageMaxSize = 3000;

  static Future<String?> getPlatformVersion() =>
      PhotosNativePlatform.instance.getPlatformVersion();

  static Future<T?> getMemo<T>(String key) =>
      PhotosNativePlatform.instance.getMemo(key);

  static Future<bool> setMemo<T>(String key, T value) =>
      PhotosNativePlatform.instance.setMemo(key, value);

  static Future<bool> requestPermissions() =>
      PhotosNativePlatform.instance.requestPermissions();

  static Future<PHGallery> loadGallery({required String title}) =>
      PhotosNativePlatform.instance.loadGallery(title: title);

  static Future<PHImageDescriptor> getThumbnail(
    int width,
    int height, {
    String? id,
    String? uri,
  }) =>
      PhotosNativePlatform.instance
          .getThumbnail(width, height, id: id, uri: uri);

  static Future<PHImageDescriptor> getPixels(
    String id, {
    String? uri,
    int maxSize = kImageMaxSize,
  }) =>
      PhotosNativePlatform.instance.getPixels(id, uri: uri, maxSize: maxSize);

  static Future<Uint8List> getBytes(
    String? id, {
    String? uri,
  }) =>
      PhotosNativePlatform.instance.getBytes(id, uri: uri);

  static Future<int> delete(List<String> ids) =>
      PhotosNativePlatform.instance.delete(ids);

  static Future<bool> save(
    Uint8List bytes,
    int width,
    int height, {
    String? album,
    String? mime,
    int quality = 80,
  }) =>
      PhotosNativePlatform.instance.save(bytes, width, height,
          mime: mime, quality: quality, album: album);

  static Future<bool> saveFile(
    Uint8List bytes,
    int width,
    int height, {
    required int quality,
    String? mime,
    required String path,
  }) =>
      PhotosNativePlatform.instance.saveFile(bytes, width, height,
          mime: mime, quality: quality, path: path);

  static Future<Uint8List> encode(
    Uint8List bytes,
    int width,
    int height, {
    String? mime,
    int quality = 80,
  }) =>
      PhotosNativePlatform.instance
          .encode(bytes, width, height, mime: mime, quality: quality);

  static Future<bool> share(
    Uint8List bytes,
    int width,
    int height, {
    String title = "",
  }) =>
      PhotosNativePlatform.instance.share(bytes, width, height, title: title);

  static Future<PHVersion> getVersion() =>
      PhotosNativePlatform.instance.getVersion();

  static Future<bool> launchUrl(String url) =>
      PhotosNativePlatform.instance.launchUrl(url);

  static Future<int> acquireTexture(String id, int width, int height) =>
      acquireTexture(id, width, height);
}
