import 'dart:math';
import 'package:flutter/material.dart';

// https://github.com/fluttercandies/flutter_scrollview_observer/blob/main/lib/src/common/observer_controller.dart#L334
// https://pub.dev/packages/scroll_to_index

class MyTestItemsScreen5 extends StatefulWidget {
  const MyTestItemsScreen5({super.key});

  @override
  State<MyTestItemsScreen5> createState() => _MyTestItemsScreen5State();
}

class _MyTestItemsScreen5State extends State<MyTestItemsScreen5> {
  List<Map<String, dynamic>>? items;
  final scrollController = ScrollController();
  var requestedIndex = -1;
  final Map<int, GlobalKey> keys = {};

  @override
  void initState() {
    super.initState();
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
    var index = 0;
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
                      // Todo: cur
                      final index = curItems.indexOf(e);
                      Scrollable.ensureVisible(keys[index]!.currentContext!);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Center(child: Text(e['key'].toString())),
                    ),
                  );
                }).toList(),
              )),
          Expanded(
              child: ListView(
            controller: scrollController,
            children: curItems.map((e) {
              if (!keys.containsKey(index)) {
                keys[index] = GlobalKey();
              }
              final key = keys[index];
              index += 1;
              return Card(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(e['key'].toString()),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(e['title']),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(e['content']),
                    ),
                    Image.network(e['image'])
                  ],
                ),
              );
            }).toList(),
          ))
        ],
      ),
    );
  }
}
