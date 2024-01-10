import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// https://github.com/fluttercandies/flutter_scrollview_observer/blob/main/lib/src/common/observer_controller.dart#L334
// https://pub.dev/packages/scroll_to_index

class MyTestItemsScreen extends StatefulWidget {
  const MyTestItemsScreen({super.key});

  @override
  State<MyTestItemsScreen> createState() => _MyTestItemsScreenState();
}

class _MyTestItemsScreenState extends State<MyTestItemsScreen> {
  List<Map<String, dynamic>>? items;
  final scrollController = ScrollController();
  Timer? timer;
  final List<int> currentlyBuiltIndexes = []; // current visible indexes
  int requestedIndex = -1; // clicked index
  final Map<int, GlobalKey> keys =
      {}; // Index is de index van het item, deze worden on the fly aangemaakt.
  //final currentKey = GlobalKey();
  //var currentKeyIndex = -1;
  var lastBuiltIndex = 0;
  final listViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(
      () async {
        // await SchedulerBinding.instance
        //     .endOfFrame;

        if (requestedIndex != -1 &&
            keys[requestedIndex]?.currentContext != null) {
          scrollController.jumpTo(scrollController.offset);
          await Scrollable.ensureVisible(keys[requestedIndex]!.currentContext!);
          requestedIndex = -1;
        }
      },
    );
    init();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void init() async {
    //final tmp = await getJson();

    setState(() {
      //items =
      //    List.of(tmp['items']).map((e) => e as Map<String, dynamic>).toList();
      final rand = Random();
      items = List.generate(
          100,
          (index) => {
                'key': 1500 + index,
                'title': 'Item ${index + 1}',
                'image': 'https://picsum.photos/200/300',
                'content': List.generate(
                        rand.nextInt(10),
                        (index) =>
                            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.')
                    .join("\n\n")
              });
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final curItems = items ?? [];
    // if (keys == null && items != null) {
    //   keys = List<GlobalKey>.generate(items!.length, (index) => GlobalKey());
    // }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
              //color: Colors.green,
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: curItems.map((e) {
                  return InkWell(
                    onTap: () async {
                      final itemIndex = curItems.indexOf(e);
                      // if (keys![itemIndex].currentContext != null) {
                      //   print('Immediately make visible for index $itemIndex');
                      //   Scrollable.ensureVisible(
                      //       keys![itemIndex].currentContext!);
                      // } else {
                      print(
                          'ItemIndex $itemIndex en lastBuiltIndex = $lastBuiltIndex');
                      // Dit gaat dus fout als de itemindex dichtbij de lastBuildindex ligt...
                      // de lastbuildindex is namelijk meestal niet degene die je nu ziet.
                      // dus bijv je ziet nu 20 en men scrolde naar beneden, dus dan kan lasrBuildindex bijv. 22 zijn.
                      // Als je nu op 21 klikt, dan zal men omhoiiog willen scrollen, waardoor men dus nooit bij het item uitkomt.
                      // TODO: hoe doen?
                      print(
                          'Offset = ${scrollController.offset}'); // dit hoe ver listview gescrolt is.
                      final listViewRenderObject =
                          listViewKey.currentContext!.findRenderObject();
                      var topIndex = -1;
                      for (final entry in keys.entries) {
                        if (entry.value.currentContext != null) {
                          final translation = entry.value.currentContext!
                              .findRenderObject()
                              ?.getTransformTo(listViewRenderObject)
                              .getTranslation();
                          if (translation != null && translation.y >= 0) {
                            topIndex = entry.key;
                            break;
                          }
                        }
                      }
                      if (itemIndex == topIndex) {
                        return;
                      }
                      var scrollDown = itemIndex > topIndex;
                      requestedIndex = itemIndex;
                      print(
                          'Scrolling ${scrollDown ? 'down' : 'up'} to ${scrollDown ? scrollController.position.maxScrollExtent : scrollController.position.minScrollExtent} for index $itemIndex');
                      await scrollController.animateTo(
                          scrollDown
                              ? scrollController.position.maxScrollExtent
                              : scrollController.position.minScrollExtent,
                          duration: Duration(
                              seconds:
                                  1), // deze kunnen we zetten a.h.v. of we dicht in de buurt zitten of niet.
                          // hoe labger hoe beter, want dan worden items niet geskipt.
                          curve: Curves
                              .linear); // linear is belangrijk, want dan komen alle items even snel voorbij en worden de snelste niet geskipt.
                      print('Animate completed: ${requestedIndex}');
                      if (requestedIndex != -1) {
                        // Niet gelukt, dus we kunnen dan eventueel nog 2 keer proberen bijv.
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Center(child: Text(e['key'].toString())),
                    ),
                  );
                }).toList(),
              )),
          Expanded(
              child: ListView.builder(
                  key: listViewKey,
                  controller: scrollController,
                  itemCount: curItems.length,
                  itemBuilder: (context, index) {
                    lastBuiltIndex = index;
                    // if (index == requestedIndex && !keys.containsKey(index)) {
                    //   keys[index] = GlobalKey();
                    // }
                    if (!keys.containsKey(index)) {
                      keys[index] = GlobalKey();
                    }
                    print('Index = $index, requestedIndex = $requestedIndex');
                    final e = curItems[index];
                    final card = Card(
                      key: keys[index],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('$index: ' + e['key'].toString()),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(e['title']),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(e['content']),
                          ),
                          // Load image only if we scroll manually (requestedIndex == -1) or when the index is less than 3 away from requestedIndex
                          if (requestedIndex == -1 ||
                              (index - requestedIndex).abs() < 3)
                            Image.network(e['image'])
                        ],
                      ),
                    );
                    return card;
                  }))
        ],
      ),
    );
  }
}
