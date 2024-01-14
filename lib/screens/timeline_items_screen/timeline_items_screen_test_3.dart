import 'dart:math';
import 'package:flutter/material.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

// https://github.com/fluttercandies/flutter_scrollview_observer/blob/main/lib/src/common/observer_controller.dart#L334
// https://pub.dev/packages/scroll_to_index

class MyTestItemsScreen3 extends StatefulWidget {
  const MyTestItemsScreen3({super.key});

  @override
  State<MyTestItemsScreen3> createState() => _MyTestItemsScreen3State();
}

class _MyTestItemsScreen3State extends State<MyTestItemsScreen3> {
  List<Map<String, dynamic>>? items;
  //final scrollController = ScrollController();
  final ListObserverController observerController =
      ListObserverController(controller: ScrollController())
        ..cacheJumpIndexOffset = false;
  //final listViewKey = GlobalKey();
  var requestedIndex = -1;
  var isScrollingToIndex = false;
  List<int> displayedIndexesAfterScrollToIndex = [];
  final Map<int, GlobalKey> keys = {};

  @override
  void initState() {
    super.initState();
    // observerController = ListObserverController(controller: scrollController)
    //   ..cacheJumpIndexOffset =
    //       false; // needed if we load only images for items that are displayed in rest.
    init();
  }

  @override
  void dispose() {
    //scrollController.dispose();
    observerController.controller!.dispose();
    super.dispose();
  }

  void init() async {
    //final tmp = await getJson();

    setState(() {
      //items =
      //    List.of(tmp['items']).map((e) => e as Map<String, dynamic>).toList();
      final rand = Random();
      items = List.generate(
          1000,
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
                      // START code
                      requestedIndex = curItems.indexOf(e);
                      isScrollingToIndex = true;
                      await observerController.jumpTo(index: requestedIndex);
                      isScrollingToIndex = false;
                      // EIND code
                      print('DONE!');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Center(child: Text(e['key'].toString())),
                    ),
                  );
                }).toList(),
              )),
          Expanded(
              child: ListViewObserver(
            controller: observerController,
            onObserve: (p0) {
              // START code
              if (requestedIndex > -1) {
                final builtIndexes = keys.entries
                    .where((entry) => entry.value.currentContext != null)
                    .map((e) => e.key)
                    .toList();
                print(
                    'Currently built indexes: ${builtIndexes.join(', ')} and displayingChildIndexList = ${p0.displayingChildIndexList.join(', ')}');
                setState(() {
                  // displayedIndexesAfterScrollToIndex =
                  //     p0.displayingChildIndexList;
                  displayedIndexesAfterScrollToIndex = builtIndexes;
                });
                try {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    //await Future.delayed(Duration(seconds: 1));
                    if (keys[requestedIndex]?.currentContext != null) {
                      print('Nogmaals ensure visible...');
                      try {
                        Scrollable.ensureVisible(
                            keys[requestedIndex]!.currentContext!);
                      } catch (ex) {
                        print('ex: ${ex.toString()}');
                      }
                    }
                    requestedIndex = -1;
                  });
                } catch (ex) {
                  print(ex.toString());
                  requestedIndex = -1;
                }
              }
              // EIND code
            },
            child: ListView.builder(
                //key: listViewKey, // needed!
                controller: observerController.controller,
                itemCount: curItems.length,
                itemBuilder: (context, index) {
                  // START code
                  if (!keys.containsKey(index)) {
                    keys[index] = GlobalKey();
                  }
                  final loadImage = requestedIndex == -1 ||
                      displayedIndexesAfterScrollToIndex.contains(index);
                  print('Load image $loadImage for $index');
                  // EIND code
                  final e = curItems[index];
                  final card = Card(
                    key: keys[index], // START code?
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
                        if (loadImage) // START code?
                          Image.network(e['image'])
                      ],
                    ),
                  );
                  return card;
                }),
          ))
        ],
      ),
    );
  }
}
