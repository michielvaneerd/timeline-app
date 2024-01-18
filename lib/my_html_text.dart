import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/material.dart';

class MyHtmlText {
  static List<TextSpan> _getRichTexts(html_dom.Node node) {
    var newList = <TextSpan>[];
    for (var node in node.nodes) {
      if (node.nodeType == html_dom.Node.TEXT_NODE) {
        newList.add(TextSpan(text: node.text));
      } else {
        final nodeName = (node as html_dom.Element).localName;
        if (nodeName == 'br') {
          newList.add(const TextSpan(text: "\n"));
        } else {
          newList.add(TextSpan(
              children: _getRichTexts(node),
              style: TextStyle(
                  fontWeight: nodeName == 'strong' ? FontWeight.bold : null,
                  fontStyle: nodeName == 'em' ? FontStyle.italic : null)));
        }
      }
    }
    return newList;
  }

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
