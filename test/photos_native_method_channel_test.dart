import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photos_native/photos_native_method_channel.dart';

void main() {
  MethodChannelPhotosNative platform = MethodChannelPhotosNative();
  const MethodChannel channel = MethodChannel('photos_native');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
