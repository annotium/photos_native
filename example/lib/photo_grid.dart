// Copyright Annotium 2022

import "dart:math";

import "package:photos_native/src.dart";
import "package:photos_native_example/ph_thumbnail_widget.dart";
import "package:flutter/material.dart";

const kMinCrossAxisCount = 3;
const kThumbnailImageSize = 150.0;

class PhotosGrid extends StatelessWidget {
  final PHAlbum album;

  const PhotosGrid({
    super.key,
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount =
        (MediaQuery.of(context).size.width / kThumbnailImageSize).round();
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final size = kThumbnailImageSize * min(2.0, devicePixelRatio);

    return GridView.builder(
      itemCount: album.items.length,
      itemBuilder: (context, index) {
        final item = album.items[index];
        return PHThumbnailWidget(item: item, size: size);
      },
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount < kMinCrossAxisCount
            ? kMinCrossAxisCount
            : crossAxisCount,
        mainAxisSpacing: 1.0,
        crossAxisSpacing: 1.0,
        childAspectRatio: 1.0,
      ),
    );
  }
}
