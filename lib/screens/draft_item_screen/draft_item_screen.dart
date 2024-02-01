import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/draft_item_screen/draft_item_screen_bloc.dart';
import 'package:timeline/utils.dart';

class DraftItemScreen extends StatefulWidget {
  final TimelineItem timelineItem;
  final List<Timeline> timelines; // All timelines for this host
  final TimelineHost timelineHost;
  const DraftItemScreen(
      {super.key,
      required this.timelineItem,
      required this.timelines,
      required this.timelineHost});

  @override
  State<DraftItemScreen> createState() => _DraftItemScreenState();
}

class _DraftItemScreenState extends State<DraftItemScreen> {
  late final TextEditingController titleController;
  late final TextEditingController yearController;
  late final TextEditingController yearEndController;
  late TimelineItem timelineItem;

  @override
  void initState() {
    super.initState();
    timelineItem = widget.timelineItem;
    titleController = TextEditingController(text: timelineItem.title);
    yearController = TextEditingController(text: timelineItem.year.toString());
    yearEndController =
        TextEditingController(text: timelineItem.yearEnd?.toString());
  }

  @override
  void dispose() {
    titleController.dispose();
    yearController.dispose();
    yearEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<TimelineRepository>(context);
    return BlocProvider(
      create: (context) => DraftItemScreenCubit(repo),
      child: BlocConsumer<DraftItemScreenCubit, DraftItemScreenState>(
        listener: (context, state) {
          if (state.completed) {
            Navigator.of(context).pop<bool>(true);
          }
        },
        builder: (context, state) {
          final cubit = BlocProvider.of<DraftItemScreenCubit>(context);
          return Scaffold(
              appBar: AppBar(),
              body: Column(
                children: [
                  TextField(
                    controller: titleController,
                    onChanged: (value) {
                      setState(() {
                        timelineItem = timelineItem.copyWith(title: value);
                      });
                    },
                  ),
                  DropdownMenu<Timeline>(
                      initialSelection: widget.timelines.firstWhereOrNull(
                          (element) => element.id == timelineItem.timelineId),
                      onSelected: (value) {
                        if (value != null) {
                          setState(() {
                            timelineItem =
                                timelineItem.copyWith(timelineId: value.id);
                          });
                        }
                      },
                      dropdownMenuEntries: widget.timelines
                          .map((e) => DropdownMenuEntry<Timeline>(
                              value: e, label: e.name))
                          .toList()),
                  TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number),
                  TextField(
                      controller: yearEndController,
                      keyboardType: TextInputType.number),
                  FilledButton(
                      onPressed: state.busy
                          ? null
                          : () {
                              final newTimelineItem = timelineItem.copyWith(
                                  year: int.parse(yearController.text),
                                  useYearEndParam: true,
                                  yearEnd: yearEndController.text.isNotEmpty
                                      ? int.parse(yearEndController.text)
                                      : null);
                              cubit.update(
                                  widget.timelineHost,
                                  widget.timelines.firstWhere((element) =>
                                      element.id == timelineItem.timelineId),
                                  newTimelineItem);
                            },
                      child: Text(myLoc(context).ok))
                ],
              ));
        },
      ),
    );
  }
}
