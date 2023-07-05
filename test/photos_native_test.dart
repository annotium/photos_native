import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photos_native/ph_version.dart';
import 'package:photos_native/ph_types.dart';
import 'package:photos_native/photos_native.dart';
import 'package:photos_native/photos_native_platform_interface.dart';
import 'package:photos_native/photos_native_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPhotosNativePlatform
    with MockPlatformInterfaceMixin
    implements PhotosNativePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<int> delete(List<String> ids) {
    throw UnimplementedError();
  }

  @override
  Future<String?> getInitialImage() {
    throw UnimplementedError();
  }

  @override
  Future<PHImageDescription> getPixels(String id,
      {String? uri, required int maxSize, bool isPath = false}) {
    throw UnimplementedError();
  }

  @override
  Future<PHImageDescription> getThumbnail(int width, int height,
      {String? id, String? uri}) {
    throw UnimplementedError();
  }

  @override
  Future<PHVersion> getVersion() {
    throw UnimplementedError();
  }

  @override
  Future<bool> isMediaStoreChanged() {
    throw UnimplementedError();
  }

  @override
  Future<bool> launchUrl(String url) {
    throw UnimplementedError();
  }

  @override
  Future<PHGallery> loadGallery({required String title}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> requestPermissions() {
    throw UnimplementedError();
  }

  @override
  Future<bool> save(Uint8List bytes, int width, int height,
      {String? mime,
      int quality = 80,
      double? devicePixelRatio = 1.0,
      String? directory,
      String? path,
      bool overwrite = false}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> share(
      Uint8List bytes, int width, int height, double devicePixelRatio,
      {String title = ""}) {
    throw UnimplementedError();
  }

  @override
  Future<int> acquireTexture(String id, int width, int height) {
    throw UnimplementedError();
  }

  @override
  Future<void> releaseTexture(String id) {
    throw UnimplementedError();
  }
}

void main() {
  final PhotosNativePlatform initialPlatform = PhotosNativePlatform.instance;

  test('$MethodChannelPhotosNative is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPhotosNative>());
  });

  test('getPlatformVersion', () async {
    MockPhotosNativePlatform fakePlatform = MockPhotosNativePlatform();
    PhotosNativePlatform.instance = fakePlatform;

    expect(await FlutterPhotoNative.getPlatformVersion(), '42');
  });
}
