import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/material.dart';

class MyHtmlText {
  //final List<TapGestureRecognizer> gestureDetectors = [];

  static List<TextSpan> _getRichTexts(html_dom.Node node) {
    var newList = <TextSpan>[];
    for (var node in node.nodes) {
      if (node.nodeType == html_dom.Node.TEXT_NODE) {
        newList.add(TextSpan(text: node.text));
      } else {
        final nodeName = (node as html_dom.Element).localName;
        if (nodeName == 'br') {
          newList.add(const TextSpan(text: "\n"));
        } else if (nodeName == 'a') {
          newList.add(TextSpan(children: [
            WidgetSpan(
                child: GestureDetector(
              child: Text.rich(TextSpan(
                  children: _getRichTexts(node),
                  style: TextStyle(
                      decoration:
                          nodeName == 'a' ? TextDecoration.underline : null,
                      fontWeight: nodeName == 'strong' ? FontWeight.bold : null,
                      fontStyle: nodeName == 'em' ? FontStyle.italic : null))),
              onTap: () {
                print(node.text);
              },
            ))
          ]));
        } else {
          // This does NOT work....
          // final newGestureDetector =
          //     nodeName == 'a' ? TapGestureRecognizer() : null;
          // if (newGestureDetector != null) {
          //   gestureDetectors.add(newGestureDetector);
          //   newGestureDetector.onTap = () {
          //     print('Clicked ${node.text}');
          //   };
          // }
          newList.add(TextSpan(
              children: _getRichTexts(node),
              //recognizer: newGestureDetector,
              style: TextStyle(
                  decoration: nodeName == 'a' ? TextDecoration.underline : null,
                  fontWeight: nodeName == 'strong' ? FontWeight.bold : null,
                  fontStyle: nodeName == 'em' ? FontStyle.italic : null)));
        }
      }
    }
    return newList;
  }

  // void dispose() {
  //   for (final g in gestureDetectors) {
  //     print('Dispose gesture detector');
  //     g.dispose();
  //   }
  // }

  static Text getRichText(String text,
      {double? fontSize, TextAlign? textAlign, TextStyle? textStyle}) {
    final fragment = html_parser.parseFragment(text);
    return Text.rich(
      TextSpan(children: _getRichTexts(fragment)),
      style: textStyle,
      textAlign: textAlign,
    );
  }
}
