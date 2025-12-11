import 'package:flutter/material.dart';
import 'package:timeline/models/settings.dart';
import 'package:timeline/my_exception.dart';
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

  static String getMyExceptionMessage(BuildContext context, MyException ex) {
    switch (ex.type) {
      case MyExceptionType.offline:
        return myLoc(context).offlineError;
      case MyExceptionType.unauthenticated:
        return myLoc(context).unauthenticatedError;
      case MyExceptionType.internetConnection:
        return myLoc(context).internetConnectionError;
      case MyExceptionType.duplicateHost:
        return myLoc(context).duplicateHostError;
      case MyExceptionType.notFound:
        return myLoc(context).notFoundError;
      case MyExceptionType.unknown:
        return myLoc(context).unknownError;
    }
  }

  static String getMyThemeModes(
    BuildContext context,
    MyThemeModes myThemeModes,
  ) {
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
