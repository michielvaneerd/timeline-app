import 'package:flutter/material.dart';
import 'package:timeline/my_styles.dart';
import 'package:timeline/utils.dart';

class MyColorPicker extends StatefulWidget {
  const MyColorPicker({super.key, required this.onUpdate, this.initialColor});
  final Function(Color? color) onUpdate;
  final Color? initialColor;

  @override
  State<MyColorPicker> createState() => _MyColorPickerState();
}

class _MyColorPickerState extends State<MyColorPicker> {
  var _value = 0.0;
  Color _color = Colors.transparent;
  late List<Color> _timelineColors;

  @override
  void initState() {
    _timelineColors = generateAllHexColors();
    _color = widget.initialColor ?? Colors.transparent;
    super.initState();
  }

  static const _height = 20.0;

  void _onChanged(double value) {
    int index = (value * (_timelineColors.length - 1)).round();
    setState(() {
      _value = value;
      _color = _timelineColors[index];
      widget.onUpdate(_color);
    });
  }

  List<Color> generateAllHexColors() {
    List<Color> colors = [];
    const webSafeValues = [0x00, 0x33, 0x66, 0x99, 0xCC, 0xFF];

    for (int r in webSafeValues) {
      for (int g in webSafeValues) {
        for (int b in webSafeValues) {
          colors.add(Color.fromARGB(255, r, g, b));
        }
      }
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_height),
            gradient: LinearGradient(
              colors: _timelineColors,
              //stops: _timelineStops,
              begin: AlignmentGeometry.centerLeft,
              end: AlignmentGeometry.centerRight,
            ),
          ),
          child: Slider(
            value: _value,
            onChanged: _onChanged,
            min: 0,
            max: 1,
            activeColor: Colors.transparent,
            inactiveColor: Colors.transparent,
          ),
        ),
        SizedBox(height: MyStyles.paddingNormal),
        Container(height: _height * 4, width: _height * 4, color: _color),
      ],
    );
  }
}

// List<Color> _timelineColors = [
//   Colors.red,
//   Colors.blue,
//   Colors.green,
//   Colors.yellow,
//   Colors.purple,
// ];

// List<double> _timelineStops = [0.0, 0.25, 0.5, 0.75, 1.0];

class MyColorPickerDialog {
  Color? selectedColor;

  MyColorPickerDialog({this.selectedColor});

  void onUpdate(Color? color) {
    selectedColor = color;
  }

  Future<Color?> show({required BuildContext context}) async {
    return await showDialog<Color?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: MyColorPicker(onUpdate: onUpdate),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(selectedColor);
              },
              child: Text(myLoc(context).ok),
            ),
          ],
        );
      },
    );
  }
}
