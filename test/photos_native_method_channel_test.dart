// ignore_for_file: deprecated_member_use

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photos_native/photos_native_method_channel.dart';

void main() {
  MethodChannelPhotosNative platform = MethodChannelPhotosNative();
  const MethodChannel channel = MethodChannel('photos_native');

  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    channel.setMockMethodCallHandler((MethodCall methodCall) async => '42');

    expect(await platform.getPlatformVersion(), '42');
  });

  test('delete invokes the delete method with ids and returns count', () async {
    late MethodCall received;
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      received = methodCall;
      return 2;
    });

    final count = await platform.delete(['1', '2']);

    expect(count, 2);
    expect(received.method, 'delete');
    expect(received.arguments['ids'], ['1', '2']);
  });

  test('delete with an empty id list short-circuits without a channel call',
      () async {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      fail('Channel should not be invoked for an empty id list');
    });

    expect(await platform.delete([]), 0);
  });

  test('save invokes the save method with encoded arguments', () async {
    late MethodCall received;
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      received = methodCall;
      return true;
    });

    final bytes = Uint8List.fromList([1, 2, 3]);
    final success = await platform.save(bytes, 10, 20, quality: 90);

    expect(success, isTrue);
    expect(received.method, 'save');
    expect(received.arguments['data'], bytes);
    expect(received.arguments['width'], 10);
    expect(received.arguments['height'], 20);
    expect(received.arguments['quality'], 90);
  });

  test('share invokes the share method and returns success', () async {
    channel.setMockMethodCallHandler((MethodCall methodCall) async => true);

    final bytes = Uint8List.fromList([1, 2, 3]);
    expect(await platform.share(bytes, 10, 20, title: 'photo'), isTrue);
  });

  test('setMemo/getMemo round-trip through the channel', () async {
    final store = <String, dynamic>{};
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'setMemo':
          store[methodCall.arguments['key']] = methodCall.arguments['value'];
          return true;
        case 'getMemo':
          return store[methodCall.arguments['key']];
        default:
          fail('Unexpected method ${methodCall.method}');
      }
    });

    expect(await platform.setMemo('shared_uri', 'file:///tmp/a.jpg'), isTrue);
    expect(await platform.getMemo<String>('shared_uri'), 'file:///tmp/a.jpg');
  });

  test('acquireTexture/releaseTexture invoke the expected methods', () async {
    final calls = <String>[];
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      calls.add(methodCall.method);
      if (methodCall.method == 'acquireTexture') {
        return 7;
      }
      return null;
    });

    expect(await platform.acquireTexture('1', 100, 100), 7);
    await platform.releaseTexture('1');

    expect(calls, ['acquireTexture', 'releaseTexture']);
  });

  test('a PlatformException from the channel propagates to the caller',
      () async {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      throw PlatformException(code: 'error_unknown', message: 'boom');
    });

    expect(
      () => platform.delete(['1']),
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'error_unknown'),
      ),
    );
  });
}
