import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/material.dart';

class MyHtmlText {
  static List<TextSpan> _getRichTexts(html_dom.Node node,
      {Function({int? id, String? url})? onLinkClicked}) {
    var newList = <TextSpan>[];
    for (var node in node.nodes) {
      if (node.nodeType == html_dom.Node.TEXT_NODE) {
        newList.add(TextSpan(text: node.text));
      } else {
        final nodeName = (node as html_dom.Element).localName;
        if (nodeName == 'br') {
          newList.add(const TextSpan(text: "\n"));
        } else if (nodeName == 'a' && onLinkClicked != null) {
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
                final id = node.attributes.containsKey('data-internal-id')
                    ? int.parse(node.attributes['data-internal-id'].toString())
                    : null;
                final url = node.attributes.containsKey('href')
                    ? node.attributes['href']
                    : null;
                onLinkClicked(id: id, url: url);
              },
            ))
          ]));
        } else {
          newList.add(TextSpan(
              children: _getRichTexts(node),
              style: TextStyle(
                  decoration: nodeName == 'a' ? TextDecoration.underline : null,
                  fontWeight: nodeName == 'strong' ? FontWeight.bold : null,
                  fontStyle: nodeName == 'em' ? FontStyle.italic : null)));
        }
      }
    }
    return newList;
  }

  static Text getRichText(String text,
      {double? fontSize,
      TextAlign? textAlign,
      TextStyle? textStyle,
      Function({int? id, String? url})? onLinkClicked}) {
    final fragment = html_parser.parseFragment(text);
    return Text.rich(
      TextSpan(children: _getRichTexts(fragment, onLinkClicked: onLinkClicked)),
      style: textStyle,
      textAlign: textAlign,
    );
  }
}
