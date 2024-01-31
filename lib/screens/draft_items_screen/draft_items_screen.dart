import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/draft_item_screen/draft_item_screen.dart';
import 'package:timeline/screens/draft_items_screen/draft_items_screen_bloc.dart';

class DraftItemsScreen extends StatelessWidget {
  final List<Timeline> timelines;
  final TimelineHost timelineHost;
  const DraftItemsScreen(
      {super.key, required this.timelineHost, required this.timelines});

  List<Widget> _listViewItems(List<TimelineItem> items, BuildContext context,
      DraftItemsScreenCubit cubit) {
    return items
        .map((e) => ListTile(
              title: Text(e.title),
              onTap: () async {
                final timeline = timelines
                    .firstWhere((element) => element.id == e.timelineId);
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => DraftItemScreen(
                      timelineItem: e,
                      timeline: timeline,
                      timelineHost: timelineHost),
                ));
                cubit.getItems(timelineHost, timelines);
              },
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<TimelineRepository>(context);
    return BlocProvider(
      create: (context) =>
          DraftItemsScreenCubit(repo)..getItems(timelineHost, timelines),
      child: BlocConsumer<DraftItemsScreenCubit, DraftItemsScreenState>(
        listener: (context, state) {
          // TODO: implement listener
        },
        builder: (context, state) {
          final cubit = BlocProvider.of<DraftItemsScreenCubit>(context);
          return Scaffold(
              appBar: AppBar(),
              body: state.items != null
                  ? ListView(
                      children: _listViewItems(state.items!, context, cubit),
                    )
                  : Center(
                      child: Text('Loading...'),
                    ));
        },
      ),
    );
  }
}
