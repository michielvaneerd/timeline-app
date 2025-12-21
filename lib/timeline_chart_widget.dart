import 'package:flutter/material.dart';

class TimelineChartWidget extends StatelessWidget {
  const TimelineChartWidget({
    super.key,
    required this.orderedYears,
    this.currentYear,
    this.longPressedStartYear,
    this.longPressedEndYear,
    this.onYearClick,
  });
  final List<int> orderedYears;
  final int? currentYear;
  final int? longPressedStartYear;
  final int? longPressedEndYear;
  final void Function(int year)? onYearClick;

  static const _bulletWidth = 10.0;
  static const _widgetWidth = 20.0;
  static const _lineWidth = 1.0;

  @override
  Widget build(BuildContext context) {
    if (orderedYears.length < 2) {
      return SizedBox(width: _widgetWidth);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight - _bulletWidth;
        final heightOneYear =
            maxHeight / (orderedYears.last - orderedYears.first);
        final List<Widget> yearWidgets = [];
        for (final year in orderedYears) {
          final yearHasLongPress =
              longPressedStartYear != null &&
              longPressedEndYear != null &&
              longPressedStartYear! == year;
          yearWidgets.add(
            Positioned(
              top: heightOneYear * (year - orderedYears.first),
              child: Container(
                width: _bulletWidth,
                height: yearHasLongPress
                    ? (heightOneYear *
                              (longPressedEndYear! - longPressedStartYear!)) +
                          _bulletWidth
                    : _bulletWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_bulletWidth),
                  color: yearHasLongPress
                      ? (Theme.of(context).colorScheme.inversePrimary)
                      : (year == currentYear
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(50)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onYearClick != null
                      ? () {
                          onYearClick!(year);
                        }
                      : null,
                ),
              ),
            ),
          );
        }
        return SizedBox(
          height: maxHeight + _bulletWidth,
          width: _widgetWidth,
          child: Stack(
            children: [
              Positioned(
                left: _widgetWidth / 2 - (_lineWidth / 2),
                top: _bulletWidth,
                child: Container(
                  width: _lineWidth,
                  height: maxHeight - _bulletWidth,
                  color: Theme.of(context).colorScheme.primary.withAlpha(50),
                ),
              ),
              Row(
                children: [
                  SizedBox(
                    width: _widgetWidth - _bulletWidth - (_bulletWidth / 2),
                  ),
                  Expanded(child: Stack(children: yearWidgets)),
                  SizedBox(
                    width: _widgetWidth - _bulletWidth - (_bulletWidth / 2),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
