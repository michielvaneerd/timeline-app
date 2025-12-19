import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:timeline/utils.dart';

class MyTextFieldsDialogResult extends Equatable {
  final String field1;
  final String? field2;

  const MyTextFieldsDialogResult({required this.field1, this.field2});

  @override
  List<Object?> get props => [field1, field2];
}

class MyTextFieldsDialog {
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

  Future<MyTextFieldsDialogResult?> show(
    BuildContext context, {
    required String field1Text,
    String? field2Text,
    String? field1Value,
    String? field2Value,
    required String title,
  }) async {
    if (field1Value != null) {
      field1Controller.text = field1Value;
    }
    if (field2Value != null) {
      field2Controller.text = field2Value;
    }
    final response = await showDialog<MyTextFieldsDialogResult?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: field1Text),
                controller: field1Controller,
              ),
              if (field2Text != null)
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
              child: Text(myLoc(context).cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  MyTextFieldsDialogResult(
                    field1: field1Controller.text,
                    field2: field2Text != null ? field2Controller.text : null,
                  ),
                );
              },
              child: Text(myLoc(context).ok),
            ),
          ],
        );
      },
    );
    return response;
  }
}
