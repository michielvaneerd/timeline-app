import 'package:flutter/material.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/utils.dart';

class TranslationHelper {
  static String getLoadImages(BuildContext context, LoadImages loadImages) {
    switch (loadImages) {
      case LoadImages.always:
        return myLoc(context).always;
      case LoadImages.wifi:
        return myLoc(context).onlyWhenOnWifi;
      case LoadImages.never:
        return myLoc(context).never;
      case LoadImages.cachedWhenNotOnWifi:
        return myLoc(context).cachedWhenNotOnWifi;
    }
  }

  static String getMyThemeModes(
      BuildContext context, MyThemeModes myThemeModes) {
    switch (myThemeModes) {
      case MyThemeModes.system:
        return myLoc(context).system;
      case MyThemeModes.dark:
        return myLoc(context).dark;
      case MyThemeModes.light:
        return myLoc(context).light;
    }
  }
}
