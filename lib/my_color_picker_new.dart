import 'package:flutter/material.dart';
import 'package:timeline/utils.dart';

class CommonColorPicker extends StatefulWidget {
  const CommonColorPicker({
    super.key,
    required this.onColorSelected,
    this.selectedColor,
  });

  final Function(Color) onColorSelected;
  final Color? selectedColor;

  static final List<Color> commonColors = [
    // Reds
    Colors.red.shade900,
    Colors.red.shade700,
    Colors.red.shade500,
    Colors.red.shade300,
    Colors.red.shade100,
    // Pinks
    Colors.pink.shade900,
    Colors.pink.shade700,
    Colors.pink.shade500,
    Colors.pink.shade300,
    Colors.pink.shade100,
    // Oranges
    Colors.orange.shade900,
    Colors.orange.shade700,
    Colors.orange.shade500,
    Colors.orange.shade300,
    Colors.orange.shade100,
    // Yellows
    Colors.yellow.shade900,
    Colors.yellow.shade700,
    Colors.yellow.shade500,
    Colors.yellow.shade300,
    Colors.yellow.shade100,
    // Greens
    Colors.green.shade900,
    Colors.green.shade700,
    Colors.green.shade500,
    Colors.green.shade300,
    Colors.green.shade100,
    // Purples
    Colors.purple.shade900,
    Colors.purple.shade700,
    Colors.purple.shade500,
    Colors.purple.shade300,
    Colors.purple.shade100,
    // Blues
    Colors.blue.shade900,
    Colors.blue.shade700,
    Colors.blue.shade500,
    Colors.blue.shade300,
    Colors.blue.shade100,
    // Greys
    Colors.grey.shade900,
    Colors.grey.shade700,
    Colors.grey.shade500,
    Colors.grey.shade300,
    Colors.grey.shade100,
  ];

  @override
  State<CommonColorPicker> createState() => _CommonColorPickerState();
}

class _CommonColorPickerState extends State<CommonColorPicker> {
  Color? _selectedColor;

  @override
  void initState() {
    _selectedColor = widget.selectedColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: CommonColorPicker.commonColors.length,
      itemBuilder: (context, index) {
        final color = CommonColorPicker.commonColors[index];
        final isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
              widget.onColorSelected(color);
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(100),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class CommonColorPickerDialog {
  Color? selectedColor;

  CommonColorPickerDialog({this.selectedColor});

  void onColorSelected(Color color) {
    selectedColor = color;
  }

  Future<Color?> show({required BuildContext context}) async {
    return await showDialog<Color?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(myLoc(context).color),
          content: SizedBox(
            width: 500,
            height: 300,
            child: CommonColorPicker(
              onColorSelected: onColorSelected,
              selectedColor: selectedColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(myLoc(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selectedColor),
              child: Text(myLoc(context).ok),
            ),
          ],
        );
      },
    );
  }
}
