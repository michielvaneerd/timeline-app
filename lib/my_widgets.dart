import 'package:flutter/material.dart';

class MyWidgets {
  static OutlineInputBorder getOutlineInputBorderEnabled(BuildContext context) {
    return OutlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(10));
  }

  static OutlineInputBorder getOutlineInputBorderFocused(BuildContext context) {
    return OutlineInputBorder(
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 3),
        borderRadius: BorderRadius.circular(10));
  }

  static Widget textField(BuildContext context,
      {TextEditingController? controller,
      Widget? suffixIcon,
      String? labelText,
      int? maxLines,
      void Function(String)? onChanged}) {
    return TextField(
        maxLines: maxLines,
        onChanged: onChanged,
        controller: controller,
        decoration: InputDecoration(
            labelText: labelText,
            suffixIcon: suffixIcon,
            //enabledBorder: UnderlineInputBorder()
            enabledBorder: getOutlineInputBorderEnabled(context),
            focusedBorder: getOutlineInputBorderFocused(context)));
  }
}
