// Copyright Annotium 2023

import 'package:photos_native/constants.dart';

/// App version
class PHVersion {
  /// App version e.g 1.0.0
  final String appVersion;

  /// App build number e.g 101
  final String buildNumber;

  /// SDK int (Android only)
  final int? sdkInt;

  PHVersion({
    required this.appVersion,
    required this.buildNumber,
    this.sdkInt,
  });

  factory PHVersion.fromCodecMessage(Map<String, dynamic> message) => PHVersion(
        appVersion: message[Keys.appVersion] as String,
        buildNumber: message[Keys.buildNumber] as String,
        sdkInt: message[Keys.sdkInt],
      );
}
