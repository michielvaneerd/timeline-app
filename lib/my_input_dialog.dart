import 'package:flutter/material.dart';

class MyInputDialog {
  static Future<String?> show(BuildContext context,
      TextEditingController textEditingController, String title) async {
    final response = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: textEditingController,
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(textEditingController.text);
                  },
                  child: const Text('OK')),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'))
            ],
          );
        });
    return response;
  }
}
