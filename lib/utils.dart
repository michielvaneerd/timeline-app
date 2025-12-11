import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:timeline/l10n/app_localizations.dart';

AppLocalizations myLoc(BuildContext context) {
  return AppLocalizations.of(context)!;
}

class Utils {
  static String getHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(6, '0').substring(2);
  }

  static bool isOnline(List<ConnectivityResult> result) {
    return !result.contains(ConnectivityResult.none);
  }

  static bool isOnWifiOrEthernet(List<ConnectivityResult> result) {
    return result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }

  static int? fromHexString(String input) {
    String normalized = input.replaceFirst('#', '');

    if (normalized.length == 6) {
      normalized = 'FF$normalized';
    }

    if (normalized.length != 8) {
      return null;
    }

    final int? decimal = int.tryParse(normalized, radix: 16);
    //return decimal == null ? null : Color(decimal);
    return decimal;
  }
}
