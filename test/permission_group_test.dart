import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photos_native/photos_native_method_channel.dart';

void main() {
  group('resolvePermissionGroup', () {
    test('iOS always uses photos permission, regardless of sdkInt', () {
      expect(resolvePermissionGroup(false, null), Permission.photos);
      expect(resolvePermissionGroup(false, 21), Permission.photos);
      expect(resolvePermissionGroup(false, 33), Permission.photos);
    });

    test('Android below API 33 uses storage permission', () {
      expect(resolvePermissionGroup(true, 21), Permission.storage);
      expect(resolvePermissionGroup(true, 32), Permission.storage);
    });

    test('Android API 33 (Tiramisu) and above uses photos permission', () {
      expect(resolvePermissionGroup(true, 33), Permission.photos);
      expect(resolvePermissionGroup(true, 34), Permission.photos);
    });

    test('Android with unknown sdkInt falls back to storage permission', () {
      expect(resolvePermissionGroup(true, null), Permission.storage);
    });
  });
}
