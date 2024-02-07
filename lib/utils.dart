import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

AppLocalizations myLoc(BuildContext context) {
  return AppLocalizations.of(context)!;
}

class Utils {
  static String getHex(Color color) {
    return color.value.toRadixString(16).padLeft(6, '0').substring(2);
  }
}
