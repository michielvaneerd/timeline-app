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
  late String currentName;
  late String currentUrl;

  @override
  void initState() {
    super.initState();
    currentName = widget.link?.name ?? '';
    currentUrl = widget.link?.url ?? '';
    link = DraftTimelineItemLink(
        name: currentName, url: currentUrl, deleted: false);
    nameController = TextEditingController(text: currentName);
    urlController = TextEditingController(text: currentUrl);
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
        appBar: AppBar(actions: [
          IconButton(
              onPressed: currentName.isNotEmpty && currentUrl.isNotEmpty
                  ? () {
                      Navigator.of(context).pop<DraftTimelineItemLink>(
                          DraftTimelineItemLink(
                              name: nameController.text,
                              url: urlController.text,
                              deleted: false));
                    }
                  : null,
              icon: const Icon(Icons.save)),
          if (widget.link != null)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    Navigator.of(context).pop<DraftTimelineItemLink>(
                        DraftTimelineItemLink(
                            name: nameController.text,
                            url: urlController.text,
                            deleted: true));
                    break;
                }
              },
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(myLoc(context).delete),
                  )
                ];
              },
            )
        ]),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: MyWidgets.textField(
                  context,
                  controller: nameController,
                  labelText: myLoc(context).name,
                  onChanged: (p0) {
                    setState(() {
                      currentName = p0;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: MyWidgets.textField(context,
                    controller: urlController,
                    labelText: myLoc(context).url, onChanged: (p0) {
                  setState(() {
                    currentUrl = p0;
                  });
                }),
              )
            ],
          ),
        ));
  }
}
