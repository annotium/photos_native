// Copyright Annotium 2023

import "dart:typed_data";

import "package:photos_native/constants.dart";
import "package:equatable/equatable.dart";

/// Photo gallery
class PHGallery {
  /// List of albums in gallery
  List<PHAlbum> albums = [];

  /// Constructor
  PHGallery();

  /// Factory constructor from platform codec message
  factory PHGallery.fromCodecMessage(List<dynamic> message) => PHGallery()
    ..albums = List.unmodifiable(
      message.map(
          (item) => PHAlbum.fromCodecMessage(Map<String, dynamic>.from(item))),
    );
}

/// Photo album
class PHAlbum {
  /// Album ID
  final String id;

  /// Album title
  final String title;

  /// Photo items in album
  final List<PHItem> items;

  /// Constructor
  PHAlbum({required this.id, required this.title, required this.items});

  /// Factory constructor from platform codec message
  factory PHAlbum.fromCodecMessage(Map<String, dynamic> message) {
    final id = message[Keys.id] as String;
    final title = message[Keys.title] as String;
    final items = message[Keys.items];
    final photos =
        List<String>.unmodifiable(items).map((e) => PHItem.fromId(e)).toList();

    return PHAlbum(id: id, title: title, items: photos);
  }

  int get count => items.length;
}

/// Photo image description
class PHImageDescriptor {
  /// Image width
  final int width;

  /// Image height
  final int height;

  /// Image data in bytes
  final Uint8List data;

  PHImageDescriptor({
    required this.width,
    required this.height,
    required this.data,
  });

  /// Factory constructor from platform codec message
  factory PHImageDescriptor.fromCodecMessage(Map<String, dynamic> message) =>
      PHImageDescriptor(
        width: message[Keys.width] as int,
        height: message[Keys.height] as int,
        data: message[Keys.data] as Uint8List,
      );
}

/// Photo shared
class PHSharedResult {
  /// Shared result from other app
  final bool shared;

  /// Shared path in cached library
  final String? path;

  /// Error message if shared result failed
  final String? errorMessage;

  /// Constructor
  PHSharedResult({required this.shared, this.path, this.errorMessage});

  /// Factory constructor from platform codec message
  factory PHSharedResult.fromCodecMessage(Map<String, dynamic> message) =>
      PHSharedResult(
        shared: message[Keys.shared] as bool,
        path: message[Keys.path] as String?,
        errorMessage: message[Keys.error] as String?,
      );
}

abstract class PHEntity extends Equatable {}

/// Photo item
class PHItem extends PHEntity {
  /// Photo item
  final String? id;

  /// Photo URI
  final Uri? uri;

  /// Constructor
  PHItem._({this.id, this.uri});

  /// Factory constructor from photo ID
  factory PHItem.fromId(String id) => PHItem._(id: id);

  /// Factory constructor from photo URI (shared photo)
  factory PHItem.fromUri(String uri) => PHItem._(uri: Uri.parse(uri));

  /// Factory constructor from codec message
  factory PHItem.fromCodecMessage(Map<String, dynamic> message) =>
      PHItem._(id: message[Keys.id] as String?);

  @override
  List<Object?> get props => [id, uri];
}
