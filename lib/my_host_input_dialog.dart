import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:timeline/utils.dart';

class MyHostInputDialogResult extends Equatable {
  final String host;
  final String name;

  const MyHostInputDialogResult({required this.host, required this.name});

  @override
  List<Object?> get props => [host, name];
}

class MyHostInputDialog {
  final hostController = TextEditingController();
  final nameController = TextEditingController();

  void dispose() {
    hostController.dispose();
    nameController.dispose();
  }

  void clear() {
    hostController.clear();
    nameController.clear();
  }

  Future<MyHostInputDialogResult?> show(BuildContext context) async {
    final response = await showDialog<MyHostInputDialogResult?>(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    decoration: InputDecoration(labelText: myLoc(context).name),
                    controller: nameController),
                TextField(
                  decoration: InputDecoration(labelText: myLoc(context).host),
                  controller: hostController,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(MyHostInputDialogResult(
                        host: hostController.text, name: nameController.text));
                  },
                  child: Text(myLoc(context).ok)),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(myLoc(context).cancel))
            ],
          );
        });
    return response;
  }
}
