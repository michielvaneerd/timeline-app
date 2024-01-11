import 'dart:math';
import 'package:flutter/material.dart';

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
  int requestedIndex = -1; // clicked index
  final Map<int, GlobalKey> keys = {};
  final listViewKey = GlobalKey();
  List<int> builtIndexes = [];

  @override
  void initState() {
    super.initState();
    scrollController.addListener(
      () async {
        // await SchedulerBinding.instance
        //     .endOfFrame;

        if (requestedIndex != -1 &&
            keys[requestedIndex]?.currentContext != null) {
          final tmp = requestedIndex;
          // Eerste keer ensureVisible.
          await Scrollable.ensureVisible(keys[requestedIndex]!
              .currentContext!); // This will cancel the animation, which is what we want.
          requestedIndex = -1;
          //await Future.delayed(Duration(milliseconds: 1000));
          // NU zouden we de images moeten laten van alle items die nu gebuild zijn.
          setState(() {
            builtIndexes = keys.entries
                .where((e) => e.value.currentContext != null)
                .map((e) => e.key)
                .toList();
          });
          print('Indexes die nu zijn gebuild zijn: ${builtIndexes.join(', ')}');
          if (tmp != -1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (keys.containsKey(tmp) && keys[tmp]!.currentContext != null) {
                print('Ensure visible for $tmp!');
                // Tweede keer ensureVisible, omdat nu de images geladen zijn en dus de items van hoogte kunnen veranderen.
                Scrollable.ensureVisible(keys[tmp]!
                    .currentContext!); // This will cancel the animation, which is what we want.
              }
            });
          }
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
                      requestedIndex = itemIndex;
                      await scrollController.animateTo(
                          itemIndex > topIndex
                              ? scrollController.position.maxScrollExtent
                              : scrollController.position.minScrollExtent,
                          duration: Duration(
                              seconds:
                                  1), // deze kunnen we zetten a.h.v. of we dicht in de buurt zitten of niet.
                          // hoe labger hoe beter, want dan worden items niet geskipt.
                          curve: Curves
                              .linear); // linear is belangrijk, want dan komen alle items even snel voorbij en worden de snelste niet geskipt.
                      // print('Animate completed: ${requestedIndex}');
                      // if (requestedIndex != -1) {
                      //   // Niet gelukt, dus we kunnen dan eventueel nog 2 keer proberen bijv.
                      // }
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
                key: listViewKey,
                controller: scrollController,
                itemCount: curItems.length,
                itemBuilder: (context, index) {
                  if (!keys.containsKey(index)) {
                    keys[index] = GlobalKey();
                  }
                  if (requestedIndex == -1 || builtIndexes.contains(index)) {
                    print('Image laden voor index $index');
                  }
                  //print('Index = $index, requestedIndex = $requestedIndex');
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
                        // if (requestedIndex == -1 ||
                        //     (index - requestedIndex).abs() < 3)
                        if (requestedIndex == -1 ||
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

class PositionRetainedScrollPhysics extends ScrollPhysics {
  final bool shouldRetain;
  const PositionRetainedScrollPhysics({super.parent, this.shouldRetain = true});

  @override
  PositionRetainedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return PositionRetainedScrollPhysics(
      parent: buildParent(ancestor),
      shouldRetain: shouldRetain,
    );
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final position = super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );

    final diff = newPosition.maxScrollExtent - oldPosition.maxScrollExtent;

    if (oldPosition.pixels > oldPosition.minScrollExtent &&
        diff > 0 &&
        shouldRetain) {
      return position + diff;
    } else {
      return position;
    }
  }
}
