// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get timeline => 'Timeline';

  @override
  String get addHost => 'Add host';

  @override
  String get hosts => 'Hosts';

  @override
  String get settings => 'Settings';

  @override
  String get host => 'Host';

  @override
  String get name => 'Name';

  @override
  String get refresh => 'Refresh';

  @override
  String get delete => 'Delete';

  @override
  String confirmDeleteHost(Object host) {
    return 'Are you sure you want to delete the host $host?';
  }

  @override
  String get condensedView => 'Condensed view';

  @override
  String get displayTimelineChart => 'Display timeline chart';

  @override
  String get loadImages => 'Load images';

  @override
  String get always => 'Always';

  @override
  String get onlyWhenOnWifi => 'Only when on WIFI';

  @override
  String get never => 'Never';

  @override
  String get imageWidth => 'Image width';

  @override
  String get selectTimelinesInfoText =>
      'Select one or more timelines to display';

  @override
  String get addHostInfoText => 'Add one or more hosts that provides timelines';

  @override
  String get theme => 'Theme';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get draftItems => 'Draft items';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get retry => 'Retry';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get cachedImages => 'Cache images';

  @override
  String get url => 'URL';

  @override
  String get addLink => 'Add link';

  @override
  String get cachedWhenNotOnWifi => 'Cached when not on WIFI';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get links => 'Links';

  @override
  String get year => 'Year';

  @override
  String get yearEnd => 'Year end';

  @override
  String get title => 'Title';

  @override
  String get yearWidth => 'Year width';

  @override
  String get yearName => 'Year name';

  @override
  String get yearEndName => 'Year end name';

  @override
  String get offlineError =>
      'For this action you need to be connected to the internet';

  @override
  String get unauthenticatedError => 'There was an error authenticating';

  @override
  String get unknownError => 'An unknown error occurred.';

  @override
  String get internetConnectionError => 'A connection error occurred';

  @override
  String get duplicateHostError => 'Host already exist';

  @override
  String get notFoundError => 'The resource was not found';

  @override
  String get color => 'Color';
}
