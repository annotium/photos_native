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
  Future<PHImageDescriptor> getPixels(String id,
      {String? uri, required int maxSize, bool isPath = false}) {
    throw UnimplementedError();
  }

  @override
  Future<PHImageDescriptor> getThumbnail(int width, int height,
      {String? id, String? uri}) {
    throw UnimplementedError();
  }

  @override
  Future<PHVersion> getVersion() {
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
  Future<bool> save(
    Uint8List bytes,
    int width,
    int height, {
    String? mime,
    String? album,
    int quality = 80,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> share(Uint8List bytes, int width, int height,
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

  @override
  Future<Uint8List> encode(Uint8List bytes, int width, int height,
      {required int quality, String? mime}) {
    throw UnimplementedError();
  }

  @override
  Future<T?> getMemo<T>(String key) {
    throw UnimplementedError();
  }

  @override
  Future<bool> setMemo<T>(String key, T value) {
    throw UnimplementedError();
  }

  @override
  Future<bool> saveFile(Uint8List bytes, int width, int height,
      {required int quality, String? mime, required String path}) {
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
