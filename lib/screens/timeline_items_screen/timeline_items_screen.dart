import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/my_html_text.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/timeline_items_screen/timeline_items_screen_bloc.dart';

// https://github.com/fluttercandies/flutter_scrollview_observer/blob/main/lib/src/common/observer_controller.dart#L334
// https://pub.dev/packages/scroll_to_index

class TimelineItemsWidget extends StatefulWidget {
  final Timeline timeline;
  final TimelineHost timelineHost;
  const TimelineItemsWidget(
      {super.key, required this.timeline, required this.timelineHost});

  @override
  State<TimelineItemsWidget> createState() => _TimelineItemsWidgetState();
}

class _TimelineItemsWidgetState extends State<TimelineItemsWidget> {
  final scrollController = ScrollController();
  int requestedIndex = -1; // clicked index
  final Map<int, GlobalKey> keys = {};
  final listViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    scrollController.addListener(
      () async {
        await SchedulerBinding.instance
            .endOfFrame; // Lijkt er voor te zorgen dat voordat de listener uitgevoerd wordt, de frame klaar is en dus ook de currentContext al beschikbaar is
        // zonder dit komt regelmatig de index niet voorbij.
        if (requestedIndex != -1 &&
            keys[requestedIndex]?.currentContext != null) {
          //scrollController.jumpTo(scrollController.offset);
          await Scrollable.ensureVisible(keys[requestedIndex]!.currentContext!);
          requestedIndex = -1;
        }
      },
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<TimelineRepository>(context);
    return BlocProvider(
      create: (context) => TimelineItemsScreenCubit(repo)
        ..getItems(widget.timelineHost, widget.timeline),
      child: BlocConsumer<TimelineItemsScreenCubit, TimelineItemsScreenState>(
        listener: (context, state) {
          // TODO: implement listener
        },
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Container();
          }
          final cubit = BlocProvider.of<TimelineItemsScreenCubit>(context);
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                  //color: Colors.green,
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: state.items.map((e) {
                      return InkWell(
                        onTap: () async {
                          final itemIndex = state.items.indexOf(e);
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
                          print('Animate completed: ${requestedIndex}');
                          if (requestedIndex != -1) {
                            // Niet gelukt, dus we kunnen dan eventueel nog 2 keer proberen bijv.
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Center(child: Text(e.year.toString())),
                        ),
                      );
                    }).toList(),
                  )),
              Expanded(
                  child: RefreshIndicator(
                onRefresh: () {
                  return cubit.getItems(widget.timelineHost, widget.timeline,
                      refresh: true);
                },
                child: ListView.builder(
                    key: listViewKey,
                    controller: scrollController,
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      if (!keys.containsKey(index)) {
                        keys[index] = GlobalKey();
                      }
                      print('Index = $index, requestedIndex = $requestedIndex');
                      final e = state.items[index];
                      final card = Card(
                        key: keys[index],
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('$index: ' + e.year.toString()),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(e.title),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: MyHtmlText.getRichText(e.intro),
                            ),
                            // Load image only if we scroll manually (requestedIndex == -1) or when the index is less than 3 away from requestedIndex
                            if (e.image != null &&
                                ((requestedIndex == -1 ||
                                    (index - requestedIndex).abs() < 3)))
                              Image.network(e.image!)
                          ],
                        ),
                      );
                      return card;
                    }),
              ))
            ],
          );
        },
      ),
    );
  }
}
