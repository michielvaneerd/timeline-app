import 'dart:math';
import 'package:flutter/material.dart';
import 'package:timeline/screens/timeline_items_screen/listview_builder_scroll_to_index_screen.dart';

// https://github.com/fluttercandies/flutter_scrollview_observer/blob/main/lib/src/common/observer_controller.dart#L334
// https://pub.dev/packages/scroll_to_index

class MyTestItemsScreen2 extends StatefulWidget {
  const MyTestItemsScreen2({super.key});

  @override
  State<MyTestItemsScreen2> createState() => _MyTestItemsScreen2State();
}

class _MyTestItemsScreen2State extends State<MyTestItemsScreen2> {
  List<Map<String, dynamic>>? items;
  final scrollController = ScrollController();

  final listViewKey = GlobalKey();
  List<int> builtIndexes = [];
  late final ListviewBuilderWithScrollToIndexController
      listviewBuilderWithScrollToIndexController;

  @override
  void initState() {
    super.initState();
    listviewBuilderWithScrollToIndexController =
        ListviewBuilderWithScrollToIndexController(
            onBuiltIndexesAfterScrollToIndex: onBuiltIndexes,
            scrollController: scrollController,
            listViewKey: listViewKey);
    init();
  }

  void onBuiltIndexes(List<int> indexes) {
    // setState(() {
    //   builtIndexes = indexes;
    // });
    print(indexes);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void init() async {
    listviewBuilderWithScrollToIndexController.init();

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
                      // print(
                      //     'Start jump to ${scrollController.position.maxScrollExtent}');
                      // scrollController.jumpTo(
                      //     scrollController.position.maxScrollExtent * 2);
                      // WidgetsBinding.instance.addPostFrameCallback(
                      //   (_) {
                      //     print('In post frame callback');
                      //   },
                      // );
                      await listviewBuilderWithScrollToIndexController
                          .scrollToIndex(itemIndex);
                      print('Scrolled to $itemIndex');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Center(child: Text(e['key'].toString())),
                    ),
                  );
                }).toList(),
              )),
          Expanded(
              child: NotificationListener<ScrollEndNotification>(
            onNotification: (notification) {
              print('End for ${notification.metrics.pixels}');
              return true;
            },
            child: ListView.builder(
                key: listViewKey, // needed!
                controller: scrollController,
                itemCount: curItems.length,
                itemBuilder: (context, index) {
                  print('Building $index');
                  final e = curItems[index];
                  final card = Card(
                    key: listviewBuilderWithScrollToIndexController
                        .getKey(index),
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
                        if (listviewBuilderWithScrollToIndexController
                                    .getRequestedIndex() ==
                                -1 ||
                            builtIndexes.contains(index))
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
