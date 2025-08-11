import 'dart:math';
import 'package:flutter/material.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

// https://github.com/fluttercandies/flutter_scrollview_observer/blob/main/lib/src/common/observer_controller.dart#L334
// https://pub.dev/packages/scroll_to_index

class MyTestItemsScreen4 extends StatefulWidget {
  const MyTestItemsScreen4({super.key});

  @override
  State<MyTestItemsScreen4> createState() => _MyTestItemsScreen4State();
}

class _MyTestItemsScreen4State extends State<MyTestItemsScreen4> {
  List<Map<String, dynamic>>? items;
  final scrollController = ScrollController();
  // late final ObserverControllerWithLazyLoading
  //     observerControllerWithLazyLoading;
  // List<int> builtIndexes = [];
  late final ListObserverController listObserverController;

  // void onBuiltEnd(List<int> indexes) {
  //   setState(() {
  //     builtIndexes = indexes;
  //   });
  // }

  @override
  void initState() {
    super.initState();
    listObserverController =
        ListObserverController(controller: scrollController);
    // observerControllerWithLazyLoading = ObserverControllerWithLazyLoading(
    //     onBuiltEnd: onBuiltEnd, scrollController: scrollController)
    //   ..init();
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
                      // observerControllerWithLazyLoading
                      //     .scrollToIndex(curItems.indexOf(e));
                      listObserverController.jumpTo(index: curItems.indexOf(e));
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
            controller: listObserverController,
            // controller:
            //     observerControllerWithLazyLoading.listObserverController,
            //onObserve: observerControllerWithLazyLoading.onObserve,
            child: ListView.builder(
                controller: scrollController,
                itemCount: curItems.length,
                itemBuilder: (context, index) {
                  // final shouldLoad = observerControllerWithLazyLoading
                  //     .shouldActivelyLoad(index, builtIndexes);
                  // if (shouldLoad) {
                  //   print('Load image for $index');
                  // }
                  final e = curItems[index];
                  final card = Card(
                    //key: observerControllerWithLazyLoading.getKey(index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('$index: ${e['key']}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(e['title']),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(e['content']),
                        ),
                        //if (shouldLoad) // START code?
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
