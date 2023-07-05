// Copyright Annotium 2023

import "package:photos_native/src.dart";
import "package:flutter/material.dart";

class PHThumbnailWidget extends StatelessWidget {
  final PHItem item;
  final double size;

  const PHThumbnailWidget({
    super.key,
    required this.item,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isize = size.toInt();

    return FutureBuilder<PHImageDescription>(
        future: FlutterPhotoNative.getThumbnail(
          id: item.id,
          uri: item.uri.toString(),
          isize,
          isize,
        ),
        builder: (
          BuildContext context,
          AsyncSnapshot<PHImageDescription> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.done) {
            final imageDescriptor = snapshot.data;
            return Image(
              image: RawImageProvider(
                RawImageData(
                  imageDescriptor!.data,
                  imageDescriptor.width,
                  imageDescriptor.height,
                ),
              ),
              width: size,
              height: size,
              fit: BoxFit.cover,
            );
          } else {
            return Container(color: const Color(0xFFE0E0E0));
          }
        });
  }
}
