import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:timeline/utils.dart';

class MyTwoFieldsDialogResult extends Equatable {
  final String field1;
  final String field2;

  const MyTwoFieldsDialogResult({required this.field1, required this.field2});

  @override
  List<Object?> get props => [field1, field2];
}

class MyTwoFieldsDialog {
  final field1Controller = TextEditingController();
  final field2Controller = TextEditingController();

  void dispose() {
    field1Controller.dispose();
    field2Controller.dispose();
  }

  void clear() {
    field1Controller.clear();
    field2Controller.clear();
  }

  Future<MyTwoFieldsDialogResult?> show(BuildContext context,
      {required String field1Text,
      required String field2Text,
      required String title}) async {
    final response = await showDialog<MyTwoFieldsDialogResult?>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    decoration: InputDecoration(labelText: field1Text),
                    controller: field1Controller),
                TextField(
                  decoration: InputDecoration(labelText: field2Text),
                  controller: field2Controller,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(myLoc(context).cancel)),
              FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(MyTwoFieldsDialogResult(
                        field1: field1Controller.text,
                        field2: field2Controller.text));
                  },
                  child: Text(myLoc(context).ok)),
            ],
          );
        });
    return response;
  }
}
