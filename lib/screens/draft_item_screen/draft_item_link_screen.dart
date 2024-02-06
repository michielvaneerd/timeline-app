import 'package:flutter/material.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_widgets.dart';
import 'package:timeline/utils.dart';

class DraftItemLinkSreen extends StatefulWidget {
  final TimelineItemLink? link;
  const DraftItemLinkSreen({super.key, this.link});

  @override
  State<DraftItemLinkSreen> createState() => _DraftItemLinkSreenState();
}

class _DraftItemLinkSreenState extends State<DraftItemLinkSreen> {
  late final TextEditingController nameController;
  late final TextEditingController urlController;
  late DraftTimelineItemLink link;

  @override
  void initState() {
    super.initState();
    link = DraftTimelineItemLink(
        name: widget.link?.name ?? '',
        url: widget.link?.url ?? '',
        deleted: false);
    nameController = TextEditingController(text: widget.link?.name);
    urlController = TextEditingController(text: widget.link?.url);
  }

  @override
  void dispose() {
    nameController.dispose();
    urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: widget.link != null
              ? [
                  IconButton(
                      onPressed: () {
                        Navigator.of(context).pop<DraftTimelineItemLink>(
                            DraftTimelineItemLink(
                                name: nameController.text,
                                url: urlController.text,
                                deleted: true));
                      },
                      icon: const Icon(Icons.delete))
                ]
              : null,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MyWidgets.textField(context,
                  controller: nameController, labelText: myLoc(context).name),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MyWidgets.textField(context,
                  controller: urlController, labelText: myLoc(context).url),
            ),
            FilledButton(
                onPressed: () {
                  // TODO: validate
                  Navigator.of(context).pop<DraftTimelineItemLink>(
                      DraftTimelineItemLink(
                          name: nameController.text,
                          url: urlController.text,
                          deleted: false));
                },
                child: Text(myLoc(context).ok))
          ],
        ));
  }
}
