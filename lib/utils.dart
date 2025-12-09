import 'package:flutter/material.dart';
import 'package:timeline/l10n/app_localizations.dart';

AppLocalizations myLoc(BuildContext context) {
  return AppLocalizations.of(context)!;
}

class Utils {
  static String getHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(6, '0').substring(2);
  }
}
