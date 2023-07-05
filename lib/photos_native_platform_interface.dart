// Copyright Annotium 2023

import 'dart:typed_data';

import 'package:photos_native/ph_types.dart';
import 'package:photos_native/ph_version.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'photos_native_method_channel.dart';

abstract class PhotosNativePlatform extends PlatformInterface {
  /// Constructs a PhotosNativePlatform.
  PhotosNativePlatform() : super(token: _token);

  static final Object _token = Object();

  static PhotosNativePlatform _instance = MethodChannelPhotosNative();

  /// The default instance of [PhotosNativePlatform] to use.
  ///
  /// Defaults to [MethodChannelPhotosNative].
  static PhotosNativePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PhotosNativePlatform] when
  /// they register themselves.
  static set instance(PhotosNativePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  Future<PHGallery> loadGallery({required String title}) {
    throw UnimplementedError('loadGallery() has not been implemented.');
  }

  Future<PHImageDescriptor> getThumbnail(int width, int height,
      {String? id, String? uri}) {
    throw UnimplementedError('getThumbnail() has not been implemented.');
  }

  Future<PHImageDescriptor> getPixels(
    String id, {
    String? uri,
    required int maxSize,
    bool isPath = false,
  }) {
    throw UnimplementedError('getPixels() has not been implemented.');
  }

  Future<int> delete(List<String> ids) {
    throw UnimplementedError('delete() has not been implemented.');
  }

  Future<bool> save(
    Uint8List bytes,
    int width,
    int height, {
    String? mime,
    int quality = 80,
    double? devicePixelRatio = 1.0,
    String? directory,
    String? path,
    bool overwrite = false,
  }) {
    throw UnimplementedError('save() has not been implemented.');
  }

  Future<bool> share(
    Uint8List bytes,
    int width,
    int height,
    double devicePixelRatio, {
    String title = "",
  }) {
    throw UnimplementedError('share() has not been implemented.');
  }

  Future<bool> launchUrl(String url) {
    throw UnimplementedError('launchUrl() has not been implemented.');
  }

  Future<String?> getInitialImage() {
    throw UnimplementedError('getInitialImage() has not been implemented.');
  }

  Future<bool> isMediaStoreChanged() {
    throw UnimplementedError('isMediaStoreChanged() has not been implemented.');
  }

  Future<PHVersion> getVersion() {
    throw UnimplementedError('getVersion() has not been implemented.');
  }

  Future<int> acquireTexture(String id, int width, int height) {
    throw UnimplementedError('acquireTexture() has not been implemented.');
  }

  Future<void> releaseTexture(String id) {
    throw UnimplementedError('releaseTexture() has not been implemented.');
  }
}
