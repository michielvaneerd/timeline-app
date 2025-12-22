import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_loading_overlay.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/draft_item_screen/draft_item_screen.dart';
import 'package:timeline/screens/draft_items_screen/draft_items_screen_bloc.dart';
import 'package:timeline/utils.dart';

class DraftItemsScreen extends StatefulWidget {
  final List<Timeline> timelines;
  final TimelineHost timelineHost;
  const DraftItemsScreen({
    super.key,
    required this.timelineHost,
    required this.timelines,
  });

  @override
  State<DraftItemsScreen> createState() => _DraftItemsScreenState();
}

class _DraftItemsScreenState extends State<DraftItemsScreen> {
  final _loadingOverlay = LoadingOverlay();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      timer = Timer(const Duration(milliseconds: 600), () {
        _loadingOverlay.show(context);
      });
    });
  }

  @override
  void dispose() {
    _loadingOverlay.hide();
    super.dispose();
  }

  List<Widget> _listViewItems(
    List<TimelineItem> items,
    BuildContext context,
    DraftItemsScreenCubit cubit,
  ) {
    return items
        .map(
          (e) => Card(
            child: ListTile(
              title: Text(e.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.timelines
                            .firstWhereOrNull(
                              (element) => element.id == e.timelineId,
                            )
                            ?.name ??
                        '-',
                  ),
                  Text(e.years()),
                  Text(DateFormat.yMd().add_jm().format(e.modified)),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final isChanged = await Navigator.of(context).push<bool?>(
                  MaterialPageRoute(
                    builder: (context) => DraftItemScreen(
                      timelineItem: e,
                      timelines: widget.timelines,
                      timelineHost: widget.timelineHost,
                    ),
                  ),
                );
                if (isChanged != null && isChanged) {
                  if (mounted) {
                    //_loadingOverlay.show(context);
                    cubit.getItems(widget.timelineHost, widget.timelines);
                  }
                }
              },
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<TimelineRepository>(context);
    return BlocProvider(
      create: (context) =>
          DraftItemsScreenCubit(repo)
            ..getItems(widget.timelineHost, widget.timelines),
      child: BlocConsumer<DraftItemsScreenCubit, DraftItemsScreenState>(
        listener: (context, state) {
          if (state.items != null) {
            if (timer != null) {
              timer!.cancel();
            }
            _loadingOverlay.hide();
          }
        },
        builder: (context, state) {
          final cubit = BlocProvider.of<DraftItemsScreenCubit>(context);
          return Scaffold(
            appBar: AppBar(
              title: Text(myLoc(context).draftItems),
              actions: [
                IconButton(
                  onPressed: () async {
                    final hasChanged = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DraftItemScreen(
                          timelineItem: null,
                          timelines: widget.timelines,
                          timelineHost: widget.timelineHost,
                        ),
                      ),
                    );
                    if (hasChanged != null && hasChanged) {
                      cubit.getItems(widget.timelineHost, widget.timelines);
                    }
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            body: state.items != null
                ? ListView(
                    children: _listViewItems(state.items!, context, cubit),
                  )
                : Container(),
          );
        },
      ),
    );
  }
}
