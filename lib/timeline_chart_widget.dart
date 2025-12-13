import 'package:flutter/material.dart';

class TimelineChartWidget extends StatelessWidget {
  const TimelineChartWidget({
    super.key,
    required this.orderedYears,
    this.currentYear,
    this.onYearClick,
  });
  final List<int> orderedYears;
  final int? currentYear;
  final void Function(int year)? onYearClick;

  static const _bulletWidth = 10.0;
  static const _widgetWidth = 20.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight - _bulletWidth;
        final heightOneYear =
            maxHeight / (orderedYears.last - orderedYears.first);
        final List<Widget> yearWidgets = [];
        for (final year in orderedYears) {
          yearWidgets.add(
            Positioned(
              top: heightOneYear * (year - orderedYears.first),
              child: Container(
                width: _bulletWidth,
                height: _bulletWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_bulletWidth),
                  color: year == currentYear
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withAlpha(50),
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
          child: Row(
            children: [
              SizedBox(width: _widgetWidth - _bulletWidth - (_bulletWidth / 2)),
              Expanded(child: Stack(children: yearWidgets)),
              SizedBox(width: _widgetWidth - _bulletWidth - (_bulletWidth / 2)),
            ],
          ),
        );
      },
    );
  }
}
