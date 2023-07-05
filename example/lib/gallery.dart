// Copyright Annotium 2023

import "package:photos_native/src.dart";
import "package:photos_native_example/photo_grid.dart";
import "package:flutter/material.dart";

class GalleryWidget extends StatelessWidget {
  const GalleryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FlutterPhotoNative.requestPermissions(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }

        if (snapshot.hasError && snapshot.error != null) {
          return const Center(
            child: Text(
              "Permission denied",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          );
        }

        return const _PhotosContainerWidget();
      },
    );
  }
}

class _PhotosContainerWidget extends StatelessWidget {
  const _PhotosContainerWidget();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FlutterPhotoNative.loadGallery(title: 'All Photos'),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }

        if (snapshot.hasError && snapshot.error != null) {
          return Center(
            child: Text(
              "${snapshot.error}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
          );
        }

        return PhotosGrid(album: snapshot.data!.albums.first);
      },
    );
  }
}
