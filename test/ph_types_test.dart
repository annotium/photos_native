import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:photos_native/ph_types.dart';
import 'package:photos_native/ph_version.dart';

void main() {
  group('PHItem', () {
    test('fromId sets id and leaves uri null', () {
      final item = PHItem.fromId('42');
      expect(item.id, '42');
      expect(item.uri, isNull);
    });

    test('fromUri parses uri and leaves id null', () {
      final item = PHItem.fromUri('file:///tmp/photo.jpg');
      expect(item.uri, Uri.parse('file:///tmp/photo.jpg'));
      expect(item.id, isNull);
    });

    test('fromCodecMessage round-trips id', () {
      final item = PHItem.fromCodecMessage({'id': '7'});
      expect(item.id, '7');
    });

    test('fromCodecMessage tolerates missing id', () {
      final item = PHItem.fromCodecMessage({});
      expect(item.id, isNull);
    });

    test('equality is based on id and uri', () {
      expect(PHItem.fromId('1'), PHItem.fromId('1'));
      expect(PHItem.fromId('1'), isNot(PHItem.fromId('2')));
    });
  });

  group('PHAlbum', () {
    test('fromCodecMessage round-trips id, title and items', () {
      final album = PHAlbum.fromCodecMessage({
        'id': 'album-1',
        'title': 'Camera Roll',
        'items': ['1', '2', '3'],
      });

      expect(album.id, 'album-1');
      expect(album.title, 'Camera Roll');
      expect(album.count, 3);
      expect(album.items.map((e) => e.id), ['1', '2', '3']);
    });

    test('fromCodecMessage throws on missing required key', () {
      expect(
        () => PHAlbum.fromCodecMessage({'title': 'No id'}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('PHGallery', () {
    test('fromCodecMessage round-trips a list of albums', () {
      final gallery = PHGallery.fromCodecMessage([
        {
          'id': 'a1',
          'title': 'All Photos',
          'items': ['1'],
        },
        {
          'id': 'a2',
          'title': 'Screenshots',
          'items': <String>[],
        },
      ]);

      expect(gallery.albums, hasLength(2));
      expect(gallery.albums[0].title, 'All Photos');
      expect(gallery.albums[1].count, 0);
    });

    test('fromCodecMessage handles an empty album list', () {
      final gallery = PHGallery.fromCodecMessage([]);
      expect(gallery.albums, isEmpty);
    });
  });

  group('PHImageDescriptor', () {
    test('fromCodecMessage round-trips width, height and data', () {
      final data = Uint8List.fromList([1, 2, 3, 4]);
      final descriptor = PHImageDescriptor.fromCodecMessage({
        'width': 100,
        'height': 200,
        'data': data,
      });

      expect(descriptor.width, 100);
      expect(descriptor.height, 200);
      expect(descriptor.data, data);
      expect(descriptor.dimension, const Size(100, 200));
    });

    test('fromCodecMessage throws on malformed data type', () {
      expect(
        () => PHImageDescriptor.fromCodecMessage({
          'width': 100,
          'height': 200,
          'data': 'not-bytes',
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('PHSharedResult', () {
    test('fromCodecMessage round-trips a success result', () {
      final result = PHSharedResult.fromCodecMessage({
        'shared': true,
        'path': '/tmp/shared.jpg',
      });

      expect(result.shared, isTrue);
      expect(result.path, '/tmp/shared.jpg');
      expect(result.errorMessage, isNull);
    });

    test('fromCodecMessage round-trips a failure result', () {
      final result = PHSharedResult.fromCodecMessage({
        'shared': false,
        'error': 'error_unknown',
      });

      expect(result.shared, isFalse);
      expect(result.path, isNull);
      expect(result.errorMessage, 'error_unknown');
    });
  });

  group('PHVersion', () {
    test('fromCodecMessage round-trips all fields', () {
      final version = PHVersion.fromCodecMessage({
        'appVersion': '1.2.3',
        'buildNumber': '45',
        'sdkInt': 33,
      });

      expect(version.appVersion, '1.2.3');
      expect(version.buildNumber, '45');
      expect(version.sdkInt, 33);
    });

    test('fromCodecMessage tolerates missing sdkInt (iOS has none)', () {
      final version = PHVersion.fromCodecMessage({
        'appVersion': '1.2.3',
        'buildNumber': '45',
      });

      expect(version.sdkInt, isNull);
    });

    test('fromCodecMessage throws on missing required key', () {
      expect(
        () => PHVersion.fromCodecMessage({'buildNumber': '45'}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
